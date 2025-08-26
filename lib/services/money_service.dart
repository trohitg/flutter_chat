import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/payment_models.dart';
import '../services/api_service.dart';
import 'money_service_web.dart' if (dart.library.io) 'money_service_mobile.dart' as web_payment;

// Helper function for unawaited futures
void unawaited(Future<void> future) {
  future.catchError((error) {
    if (kDebugMode) {
      print('Unawaited future error: $error');
    }
  });
}

class MoneyService {
  late final Dio _dio;
  late final String _baseUrl;
  late Razorpay _razorpay;
  
  // Prevent concurrent payment operations
  bool _paymentInProgress = false;

  MoneyService() {
    _dio = ApiService.instance.dio;
    _baseUrl = ApiService.instance.baseUrl;
    
    // Initialize Razorpay lazily to prevent blocking constructor
    if (!kIsWeb) {
      _initializeRazorpayLazily();
    }
  }
  
  void _initializeRazorpayLazily() {
    // Initialize Razorpay in next event loop to prevent blocking
    Future.microtask(() {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    });
  }
  
  // Store callbacks per payment operation
  void Function(dynamic)? _currentSuccessCallback;
  void Function(dynamic)? _currentErrorCallback;
  
  void _handlePaymentSuccess(dynamic response) {
    _paymentInProgress = false;
    _currentSuccessCallback?.call(response);
    _currentSuccessCallback = null;
    _currentErrorCallback = null;
  }
  
  void _handlePaymentError(dynamic response) {
    _paymentInProgress = false;
    _currentErrorCallback?.call(response);
    _currentSuccessCallback = null;
    _currentErrorCallback = null;
  }
  
  void _handleExternalWallet(dynamic response) {
    // External wallet not supported for now
    _paymentInProgress = false;
    _currentErrorCallback?.call('External wallet not supported');
    _currentSuccessCallback = null;
    _currentErrorCallback = null;
  }

  // Default user ID for single-user app
  static const String _defaultUserId = "default_user";

  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 200000; // UPI limit
  }

  // === WALLET OPERATIONS ===

  Future<WalletResponse> getWallet({int includeTransactions = 5}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/wallet/$_defaultUserId?include_transactions=$includeTransactions',
        options: Options(sendTimeout: Duration(seconds: 10), receiveTimeout: Duration(seconds: 10)),
      );
      return WalletResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw Exception('Failed to get wallet: $e');
    }
  }

  Future<List<TransactionHistoryResponse>> getTransactionHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/api/v1/wallet/$_defaultUserId/transactions?limit=$limit&offset=$offset'
      );
      return (response.data as List)
          .map((item) => TransactionHistoryResponse.fromJson(item))
          .toList();
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw Exception('Failed to get transaction history: $e');
    }
  }

  Future<CreateOrderResponse> addMoneyToWallet(double amount) async {
    try {
      if (!isValidAmount(amount)) {
        throw Exception('Amount must be between ₹1 and ₹2,00,00,000');
      }

      final request = AddBalanceRequest(amount: amount);
      final response = await _dio.post(
        '$_baseUrl/api/v1/wallet/$_defaultUserId/add',
        data: request.toJson(),
        options: Options(sendTimeout: Duration(seconds: 15), receiveTimeout: Duration(seconds: 15)),
      );
      return CreateOrderResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw Exception('Failed to create payment order: $e');
    }
  }

  // === PAYMENT INTEGRATION ===

  Future<void> startPayment({
    required double amount,
    required Function(String paymentId) onSuccess,
    required Function(String error) onFailure,
  }) async {
    try {
      // Prevent concurrent payments
      if (_paymentInProgress) {
        onFailure('Another payment is already in progress');
        return;
      }
      
      if (!isValidAmount(amount)) {
        throw Exception('Amount must be between ₹1 and ₹2,00,000');
      }

      _paymentInProgress = true;

      // Create payment order
      final orderResponse = await addMoneyToWallet(amount);

      if (kIsWeb) {
        // Web: Working verification approach - don't change
        await _startWebPayment(
          orderResponse, 
          (paymentId) => _handlePaymentVerification(paymentId, orderResponse.orderId, onSuccess, onFailure),
          onFailure
        );
      } else {
        // Mobile: Simple API verification after payment success
        await _startMobilePayment(
          orderResponse,
          (paymentId) => _handlePaymentVerification(paymentId, orderResponse.orderId, onSuccess, onFailure),
          onFailure
        );
      }
    } catch (e) {
      _paymentInProgress = false;
      onFailure('Failed to create payment: $e');
    }
  }

  Future<void> _handlePaymentVerification(
    String paymentId, 
    String orderId, 
    Function(String paymentId) onSuccess, 
    Function(String error) onFailure
  ) async {
    try {
      if (kDebugMode) {
        print('💳 Payment successful, starting verification...');
        print('Payment ID: $paymentId');
        print('Order ID: $orderId');
      }

      // Run verification in background to prevent UI blocking
      unawaited(_verifyPaymentInBackground(
        paymentId: paymentId,
        orderId: orderId,
        onSuccess: onSuccess,
        onFailure: onFailure,
      ));
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment verification error: $e');
      }
      _paymentInProgress = false;
      onFailure('Payment verification failed: $e');
    }
  }

  Future<void> _verifyPaymentInBackground({
    required String paymentId,
    required String orderId,
    required Function(String paymentId) onSuccess,
    required Function(String error) onFailure,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 Calling verification API...');
      }
      
      final verificationResult = await verifyAndCreditPayment(
        paymentId: paymentId,
        orderId: orderId,
      ).timeout(Duration(seconds: 30)); // Add timeout

      if (kDebugMode) {
        print('📝 Verification result: $verificationResult');
      }

      if (verificationResult['success'] == true && verificationResult['balance_credited'] == true) {
        final amountCredited = verificationResult['amount_credited'];
        if (kDebugMode) {
          print('✅ Payment verified and ₹$amountCredited credited to wallet');
        }
        _paymentInProgress = false;
        onSuccess(paymentId);
      } else {
        final message = verificationResult['message'] ?? 'Payment verification failed';
        if (kDebugMode) {
          print('❌ Payment verification failed: $message');
        }
        _paymentInProgress = false;
        onFailure('Payment completed but verification failed: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Payment verification error: $e');
        print('Error type: ${e.runtimeType}');
      }
      _paymentInProgress = false;
      onFailure('Payment completed but verification failed: $e');
    }
  }

  Future<void> _startWebPayment(
    CreateOrderResponse orderResponse,
    Function(String paymentId) onSuccess,
    Function(String error) onFailure,
  ) async {
    // Use conditional import - web implementation uses dart:js, mobile doesn't
    await web_payment.startWebPayment(orderResponse, onSuccess, onFailure);
  }

  Future<void> _startMobilePayment(
    CreateOrderResponse orderResponse,
    Function(String paymentId) onSuccess,
    Function(String error) onFailure,
  ) async {
    try {
      // Mobile: Set up callbacks for this payment operation
      _currentSuccessCallback = (response) {
        if (kDebugMode) {
          print('📱 Mobile payment success: $response');
        }
        try {
          final paymentId = response.paymentId ?? '';
          if (paymentId.isNotEmpty) {
            onSuccess(paymentId);
          } else {
            onFailure('Payment ID not received from Razorpay');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Payment success handler error: $e');
          }
          onFailure('Payment success handling failed: $e');
        }
      };
      _currentErrorCallback = (response) {
        try {
          final message = response.description ?? 'Payment failed';
          onFailure('Payment failed: $message');
        } catch (e) {
          onFailure('Payment failed');
        }
      };
      
      final options = {
        'key': orderResponse.keyId,
        'amount': (orderResponse.amount * 100).toInt(),
        'name': 'Flutter Chat',
        'order_id': orderResponse.orderId,
        'description': 'Add money to wallet',
        'timeout': 300,
        'prefill': {
          'contact': '9999999999',
          'email': 'user@example.com'
        }
      };

      _razorpay.open(options);
    } catch (e) {
      onFailure('Mobile payment error: $e');
    }
  }

  Future<PaymentHealthResponse> checkHealth() async {
    try {
      final response = await _dio.get('$_baseUrl/api/v1/wallet/health');
      return PaymentHealthResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw Exception('Health check failed: $e');
    }
  }

  Future<Map<String, dynamic>> verifyAndCreditPayment({
    required String paymentId,
    required String orderId,
  }) async {
    try {
      if (kDebugMode) {
        print('🌐 Making verification API request...');
        print('URL: $_baseUrl/api/v1/wallet/$_defaultUserId/verify-payment');
        print('Payload: {payment_id: $paymentId, order_id: $orderId}');
      }

      final response = await _dio.post(
        '$_baseUrl/api/v1/wallet/$_defaultUserId/verify-payment',
        data: {
          'payment_id': paymentId,
          'order_id': orderId,
        },
        options: Options(
          sendTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
          responseType: ResponseType.json,
        ),
      );

      if (kDebugMode) {
        print('✅ Verification API response: ${response.data}');
        print('Status code: ${response.statusCode}');
      }

      return response.data ?? {};
    } catch (e) {
      if (kDebugMode) {
        print('❌ Verification API error: $e');
        if (e is DioException) {
          print('Dio error type: ${e.type}');
          print('Response data: ${e.response?.data}');
          print('Status code: ${e.response?.statusCode}');
        }
      }
      
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw Exception('Payment verification failed: $e');
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please try again later.';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          return e.response?.data?['detail'] ?? 'Invalid request';
        } else if (statusCode == 429) {
          return 'Too many requests. Please slow down.';
        } else if (statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return 'Request failed (${statusCode ?? 'Unknown'})';
      default:
        return 'Unexpected error occurred';
    }
  }

  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
  }
}