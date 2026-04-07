import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/flashcard.dart';
import '../providers/learning_providers.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({
    super.key,
    required this.uid,
    required this.setId,
  });

  final String uid;
  final String setId;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isFinished = false;

  final Map<Difficulty, int> _sortOrder = {
    Difficulty.unreviewed: 0,
    Difficulty.hard: 1,
    Difficulty.medium: 2,
    Difficulty.easy: 3,
  };

  void _nextCard(List<Flashcard> cards) {
    if (_currentIndex < cards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  Future<void> _updateDifficulty(Difficulty difficulty, List<Flashcard> cards) async {
    final card = cards[_currentIndex];
    final repository = ref.read(firestoreRepositoryProvider);
    
    await repository.updateFlashcardDifficulty(
      widget.uid,
      widget.setId,
      card.id,
      difficulty,
    );

    _nextCard(cards);
  }

  @override
  Widget build(BuildContext context) {
    final flashcardsAsync = ref.watch(
      flashcardStreamProvider((uid: widget.uid, setId: widget.setId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: flashcardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(child: Text('No cards in this set.'));
          }

          // Sort cards according to assessment requirements:
          // Unreviewed > Hard > Medium > Easy
          final sortedCards = List<Flashcard>.from(cards)
            ..sort((a, b) => _sortOrder[a.difficulty]!.compareTo(_sortOrder[b.difficulty]!));

          if (_isFinished) {
            return _buildCompletionView();
          }

          final currentCard = sortedCards[_currentIndex];
          final progress = (_currentIndex + 1) / sortedCards.length;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Card ${_currentIndex + 1} of ${sortedCards.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                _buildFlipCard(currentCard),
                const Spacer(),
                if (_isFlipped)
                  _buildDifficultyButtons(sortedCards)
                else
                  Text(
                    'Tap to Reveal Answer',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFlipCard(Flashcard card) {
    return GestureDetector(
      onTap: () => setState(() => _isFlipped = !_isFlipped),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: _isFlipped ? 180 : 0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (context, angle, child) {
          final isBack = angle >= 90;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle * pi / 180),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _cardContent(card.answer, isAnswer: true),
                  )
                : _cardContent(card.question, isAnswer: false),
          );
        },
      ),
    );
  }

  Widget _cardContent(String text, {required bool isAnswer}) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: isAnswer 
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontStyle: isAnswer ? FontStyle.italic : FontStyle.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildDifficultyButtons(List<Flashcard> cards) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _difficultyBtn('Hard', Colors.red, Difficulty.hard, cards),
        _difficultyBtn('Medium', Colors.orange, Difficulty.medium, cards),
        _difficultyBtn('Easy', Colors.green, Difficulty.easy, cards),
      ],
    );
  }

  Widget _difficultyBtn(String label, Color color, Difficulty diff, List<Flashcard> cards) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _updateDifficulty(diff, cards),
      child: Text(label),
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Great job! You have reviewed all cards in this session.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => context.pushReplacement('/progress/${widget.setId}'),
              icon: const Icon(Icons.bar_chart),
              label: const Text('See Progress'),
            ),
          ],
        ),
      ),
    );
  }
}
