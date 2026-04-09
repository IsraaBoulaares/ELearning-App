import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elearning_app/core/services/stripe_service.dart';
import 'package:elearning_app/core/theme/app_theme.dart';
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
      // Call the real Stripe checkout
      final sessionId = await StripeService.startCheckout(uid);
      
      if (!mounted) return;
      
      if (sessionId != null) {
        // Show success message - webhook will update premium status
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Checkout opened! Complete payment in your browser. '
              'Your premium status will update automatically.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        
        // Return to home - user can check back after payment
        if (mounted) {
          context.go('/home');
        }
      } else {
        throw Exception('Failed to create checkout session');
      }
    } catch (e) {
      if (!mounted) return;
      
      // Show error with option to use demo mode
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Checkout Error'),
          content: Text(
            'Could not start Stripe checkout: ${e.toString()}\n\n'
            'This might happen if:\n'
            '• Cloud Functions are not deployed\n'
            '• Stripe API key is not configured\n'
            '• Network connection issues\n\n'
            'Would you like to use demo mode instead?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Show mock payment form as fallback
                final result = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => _MockStripeCheckoutDialog(uid: uid),
                );
                
                if (result == true && mounted) {
                  final repository = ref.read(firestoreRepositoryProvider);
                  await repository.updateUserPremiumStatus(uid, true);
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Demo payment successful! Welcome to Premium 🎉'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.go('/home');
                }
              },
              child: const Text('Use Demo Mode'),
            ),
          ],
        ),
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
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background gradient decoration
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryPurple.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondaryTeal.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hero section
                const Icon(
                  Icons.workspace_premium,
                  size: 80,
                  color: AppTheme.primaryPurple,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlock Your Full Potential',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join thousands of learners achieving their goals',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Comparison cards
                _buildComparisonCard(
                  context,
                  title: 'Free',
                  price: '\$0',
                  period: 'forever',
                  features: [
                    _Feature(icon: Icons.layers, text: 'Up to 3 learning sets', included: true),
                    _Feature(icon: Icons.bar_chart, text: 'Basic progress tracking', included: true),
                    _Feature(icon: Icons.auto_awesome, text: 'AI card generation', included: false),
                    _Feature(icon: Icons.analytics, text: 'Advanced analytics', included: false),
                    _Feature(icon: Icons.speed, text: 'Priority processing', included: false),
                  ],
                  isCurrent: !isPremium,
                  isRecommended: false,
                ),
                const SizedBox(height: 20),
                
                _buildComparisonCard(
                  context,
                  title: 'Premium',
                  price: '\$4.99',
                  period: 'per month',
                  features: [
                    _Feature(icon: Icons.all_inclusive, text: 'Unlimited learning sets', included: true),
                    _Feature(icon: Icons.bar_chart, text: 'Advanced progress tracking', included: true),
                    _Feature(icon: Icons.auto_awesome, text: 'Priority AI generation', included: true),
                    _Feature(icon: Icons.analytics, text: 'Visual analytics dashboard', included: true),
                    _Feature(icon: Icons.speed, text: '3x faster processing', included: true),
                  ],
                  isCurrent: isPremium,
                  isRecommended: true,
                  onUpgrade: !isPremium && user != null 
                    ? () => _handleCheckout(user.uid) 
                    : null,
                ),
                
                const SizedBox(height: 32),
                
                // Benefits section
                _buildBenefitsSection(context),
                
                const SizedBox(height: 32),
                
                // Testimonial or trust badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.secondaryTeal.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: AppTheme.secondaryTeal,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Payment',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Powered by Stripe. Cancel anytime.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (isPremium)
                  TextButton.icon(
                    onPressed: () {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Redirecting to Customer Portal...')),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Manage Subscription'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.secondaryTeal,
                    ),
                  ),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required List<_Feature> features,
    required bool isCurrent,
    required bool isRecommended,
    VoidCallback? onUpgrade,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isRecommended
            ? LinearGradient(
                colors: [
                  AppTheme.primaryPurple.withOpacity(0.2),
                  AppTheme.cardBackground,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isRecommended ? null : AppTheme.cardBackground,
        border: Border.all(
          color: isRecommended 
            ? AppTheme.primaryPurple 
            : AppTheme.textSecondary.withOpacity(0.2),
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.easyGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.easyGreen),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: AppTheme.easyGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isRecommended ? AppTheme.primaryPurple : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        period,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: feature.included 
                            ? AppTheme.easyGreen.withOpacity(0.2)
                            : AppTheme.textSecondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          feature.included ? Icons.check : Icons.close,
                          size: 16,
                          color: feature.included 
                            ? AppTheme.easyGreen 
                            : AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        feature.icon,
                        size: 20,
                        color: feature.included 
                          ? AppTheme.textPrimary 
                          : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature.text,
                          style: TextStyle(
                            color: feature.included 
                              ? AppTheme.textPrimary 
                              : AppTheme.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (onUpgrade != null) ...[
                  const SizedBox(height: 24),
                  AppTheme.gradientButton(
                    text: 'Upgrade to Premium',
                    onPressed: onUpgrade,
                    isLoading: false,
                    width: double.infinity,
                  ),
                ],
              ],
            ),
          ),
          if (isRecommended)
            Positioned(
              top: 0,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Go Premium?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        _buildBenefitItem(
          context,
          icon: Icons.rocket_launch,
          title: 'Learn Faster',
          description: 'Priority AI processing means your flashcards are ready in seconds',
          color: AppTheme.primaryPurple,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          context,
          icon: Icons.insights,
          title: 'Track Progress',
          description: 'Visual analytics help you understand your learning patterns',
          color: AppTheme.secondaryTeal,
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          context,
          icon: Icons.all_inclusive,
          title: 'No Limits',
          description: 'Create unlimited learning sets for all your subjects',
          color: AppTheme.easyGreen,
        ),
      ],
    );
  }

  Widget _buildBenefitItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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

class _Feature {
  final IconData icon;
  final String text;
  final bool included;

  _Feature({
    required this.icon,
    required this.text,
    required this.included,
  });
}
