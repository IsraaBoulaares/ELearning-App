import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/flashcard.dart';
import '../../../core/models/learning_set.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/user_profile.dart';

class FirestoreRepository {
  FirestoreRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _learningSets(String uid) {
    return _userDoc(uid).collection('learning_sets');
  }

  CollectionReference<Map<String, dynamic>> _flashcards(String uid, String setId) {
    return _learningSets(uid).doc(setId).collection('flashcards');
  }

  DocumentReference<Map<String, dynamic>> _progressDoc(String uid, String setId) {
    return _learningSets(uid).doc(setId).collection('meta').doc('progress');
  }

  Future<void> createUserProfile(User user) async {
    final userRef = _userDoc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (snapshot.exists) {
        return;
      }

      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        createdAt: DateTime.now(),
        isPremium: false,
        setsCount: 0,
      );

      transaction.set(userRef, profile.toMap());
    });
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    return UserProfile.fromFirestore(snapshot);
  }

  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromFirestore(snapshot);
    });
  }

  Future<void> createLearningSet(String uid, String title, String rawText) async {
    final userProfile = await getUserProfile(uid);
    if (userProfile != null && !userProfile.isPremium && userProfile.setsCount >= 3) {
      throw Exception('free_limit_reached');
    }

    final setRef = _learningSets(uid).doc();
    final progressRef = _progressDoc(uid, setRef.id);
    final userRef = _userDoc(uid);

    // Client-side flashcard generation
    final sentences = rawText
        .split('.')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final flashcardData = <Map<String, dynamic>>[];
    for (var i = 0; i < sentences.length; i += 2) {
      final question = sentences[i];
      final answer = i + 1 < sentences.length ? sentences[i + 1] : 'See notes';
      flashcardData.add({
        'question': question,
        'answer': answer,
        'difficulty': 'unreviewed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final now = DateTime.now();
    final set = LearningSet(
      id: setRef.id,
      userId: uid,
      title: title,
      rawText: rawText,
      status: 'ready', // Set to ready immediately
      createdAt: now,
      cardCount: flashcardData.length,
    );

    final progress = Progress(
      setId: setRef.id,
      totalCards: flashcardData.length,
      reviewed: 0,
      easy: 0,
      medium: 0,
      hard: 0,
      lastStudiedAt: null,
    );

    final batch = _firestore.batch();
    
    // 1. Create the learning set
    batch.set(setRef, set.toMap());
    
    // 2. Create all flashcards
    for (var data in flashcardData) {
      final cardRef = _flashcards(uid, setRef.id).doc();
      batch.set(cardRef, data);
    }
    
    // 3. Create the progress tracking doc
    batch.set(progressRef, progress.toMap());
    
    // 4. Update the user's set count
    batch.set(userRef, {'setsCount': FieldValue.increment(1)}, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<List<LearningSet>> getLearningSets(String uid) {
    return _learningSets(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(LearningSet.fromFirestore).toList());
  }

  Stream<List<Flashcard>> getFlashcards(String uid, String setId) {
    return _flashcards(uid, setId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Flashcard.fromFirestore).toList());
  }

  Future<void> updateFlashcardDifficulty(
    String uid,
    String setId,
    String cardId,
    Difficulty difficulty,
  ) async {
    final cardRef = _flashcards(uid, setId).doc(cardId);
    final progressRef = _progressDoc(uid, setId);
    final now = DateTime.now();

    final batch = _firestore.batch();
    batch.update(cardRef, {
      'difficulty': difficulty.name,
      'lastReviewedAt': Timestamp.fromDate(now),
    });
    batch.set(progressRef, {
      'reviewed': FieldValue.increment(1),
      difficulty.name: FieldValue.increment(1),
      'lastStudiedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<Progress> getProgress(String uid, String setId) async {
    final snapshot = await _progressDoc(uid, setId).get();
    if (!snapshot.exists) {
      return Progress(
        setId: setId,
        totalCards: 0,
        reviewed: 0,
        easy: 0,
        medium: 0,
        hard: 0,
        lastStudiedAt: null,
      );
    }

    return Progress.fromFirestore(snapshot);
  }

  Future<void> updateUserPremiumStatus(String uid, bool isPremium) async {
    await _userDoc(uid).update({'isPremium': isPremium});
  }
}
