import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/learning_providers.dart';

/// Temporary helper screen to reset and recalculate progress counters
/// Use this if progress tracking gets corrupted
/// 
/// To use: Add a button in HomeScreen that navigates to this screen
/// After fixing data, you can remove this file
class ResetProgressHelper extends ConsumerWidget {
  const ResetProgressHelper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final uid = authState.asData?.value?.uid ?? '';
    
    if (uid.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final setsAsync = ref.watch(learningSetStreamProvider(uid));

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Reset Progress Helper'),
        backgroundColor: Colors.transparent,
      ),
      body: setsAsync.when(
        data: (sets) {
          if (sets.isEmpty) {
            return const Center(
              child: Text(
                'No learning sets found',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (context, index) {
              final set = sets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: AppTheme.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        set.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set ID: ${set.id}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final repo = ref.read(firestoreRepositoryProvider);
                                  await repo.resetProgressCounters(uid, set.id);
                                  
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Reset counters for "${set.title}"'),
                                      backgroundColor: AppTheme.easyGreen,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppTheme.hardRed,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset to 0'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.mediumAmber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final repo = ref.read(firestoreRepositoryProvider);
                                  await repo.recalculateProgress(uid, set.id);
                                  
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Recalculated progress for "${set.title}"'),
                                      backgroundColor: AppTheme.easyGreen,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppTheme.hardRed,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.calculate),
                              label: const Text('Recalculate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppTheme.hardRed),
          ),
        ),
      ),
    );
  }
}
