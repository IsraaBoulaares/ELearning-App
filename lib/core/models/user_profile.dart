import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.createdAt,
    required this.isPremium,
    required this.setsCount,
  });

  final String uid;
  final String email;
  final DateTime createdAt;
  final bool isPremium;
  final int setsCount;

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return UserProfile(
      uid: (data['uid'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      createdAt: _asDateTime(data['createdAt']) ?? DateTime.now(),
      isPremium: (data['isPremium'] as bool?) ?? false,
      setsCount: (data['setsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPremium': isPremium,
      'setsCount': setsCount,
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
