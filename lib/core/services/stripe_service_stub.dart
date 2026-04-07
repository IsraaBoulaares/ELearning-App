// Stub implementation for unsupported platforms
class StripeService {
  static Future<void> initialize(String publishableKey) async {
    // No-op for unsupported platforms
  }

  static Future<void> startCheckout(String uid) async {
    throw UnsupportedError('Stripe is not supported on this platform');
  }

  static Future<void> openCustomerPortal() async {
    throw UnsupportedError('Stripe is not supported on this platform');
  }
}
