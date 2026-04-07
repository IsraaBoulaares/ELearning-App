import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../../learning/presentation/create_set_sheet.dart';
import '../../learning/providers/learning_providers.dart';
import '../../paywall/presentation/subscription_status_widget.dart';

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
            title: const Text('Learning Sets'),
            actions: [
              IconButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Log Out',
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubscriptionStatusWidget(uid: user.uid),
                profileAsync.when(
                  data: (profile) {
                    if (profile == null || _canCreateSet(profile)) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Free plan limit reached (3 sets). Upgrade to Premium to create more sets.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                if (!canCreateSet) const SizedBox(height: 12),
                Expanded(
                  child: setsAsync.when(
                    data: (sets) {
                      if (sets.isEmpty) {
                        return const Center(
                          child: Text('No learning sets yet. Create your first set.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: sets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final set = sets[index];
                          final isReady = set.status == 'ready';

                          return ListTile(
                            onTap: isReady ? () => context.push('/study/${set.id}') : null,
                            leading: isReady
                                ? CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primaryContainer,
                                    child: const Icon(Icons.book),
                                  )
                                : const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                            title: Text(set.title),
                            subtitle: Text(
                              'Status: ${set.status}  |  Cards: ${set.cardCount}',
                            ),
                            trailing: isReady
                                ? IconButton(
                                    icon: const Icon(Icons.analytics_outlined),
                                    onPressed: () => context.push('/progress/${set.id}'),
                                    tooltip: 'View Progress',
                                  )
                                : null,
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Text('Could not load sets: $error'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              if (canCreateSet) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => CreateSetSheet(uid: user.uid),
                );
              } else {
                context.push('/paywall');
              }
            },
            icon: Icon(canCreateSet ? Icons.add : Icons.star),
            label: Text(canCreateSet ? 'Create Set' : 'Get Premium'),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Auth error: $error')),
      ),
    );
  }

  bool _canCreateSet(UserProfile profile) {
    return profile.isPremium || profile.setsCount < 3;
  }
}
