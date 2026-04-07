import 'package:cloud_firestore/cloud_firestore.dart';

enum Difficulty { unreviewed, easy, medium, hard }

class Flashcard {
  const Flashcard({
    required this.id,
    required this.question,
    required this.answer,
    required this.difficulty,
    required this.lastReviewedAt,
  });

  final String id;
  final String question;
  final String answer;
  final Difficulty difficulty;
  final DateTime? lastReviewedAt;

  factory Flashcard.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Flashcard(
      id: doc.id,
      question: (data['question'] as String?) ?? '',
      answer: (data['answer'] as String?) ?? '',
      difficulty: DifficultyParser.fromString(data['difficulty'] as String?),
      lastReviewedAt: _asDateTime(data['lastReviewedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'difficulty': difficulty.name,
      'lastReviewedAt':
          lastReviewedAt == null ? null : Timestamp.fromDate(lastReviewedAt!),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

extension DifficultyParser on Difficulty {
  static Difficulty fromString(String? value) {
    return Difficulty.values.firstWhere(
      (item) => item.name == value,
      orElse: () => Difficulty.unreviewed,
    );
  }
}
