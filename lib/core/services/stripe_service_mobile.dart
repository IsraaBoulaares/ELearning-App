import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  static bool _initialized = false;
  
  static Future<void> initialize(String publishableKey) async {
    // Set publishable key immediately (synchronous)
    Stripe.publishableKey = publishableKey;
    
    // Apply settings can be slow, so we do it asynchronously without blocking
    // The settings will be applied in the background
    Stripe.instance.applySettings().then((_) {
      _initialized = true;
    }).catchError((error) {
      // Silently fail if settings can't be applied
      print('Stripe settings application failed: $error');
    });
    
    // Return immediately without waiting for applySettings
  }

  /**
   * Creates a Stripe Checkout Session via Cloud Function and opens it
   */
  static Future<String?> startCheckout(String uid) async {
    try {
      // Call Cloud Function to create checkout session
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('createCheckoutSession').call();
      
      final data = result.data as Map<String, dynamic>;
      final checkoutUrl = data['url'] as String?;
      
      if (checkoutUrl != null) {
        // Open Stripe Checkout in browser
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return data['sessionId'] as String?;
        }
      }
      
      return null;
    } catch (e) {
      print('Error starting checkout: $e');
      rethrow;
    }
  }

  /**
   * Opens the Stripe Customer Portal for subscription management.
   */
  static Future<void> openCustomerPortal() async {
    // This requires a backend call to generate a portal link
    // Would be implemented similarly to startCheckout
  }
}
