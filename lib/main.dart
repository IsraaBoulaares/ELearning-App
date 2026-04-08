import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/stripe_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with timeout to prevent hanging
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Firebase initialization timed out');
        throw TimeoutException('Firebase initialization took too long');
      },
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue app launch even if Firebase fails
  }
  
  // Initialize Stripe with timeout - platform-specific implementation handles web compatibility
  if (!kIsWeb) {
    try {
      await StripeService.initialize(
        'pk_test_51TJKWaQRFCiPTLzCAtqFpvDnZUTJ15MGgV12oXCePAYOLyN5nvMfPq1ak4BQorxZWIVRESBySg1D7uIW3WRrjg1v00YQTiIqIs',
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('Stripe initialization timed out - continuing without Stripe');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Stripe initialization error: $e');
      // Stripe failed silently, app continues
    }
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'eLearning App',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}