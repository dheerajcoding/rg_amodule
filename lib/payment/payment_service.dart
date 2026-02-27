// lib/payment/payment_service.dart
// Payment Abstraction Layer — Phase 1 uses MockPaymentService.
// Phase 2: swap with RazorpayPaymentService / PayUPaymentService.

// ── Domain objects ────────────────────────────────────────────────────────────

enum PaymentStatus { idle, processing, success, failed, cancelled }

class PaymentRequest {
  const PaymentRequest({
    required this.orderId,
    required this.amountPaise,
    required this.description,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.metadata = const {},
  });

  final String orderId;
  final int amountPaise;     // amount in paise (₹1 = 100 paise)
  final String description;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, dynamic> metadata;

  double get amountRupees => amountPaise / 100;
}

class PaymentResult {
  const PaymentResult({
    required this.status,
    this.transactionId,
    this.providerPaymentId,
    this.errorMessage,
    this.providerData,
  });

  final PaymentStatus status;
  final String? transactionId;
  final String? providerPaymentId;
  final String? errorMessage;
  final Map<String, dynamic>? providerData;

  bool get isSuccess => status == PaymentStatus.success;

  factory PaymentResult.success({
    required String transactionId,
    String? providerPaymentId,
    Map<String, dynamic>? providerData,
  }) =>
      PaymentResult(
        status: PaymentStatus.success,
        transactionId: transactionId,
        providerPaymentId: providerPaymentId,
        providerData: providerData,
      );

  factory PaymentResult.failed(String message) => PaymentResult(
        status: PaymentStatus.failed,
        errorMessage: message,
      );

  factory PaymentResult.cancelled() => const PaymentResult(
        status: PaymentStatus.cancelled,
      );
}

// ── Abstract interface ────────────────────────────────────────────────────────

abstract class IPaymentService {
  /// Initiates a payment flow. On mobile this opens the payment SDK.
  /// Returns a [PaymentResult] when the flow completes (success/fail/cancel).
  Future<PaymentResult> initiatePayment(PaymentRequest request);

  /// Verifies a payment server-side after client receives success callback.
  /// Returns true if verification passes.
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  });

  String get providerName;
}

// ── Mock Implementation (Phase 1) ─────────────────────────────────────────────
// Simulates a 1.5s payment processing delay and always succeeds.
// Replace with real SDK in Phase 2.

class MockPaymentService implements IPaymentService {
  @override
  String get providerName => 'mock';

  @override
  Future<PaymentResult> initiatePayment(PaymentRequest request) async {
    // Simulate network + SDK latency
    await Future.delayed(const Duration(milliseconds: 1500));

    // Generate a fake transaction ID
    final txnId = 'mock_txn_${DateTime.now().millisecondsSinceEpoch}';
    final providerId = 'mock_pay_${request.orderId}';

    return PaymentResult.success(
      transactionId: txnId,
      providerPaymentId: providerId,
      providerData: {
        'provider': 'mock',
        'orderId': request.orderId,
        'amount': request.amountPaise,
        'paidAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true; // Mock always verifies
  }
}

// ── Razorpay stub (Phase 2 ready — NOT active) ────────────────────────────────
// Uncomment and implement when integrating Razorpay.
//
// class RazorpayPaymentService implements IPaymentService {
//   @override
//   String get providerName => 'razorpay';
//
//   @override
//   Future<PaymentResult> initiatePayment(PaymentRequest request) async {
//     // TODO: Initialize Razorpay SDK
//     // var options = {
//     //   'key': RazorpayConfig.keyId,
//     //   'amount': request.amountPaise,
//     //   'name': 'Divine Pooja',
//     //   'description': request.description,
//     //   'prefill': {
//     //     'contact': request.customerPhone,
//     //     'email': request.customerEmail,
//     //   }
//     // };
//     // _razorpay.open(options);
//     throw UnimplementedError('Razorpay not yet integrated');
//   }
//
//   @override
//   Future<bool> verifyPayment({...}) async {
//     // TODO: Call backend /verify-payment endpoint
//     throw UnimplementedError();
//   }
// }
