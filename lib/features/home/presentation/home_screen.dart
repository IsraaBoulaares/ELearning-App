import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../learning/presentation/create_set_sheet.dart';
import '../../learning/providers/learning_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final setsAsync = ref.watch(learningSetStreamProvider(user.uid));
        final profileAsync = ref.watch(userProfileProvider(user.uid));

        final canCreateSet = profileAsync.asData?.value == null
            ? true
            : _canCreateSet(profileAsync.asData!.value!);

        return Scaffold(
          appBar: AppBar(
            title: const Text('LearnFlow'),
            actions: [
              IconButton(
                onPressed: () async {
                  final authRepo = ref.read(authRepositoryProvider);
                  await authRepo.signOut();
                  if (!context.mounted) return;
                },
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Log Out',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _buildWelcomeHeader(user.email ?? 'User'),
                const SizedBox(height: 24),
                
                // Subscription Status
                profileAsync.when(
                  data: (profile) {
                    if (profile == null) return const SizedBox.shrink();
                    return _buildSubscriptionCard(context, profile);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                
                // Learning Sets Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Learning Sets',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    setsAsync.when(
                      data: (sets) => Text(
                        '${sets.length} sets',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Learning Sets List
                setsAsync.when(
                  data: (sets) {
                    if (sets.isEmpty) {
                      return _buildEmptyState();
                    }

                    return Column(
                      children: sets.map((set) {
                        final isReady = set.status == 'ready';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildLearningSetCard(
                            context,
                            set.title,
                            set.cardCount,
                            set.status,
                            isReady,
                            () {
                              if (!context.mounted) return;
                              context.push('/study/${set.id}');
                            },
                            () {
                              if (!context.mounted) return;
                              context.push('/progress/${set.id}');
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'Could not load sets: $error',
                        style: const TextStyle(color: AppTheme.hardRed),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (!context.mounted) return;
              
              if (canCreateSet) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CreateSetSheet(uid: user.uid),
                );
              } else {
                context.push('/paywall');
              }
            },
            icon: Icon(canCreateSet ? Icons.add_rounded : Icons.star_rounded),
            label: Text(canCreateSet ? 'Create Set' : 'Get Premium'),
            backgroundColor: AppTheme.primaryPurple,
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            'Auth error: $error',
            style: const TextStyle(color: AppTheme.hardRed),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('👋', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, UserProfile profile) {
    final isPremium = profile.isPremium;
    final setsCount = profile.setsCount;

    return GestureDetector(
      onTap: !isPremium ? () => context.push('/paywall') : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isPremium ? AppTheme.goldGradient : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isPremium ? Colors.amber : AppTheme.primaryPurple).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isPremium ? Icons.stars_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPremium ? 'Premium Active' : 'Free Plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPremium
                        ? 'Unlimited sets & advanced features'
                        : '$setsCount/3 sets used • Tap to upgrade',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!isPremium)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningSetCard(
    BuildContext context,
    String title,
    int cardCount,
    String status,
    bool isReady,
    VoidCallback onTap,
    VoidCallback onProgressTap,
  ) {
    return GestureDetector(
      onTap: isReady ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.style_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$cardCount cards',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isReady)
                  IconButton(
                    onPressed: onProgressTap,
                    icon: const Icon(
                      Icons.analytics_rounded,
                      color: AppTheme.secondaryTeal,
                    ),
                    tooltip: 'View Progress',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isReady
                    ? AppTheme.easyGreen.withOpacity(0.2)
                    : AppTheme.mediumAmber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isReady ? AppTheme.easyGreen : AppTheme.mediumAmber,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isReady ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
                    size: 16,
                    color: isReady ? AppTheme.easyGreen : AppTheme.mediumAmber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isReady ? 'Ready' : 'Processing',
                    style: TextStyle(
                      color: isReady ? AppTheme.easyGreen : AppTheme.mediumAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No learning sets yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first set to start learning',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _canCreateSet(UserProfile profile) {
    return profile.isPremium || profile.setsCount < 3;
  }
}
