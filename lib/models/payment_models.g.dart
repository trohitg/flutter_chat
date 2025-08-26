// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VPAValidationRequest _$VPAValidationRequestFromJson(
        Map<String, dynamic> json) =>
    VPAValidationRequest(
      vpa: json['vpa'] as String,
    );

Map<String, dynamic> _$VPAValidationRequestToJson(
        VPAValidationRequest instance) =>
    <String, dynamic>{
      'vpa': instance.vpa,
    };

VPAValidationResponse _$VPAValidationResponseFromJson(
        Map<String, dynamic> json) =>
    VPAValidationResponse(
      valid: json['valid'] as bool,
      vpa: json['vpa'] as String,
      accountHolderName: json['account_holder_name'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$VPAValidationResponseToJson(
        VPAValidationResponse instance) =>
    <String, dynamic>{
      'valid': instance.valid,
      'vpa': instance.vpa,
      'account_holder_name': instance.accountHolderName,
      'error': instance.error,
    };

CollectRequest _$CollectRequestFromJson(Map<String, dynamic> json) =>
    CollectRequest(
      payerVpa: json['payer_vpa'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      beneficiaryVpa: json['beneficiary_vpa'] as String,
      beneficiaryName: json['beneficiary_name'] as String,
    );

Map<String, dynamic> _$CollectRequestToJson(CollectRequest instance) =>
    <String, dynamic>{
      'payer_vpa': instance.payerVpa,
      'amount': instance.amount,
      'description': instance.description,
      'beneficiary_vpa': instance.beneficiaryVpa,
      'beneficiary_name': instance.beneficiaryName,
    };

CollectResponse _$CollectResponseFromJson(Map<String, dynamic> json) =>
    CollectResponse(
      success: json['success'] as bool,
      paymentId: json['payment_id'] as String?,
      orderId: json['order_id'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String,
      trackingId: json['tracking_id'] as String?,
      paymentLink: json['payment_link'] as String?,
      upiIntentUrl: json['upi_intent_url'] as String?,
    );

Map<String, dynamic> _$CollectResponseToJson(CollectResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'payment_id': instance.paymentId,
      'order_id': instance.orderId,
      'status': instance.status,
      'message': instance.message,
      'tracking_id': instance.trackingId,
      'payment_link': instance.paymentLink,
      'upi_intent_url': instance.upiIntentUrl,
    };

PaymentStatusResponse _$PaymentStatusResponseFromJson(
        Map<String, dynamic> json) =>
    PaymentStatusResponse(
      trackingId: json['tracking_id'] as String,
      orderId: json['order_id'] as String,
      paymentId: json['payment_id'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      payerVpa: json['payer_vpa'] as String,
      beneficiaryVpa: json['beneficiary_vpa'] as String,
      beneficiaryName: json['beneficiary_name'] as String,
      description: json['description'] as String,
      paymentLink: json['payment_link'] as String?,
      upiIntentUrl: json['upi_intent_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PaymentStatusResponseToJson(
        PaymentStatusResponse instance) =>
    <String, dynamic>{
      'tracking_id': instance.trackingId,
      'order_id': instance.orderId,
      'payment_id': instance.paymentId,
      'status': instance.status,
      'amount': instance.amount,
      'payer_vpa': instance.payerVpa,
      'beneficiary_vpa': instance.beneficiaryVpa,
      'beneficiary_name': instance.beneficiaryName,
      'description': instance.description,
      'payment_link': instance.paymentLink,
      'upi_intent_url': instance.upiIntentUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

PaymentHealthResponse _$PaymentHealthResponseFromJson(
        Map<String, dynamic> json) =>
    PaymentHealthResponse(
      status: json['status'] as String,
      service: json['service'] as String,
      timestamp: json['timestamp'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$PaymentHealthResponseToJson(
        PaymentHealthResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'service': instance.service,
      'timestamp': instance.timestamp,
      'error': instance.error,
    };

TransactionHistoryResponse _$TransactionHistoryResponseFromJson(
        Map<String, dynamic> json) =>
    TransactionHistoryResponse(
      id: json['id'] as String,
      transactionType: json['transaction_type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TransactionHistoryResponseToJson(
        TransactionHistoryResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transaction_type': instance.transactionType,
      'amount': instance.amount,
      'description': instance.description,
      'reference_id': instance.referenceId,
      'reference_type': instance.referenceType,
      'created_at': instance.createdAt.toIso8601String(),
    };

WalletResponse _$WalletResponseFromJson(Map<String, dynamic> json) =>
    WalletResponse(
      userId: json['user_id'] as String,
      balance: (json['balance'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      recentTransactions: (json['recent_transactions'] as List<dynamic>)
          .map((e) =>
              TransactionHistoryResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WalletResponseToJson(WalletResponse instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'balance': instance.balance,
      'last_updated': instance.lastUpdated.toIso8601String(),
      'recent_transactions': instance.recentTransactions,
    };

AddBalanceRequest _$AddBalanceRequestFromJson(Map<String, dynamic> json) =>
    AddBalanceRequest(
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$AddBalanceRequestToJson(AddBalanceRequest instance) =>
    <String, dynamic>{
      'amount': instance.amount,
    };

CreateOrderResponse _$CreateOrderResponseFromJson(Map<String, dynamic> json) =>
    CreateOrderResponse(
      orderId: json['order_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      receipt: json['receipt'] as String?,
      keyId: json['key_id'] as String,
    );

Map<String, dynamic> _$CreateOrderResponseToJson(
        CreateOrderResponse instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'amount': instance.amount,
      'currency': instance.currency,
      'status': instance.status,
      'receipt': instance.receipt,
      'key_id': instance.keyId,
    };
