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
      
      if (!mounted) return;
      
      // Show mock payment form
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _MockStripeCheckoutDialog(uid: uid),
      );
      
      if (result == true && mounted) {
        // Payment successful
        final repository = ref.read(firestoreRepositoryProvider);
        await repository.updateUserPremiumStatus(uid, true);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Welcome to Premium 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
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

class _MockStripeCheckoutDialog extends StatefulWidget {
  const _MockStripeCheckoutDialog({required this.uid});
  
  final String uid;

  @override
  State<_MockStripeCheckoutDialog> createState() => _MockStripeCheckoutDialogState();
}

class _MockStripeCheckoutDialogState extends State<_MockStripeCheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController(text: '4242 4242 4242 4242');
  final _expiryController = TextEditingController(text: '12/25');
  final _cvcController = TextEditingController(text: '123');
  final _nameController = TextEditingController(text: 'Test User');
  bool _isProcessing = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    Navigator.of(context).pop(true); // Return success
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/stripe_logo.png',
                        height: 24,
                        errorBuilder: (_, __, ___) => const Icon(Icons.payment, size: 24),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Stripe Checkout',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _isProcessing ? null : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Premium Plan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$4.99/month',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Unlimited learning sets • Advanced analytics'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      hintText: '4242 4242 4242 4242',
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Card number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry',
                            hintText: 'MM/YY',
                          ),
                          keyboardType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvcController,
                          decoration: const InputDecoration(
                            labelText: 'CVC',
                            hintText: '123',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Demo Mode: This is a simulated payment form. Use the pre-filled test card.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Pay \$4.99', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Secured by Stripe',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
