import 'package:cloud_firestore/cloud_firestore.dart';

class Progress {
  const Progress({
    required this.setId,
    required this.totalCards,
    required this.reviewed,
    required this.easy,
    required this.medium,
    required this.hard,
    required this.lastStudiedAt,
  });

  final String setId;
  final int totalCards;
  final int reviewed;
  final int easy;
  final int medium;
  final int hard;
  final DateTime? lastStudiedAt;

  factory Progress.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return Progress(
      setId: (data['setId'] as String?) ?? doc.id,
      totalCards: (data['totalCards'] as num?)?.toInt() ?? 0,
      reviewed: (data['reviewed'] as num?)?.toInt() ?? 0,
      easy: (data['easy'] as num?)?.toInt() ?? 0,
      medium: (data['medium'] as num?)?.toInt() ?? 0,
      hard: (data['hard'] as num?)?.toInt() ?? 0,
      lastStudiedAt: _asDateTime(data['lastStudiedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'setId': setId,
      'totalCards': totalCards,
      'reviewed': reviewed,
      'easy': easy,
      'medium': medium,
      'hard': hard,
      'lastStudiedAt':
          lastStudiedAt == null ? null : Timestamp.fromDate(lastStudiedAt!),
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
