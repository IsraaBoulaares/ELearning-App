/**
 * REVENUECAT SERVICE - SUBSCRIPTION LAYER
 * 
 * 1. How RevenueCat connects to App Stores:
 * RevenueCat acts as a middleware between the Apple App Store / Google Play Store 
 * and your app. When a user initiates a purchase, RevenueCat's SDK handles 
 * the platform-specific communication, validates the receipt, and provides 
 * a unified JSON response across all platforms.
 * 
 * 2. How Entitlements work:
 * Entitlements are logical groupings of products. Instead of checking for 
 * specific "Product IDs", we check if the user has the "premium" entitlement. 
 * This allows us to change products in the dashboard without updating the app code.
 * 
 * 3. Why server-side validation is required:
 * Client-side checks are vulnerable to manipulation (phone "rooting" or 
 * intercepting network calls). RevenueCat performs server-to-server 
 * validation with Apple/Google to ensure every transaction is authentic 
 * before granting an entitlement.
 */

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static Future<void> initialize(String apiKey, String? userId) async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      // Note: Use your Android API Key here
      configuration = PurchasesConfiguration(apiKey);
    } else {
      // Note: Use your iOS API Key here
      configuration = PurchasesConfiguration(apiKey);
    }

    if (userId != null) {
      configuration.appUserId = userId;
    }

    await Purchases.configure(configuration);
  }

  static Future<bool> isPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // Check if 'premium' entitlement is active
      return customerInfo.entitlements.active.containsKey('premium');
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> purchasePremium() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        // Purchase the first available package (usually monthly/yearly)
        CustomerInfo customerInfo = await Purchases.purchasePackage(
          offerings.current!.availablePackages.first,
        );
        return customerInfo.entitlements.active.containsKey('premium');
      }
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        rethrow;
      }
    }
    return false;
  }

  static Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    await Purchases.logOut();
  }
}
