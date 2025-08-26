import 'package:flutter/foundation.dart';
import 'dart:js' as js;
import '../models/payment_models.dart';

Future<void> startWebPayment(
  CreateOrderResponse orderResponse,
  Function(String paymentId) onSuccess,
  Function(String error) onFailure,
) async {
  try {
    if (kDebugMode) {
      print('🌐 Opening Razorpay checkout...');
      print('Order: ${orderResponse.orderId}');
      print('Amount: ₹${orderResponse.amount}');
      print('Key: ${orderResponse.keyId}');
    }

    // Use JavaScript interop to call Razorpay checkout
    final options = js.JsObject.jsify({
      'key': orderResponse.keyId,
      'amount': (orderResponse.amount * 100).toInt(),
      'currency': orderResponse.currency,
      'name': 'Flutter Chat',
      'description': 'Add money to wallet',
      'order_id': orderResponse.orderId,
      'prefill': {
        'contact': '9999999999',
        'email': 'user@example.com'
      },
      'theme': {
        'color': '#009688'
      }
    });

    // Web success callback - restore working verification
    final successCallback = js.allowInterop((String paymentId, String orderId, String signature) {
      if (kDebugMode) {
        print('✅ Web payment success callback triggered!');
        print('Payment ID: $paymentId');
        print('Order ID: $orderId');
        print('Signature: $signature');
      }
      try {
        onSuccess(paymentId);
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error in success callback: $e');
        }
        onFailure('Success callback error: $e');
      }
    });

    // Create error callback with better debugging
    final errorCallback = js.allowInterop((String error) {
      if (kDebugMode) {
        print('❌ Payment error callback triggered: $error');
      }
      onFailure(error);
    });

    // Check if the JavaScript handler exists
    if (js.context['flutterRazorpayHandler'] == null) {
      throw Exception('flutterRazorpayHandler not found in window object');
    }

    if (kDebugMode) {
      print('🚀 Calling JavaScript handler...');
    }

    // Call the global JavaScript handler from index.html
    js.context['flutterRazorpayHandler'].callMethod('openCheckout', [options, successCallback, errorCallback]);
    
  } catch (e) {
    if (kDebugMode) {
      print('❌ Web payment error: $e');
    }
    onFailure('Web payment error: $e');
  }
}