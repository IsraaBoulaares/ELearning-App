import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learning/presentation/progress_screen.dart';
import '../../features/learning/presentation/study_screen.dart';
import '../../features/paywall/presentation/paywall_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/study/:setId',
        builder: (context, state) {
          final setId = state.pathParameters['setId']!;
          final user = authState.asData?.value;
          return StudyScreen(uid: user!.uid, setId: setId);
        },
      ),
      GoRoute(
        path: '/progress/:setId',
        builder: (context, state) {
          final setId = state.pathParameters['setId']!;
          final user = authState.asData?.value;
          return ProgressScreen(uid: user!.uid, setId: setId);
        },
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
    ],
    redirect: (context, state) {
      final user = authState.asData?.value;
      final isAuthenticated = user != null;
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
  );
});
