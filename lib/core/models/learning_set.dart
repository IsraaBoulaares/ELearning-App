import 'package:cloud_firestore/cloud_firestore.dart';

class LearningSet {
  const LearningSet({
    required this.id,
    required this.userId,
    required this.title,
    required this.rawText,
    required this.status,
    required this.createdAt,
    required this.cardCount,
  });

  final String id;
  final String userId;
  final String title;
  final String rawText;
  final String status;
  final DateTime createdAt;
  final int cardCount;

  factory LearningSet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return LearningSet(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      rawText: (data['rawText'] as String?) ?? '',
      status: (data['status'] as String?) ?? 'processing',
      createdAt: _asDateTime(data['createdAt']) ?? DateTime.now(),
      cardCount: (data['cardCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'rawText': rawText,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'cardCount': cardCount,
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
