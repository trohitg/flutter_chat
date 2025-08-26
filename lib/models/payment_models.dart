import 'package:json_annotation/json_annotation.dart';

part 'payment_models.g.dart';

@JsonSerializable()
class VPAValidationRequest {
  final String vpa;

  const VPAValidationRequest({
    required this.vpa,
  });

  factory VPAValidationRequest.fromJson(Map<String, dynamic> json) =>
      _$VPAValidationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VPAValidationRequestToJson(this);
}

@JsonSerializable()
class VPAValidationResponse {
  final bool valid;
  final String vpa;
  @JsonKey(name: 'account_holder_name')
  final String? accountHolderName;
  final String? error;

  const VPAValidationResponse({
    required this.valid,
    required this.vpa,
    this.accountHolderName,
    this.error,
  });

  factory VPAValidationResponse.fromJson(Map<String, dynamic> json) =>
      _$VPAValidationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VPAValidationResponseToJson(this);
}

@JsonSerializable()
class CollectRequest {
  @JsonKey(name: 'payer_vpa')
  final String payerVpa;
  final double amount;
  final String description;
  @JsonKey(name: 'beneficiary_vpa')
  final String beneficiaryVpa;
  @JsonKey(name: 'beneficiary_name')
  final String beneficiaryName;

  const CollectRequest({
    required this.payerVpa,
    required this.amount,
    required this.description,
    required this.beneficiaryVpa,
    required this.beneficiaryName,
  });

  factory CollectRequest.fromJson(Map<String, dynamic> json) =>
      _$CollectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CollectRequestToJson(this);
}

@JsonSerializable()
class CollectResponse {
  final bool success;
  @JsonKey(name: 'payment_id')
  final String? paymentId;
  @JsonKey(name: 'order_id')
  final String? orderId;
  final String? status;
  final String message;
  @JsonKey(name: 'tracking_id')
  final String? trackingId;
  @JsonKey(name: 'payment_link')
  final String? paymentLink;
  @JsonKey(name: 'upi_intent_url')
  final String? upiIntentUrl;

  const CollectResponse({
    required this.success,
    this.paymentId,
    this.orderId,
    this.status,
    required this.message,
    this.trackingId,
    this.paymentLink,
    this.upiIntentUrl,
  });

  factory CollectResponse.fromJson(Map<String, dynamic> json) =>
      _$CollectResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CollectResponseToJson(this);
}

@JsonSerializable()
class PaymentStatusResponse {
  @JsonKey(name: 'tracking_id')
  final String trackingId;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'payment_id')
  final String paymentId;
  final String status;
  final double amount;
  @JsonKey(name: 'payer_vpa')
  final String payerVpa;
  @JsonKey(name: 'beneficiary_vpa')
  final String beneficiaryVpa;
  @JsonKey(name: 'beneficiary_name')
  final String beneficiaryName;
  final String description;
  @JsonKey(name: 'payment_link')
  final String? paymentLink;
  @JsonKey(name: 'upi_intent_url')
  final String? upiIntentUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const PaymentStatusResponse({
    required this.trackingId,
    required this.orderId,
    required this.paymentId,
    required this.status,
    required this.amount,
    required this.payerVpa,
    required this.beneficiaryVpa,
    required this.beneficiaryName,
    required this.description,
    this.paymentLink,
    this.upiIntentUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentStatusResponseToJson(this);
}

@JsonSerializable()
class PaymentHealthResponse {
  final String status;
  final String service;
  final String? timestamp;
  final String? error;

  const PaymentHealthResponse({
    required this.status,
    required this.service,
    this.timestamp,
    this.error,
  });

  factory PaymentHealthResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentHealthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentHealthResponseToJson(this);
}

// Wallet Models
@JsonSerializable()
class TransactionHistoryResponse {
  final String id;
  @JsonKey(name: 'transaction_type')
  final String transactionType;
  final double amount;
  final String? description;
  @JsonKey(name: 'reference_id')
  final String? referenceId;
  @JsonKey(name: 'reference_type')
  final String? referenceType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const TransactionHistoryResponse({
    required this.id,
    required this.transactionType,
    required this.amount,
    this.description,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
  });

  factory TransactionHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionHistoryResponseToJson(this);
}

@JsonSerializable()
class WalletResponse {
  @JsonKey(name: 'user_id')
  final String userId;
  final double balance;
  @JsonKey(name: 'last_updated')
  final DateTime lastUpdated;
  @JsonKey(name: 'recent_transactions')
  final List<TransactionHistoryResponse> recentTransactions;

  const WalletResponse({
    required this.userId,
    required this.balance,
    required this.lastUpdated,
    required this.recentTransactions,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletResponseToJson(this);
}

@JsonSerializable()
class AddBalanceRequest {
  final double amount;

  const AddBalanceRequest({
    required this.amount,
  });

  factory AddBalanceRequest.fromJson(Map<String, dynamic> json) =>
      _$AddBalanceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddBalanceRequestToJson(this);
}

@JsonSerializable()
class CreateOrderResponse {
  @JsonKey(name: 'order_id')
  final String orderId;
  final double amount;
  final String currency;
  final String status;
  final String? receipt;
  @JsonKey(name: 'key_id')
  final String keyId;

  const CreateOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.status,
    this.receipt,
    required this.keyId,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderResponseToJson(this);
}