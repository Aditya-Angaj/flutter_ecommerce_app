import 'dart:async';

class PaymentService {
  // Mock payment service - In production, integrate with Stripe, Razorpay, etc.
  
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock payment success (90% success rate)
    final success = DateTime.now().second % 10 != 0;

    if (success) {
      return PaymentResult(
        success: true,
        transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        message: 'Payment successful',
      );
    } else {
      return PaymentResult(
        success: false,
        transactionId: null,
        message: 'Payment failed. Please try again.',
      );
    }
  }

  Future<bool> refundPayment(String transactionId) async {
    // Simulate refund processing
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<PaymentMethodInfo> getPaymentMethods() async {
    return PaymentMethodInfo(
      methods: [
        PaymentMethod(
          id: 'card',
          name: 'Credit/Debit Card',
          icon: '💳',
          isAvailable: true,
        ),
        PaymentMethod(
          id: 'upi',
          name: 'UPI',
          icon: '📱',
          isAvailable: true,
        ),
        PaymentMethod(
          id: 'netbanking',
          name: 'Net Banking',
          icon: '🏦',
          isAvailable: true,
        ),
        PaymentMethod(
          id: 'wallet',
          name: 'Wallet',
          icon: '👛',
          isAvailable: true,
        ),
        PaymentMethod(
          id: 'cod',
          name: 'Cash on Delivery',
          icon: '💵',
          isAvailable: true,
        ),
      ],
    );
  }
}

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String message;

  PaymentResult({
    required this.success,
    this.transactionId,
    required this.message,
  });
}

class PaymentMethodInfo {
  final List<PaymentMethod> methods;

  PaymentMethodInfo({required this.methods});
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final bool isAvailable;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.isAvailable,
  });
}