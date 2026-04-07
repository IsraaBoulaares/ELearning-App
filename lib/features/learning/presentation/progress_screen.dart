import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/learning_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({
    super.key,
    required this.uid,
    required this.setId,
  });

  final String uid;
  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressProvider((uid: uid, setId: setId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Progress'),
      ),
      body: progressAsync.when(
        data: (progress) {
          final total = progress.totalCards;
          final reviewed = progress.reviewed;
          final percentage = total == 0 ? 0.0 : (reviewed / total) * 100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, reviewed, total, percentage),
                const SizedBox(height: 32),
                Text(
                  'Difficulty Distribution',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildDifficultyBar('Easy', progress.easy, total, Colors.green),
                const SizedBox(height: 12),
                _buildDifficultyBar('Medium', progress.medium, total, Colors.orange),
                const SizedBox(height: 12),
                _buildDifficultyBar('Hard', progress.hard, total, Colors.red),
                const SizedBox(height: 12),
                _buildDifficultyBar(
                  'Unreviewed',
                  total - reviewed,
                  total,
                  Theme.of(context).disabledColor,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int reviewed, int total, double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Keep it up!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviewed $reviewed out of $total cards',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBar(String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(height: 12, color: color.withOpacity(0.1)),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                height: 12,
                width: 300 * ratio, // Simple visual bar
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
