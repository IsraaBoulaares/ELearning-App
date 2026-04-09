import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/learning_providers.dart';
import '../../../core/theme/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Learning Progress'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                // Circular progress indicator
                _buildCircularProgress(context, reviewed, total, percentage),
                const SizedBox(height: 32),
                
                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Easy',
                        progress.easy,
                        AppTheme.easyGreen,
                        Icons.sentiment_satisfied_alt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Medium',
                        progress.medium,
                        AppTheme.mediumAmber,
                        Icons.sentiment_neutral,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Hard',
                        progress.hard,
                        AppTheme.hardRed,
                        Icons.sentiment_dissatisfied,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Difficulty distribution
                Text(
                  'Difficulty Distribution',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDifficultyBar(context, 'Easy', progress.easy, total, AppTheme.easyGreen),
                const SizedBox(height: 16),
                _buildDifficultyBar(context, 'Medium', progress.medium, total, AppTheme.mediumAmber),
                const SizedBox(height: 16),
                _buildDifficultyBar(context, 'Hard', progress.hard, total, AppTheme.hardRed),
                const SizedBox(height: 16),
                _buildDifficultyBar(
                  context,
                  'Not Reviewed',
                  total - reviewed,
                  total,
                  AppTheme.textSecondary,
                ),
                
                const SizedBox(height: 32),
                
                // Last studied timestamp
                if (progress.lastStudiedAt != null)
                  _buildLastStudiedCard(context, progress.lastStudiedAt!),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
          ),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.hardRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgress(BuildContext context, int reviewed, int total, double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.textSecondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage < 33
                        ? AppTheme.hardRed
                        : percentage < 66
                            ? AppTheme.mediumAmber
                            : AppTheme.easyGreen,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$reviewed of $total cards reviewed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total - reviewed == 0
                ? '🎉 All cards mastered!'
                : '${total - reviewed} cards remaining',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBar(BuildContext context, String label, int count, int total, Color color) {
    final ratio = total == 0 ? 0.0 : count / total;
    final percentage = (ratio * 100).toStringAsFixed(1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$count ($percentage%)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // Use available width from parent, ensure it's never negative
            final availableWidth = max(0.0, constraints.maxWidth);
            final barWidth = max(0.0, availableWidth * ratio);
            
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 12,
                    width: availableWidth,
                    color: color.withOpacity(0.15),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 12,
                    width: barWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLastStudiedCard(BuildContext context, DateTime lastStudied) {
    final now = DateTime.now();
    final difference = now.difference(lastStudied);
    
    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'Just now';
    } else if (difference.inHours < 1) {
      timeAgo = '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      timeAgo = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      timeAgo = DateFormat('MMM d, y').format(lastStudied);
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryTeal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryTeal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.schedule,
              color: AppTheme.secondaryTeal,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Studied',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
