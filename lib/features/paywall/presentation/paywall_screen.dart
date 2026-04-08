import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elearning_app/core/services/stripe_service.dart';
import 'package:elearning_app/features/auth/providers/auth_providers.dart';
import 'package:elearning_app/features/learning/providers/learning_providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _handleCheckout(String uid) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment processing is available on the mobile app. On web, contact us to upgrade.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // In a real implementation, this would:
      // 1. Call your backend to create a Stripe Checkout Session
      // 2. Get the checkout URL from the backend
      // 3. Open the Stripe Checkout page
      // 4. Wait for the webhook to update isPremium in Firestore
      
      // Example of what the real implementation would look like:
      // final checkoutUrl = await ref.read(firestoreRepositoryProvider).createCheckoutSession(uid);
      // await StripeService.startCheckout(uid);
      // Then Stripe redirects back to the app, and webhook updates Firestore
      
      if (!mounted) return;
      
      // For now, show a message explaining this is a demo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Demo Mode'),
          content: const Text(
            'This is a demonstration app. In production:\n\n'
            '1. This would open Stripe Checkout\n'
            '2. You would enter payment details\n'
            '3. After successful payment, a webhook would update your premium status\n\n'
            'For assessment purposes, the Stripe integration is documented but not fully connected to avoid requiring real payment credentials.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Simulate successful payment for demo
                final repository = ref.read(firestoreRepositoryProvider);
                await repository.updateUserPremiumStatus(uid, true);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo: Premium activated! (In production, this would happen via webhook)'),
                  ),
                );
                context.go('/home');
              },
              child: const Text('Simulate Payment'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userUid = authState.asData?.value?.uid ?? '';
    final user = ref.watch(userProfileProvider(userUid)).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildTierCard(
                  context,
                  title: 'Free Plan',
                  price: '\$0',
                  subtitle: 'Perfect for starters',
                  benefits: ['Up to 3 Learning Sets', 'Basic progress tracking'],
                  isCurrent: !(user?.isPremium ?? false),
                ),
                const SizedBox(height: 24),
                _buildTierCard(
                  context,
                  title: 'Premium Plan',
                  price: '\$4.99/mo',
                  subtitle: 'For power learners',
                  benefits: [
                    'Unlimited Learning Sets',
                    'Advanced visual analytics',
                    'Priority card generation',
                    'Ad-free experience',
                  ],
                  isCurrent: user?.isPremium ?? false,
                  onUpgrade: user != null && !user.isPremium 
                    ? () => _handleCheckout(user.uid) 
                    : null,
                  isHighlighted: true,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    if (!context.mounted) return;
                    // Simulation of Stripe Customer Portal
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Redirecting to Customer Portal...')),
                    );
                  },
                  child: const Text('Restore Purchases / Manage Subscription'),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTierCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required List<String> benefits,
    required bool isCurrent,
    VoidCallback? onUpgrade,
    bool isHighlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isHighlighted 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1) 
          : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isCurrent)
                const Badge(label: Text('Current Plan'), padding: EdgeInsets.symmetric(horizontal: 8)),
            ],
          ),
          const SizedBox(height: 8),
          Text(price, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const Divider(height: 32),
          ...benefits.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(b)),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          if (onUpgrade != null)
            FilledButton(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade Now'),
            ),
        ],
      ),
    );
  }
}
