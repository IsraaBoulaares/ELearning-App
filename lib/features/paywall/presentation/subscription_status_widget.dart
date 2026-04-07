import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_profile.dart';
import '../../learning/providers/learning_providers.dart';

class SubscriptionStatusWidget extends ConsumerWidget {
  const SubscriptionStatusWidget({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    return AsyncValueWidget<UserProfile?>(
      value: profileAsync,
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final isPremium = profile.isPremium;
        final setsCount = profile.setsCount;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isPremium 
              ? Colors.amber.shade50 
              : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPremium ? Colors.amber.shade400 : Colors.blue.shade200,
              width: 1.5,
            ),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(
              isPremium ? Icons.stars : Icons.info_outline,
              color: isPremium ? Colors.amber.shade700 : Colors.blue.shade700,
            ),
            title: Text(
              isPremium ? 'Premium Plan Active' : 'Free Plan — $setsCount/3 sets',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPremium ? Colors.amber.shade900 : Colors.blue.shade900,
              ),
            ),
            subtitle: Text(
              isPremium ? 'Instant generation & unlimited sets' : 'Upgrade to remove limits',
            ),
            trailing: !isPremium 
              ? Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue.shade300)
              : null,
            onTap: !isPremium ? () => context.push('/paywall') : null,
          ),
        );
      },
    );
  }
}

class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: LinearProgressIndicator(),
      ),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }
}
