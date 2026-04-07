import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/stripe_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Stripe - platform-specific implementation handles web compatibility
  await StripeService.initialize('pk_test_51TJKWaQRFCiPTLzCAtqFpvDnZUTJ15MGgV12oXCePAYOLyN5nvMfPq1ak4BQorxZWIVRESBySg1D7uIW3WRrjg1v00YQTiIqIs');
  
  runApp(const ProviderScope(child: MyApp()));
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