import 'package:flutter/foundation.dart';
import '../models/payment_models.dart';

Future<void> startWebPayment(
  CreateOrderResponse orderResponse,
  Function(String paymentId) onSuccess,
  Function(String error) onFailure,
) async {
  // This is the mobile implementation file
  // The actual mobile payment logic is handled in the main MoneyService class
  // This file exists for the conditional import system
  if (kDebugMode) {
    print('📱 Mobile payment implementation called');
  }
  
  // This shouldn't be called on mobile, but provide fallback
  onFailure('Mobile implementation called incorrectly');
}