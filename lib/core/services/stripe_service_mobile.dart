import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static Future<void> initialize(String publishableKey) async {
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  /**
   * In a real implementation, this would call your backend to 
   * create a Stripe Checkout Session and return the URL. 
   * Here we simulate the trigger.
   */
  static Future<void> startCheckout(String uid) async {
    // 1. Call Cloud Function to create session
    // 2. Redirect to Stripe Checkout URL
    // 3. Webhook (handleStripeWebhook) will update Firestore
  }

  /**
   * Opens the Stripe Customer Portal for subscription management.
   */
  static Future<void> openCustomerPortal() async {
    // This requires a backend call to generate a portal link
  }
}
