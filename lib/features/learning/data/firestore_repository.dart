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
    return _userDoc(uid).collection('learningSets');
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
    
    // 1. Create the learning set document
    // Path: users/{uid}/learningSets/{setId}
    batch.set(setRef, set.toMap());
    
    // 2. Create all flashcard documents
    // Path: users/{uid}/learningSets/{setId}/flashcards/{cardId}
    for (var data in flashcardData) {
      final cardRef = _flashcards(uid, setRef.id).doc();
      batch.set(cardRef, data);
    }
    
    // 3. Create the progress tracking document
    // Path: users/{uid}/learningSets/{setId}/meta/progress
    batch.set(progressRef, progress.toMap());
    
    // 4. Update the user's set count
    // Path: users/{uid}
    batch.set(userRef, {'setsCount': FieldValue.increment(1)}, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<List<LearningSet>> getLearningSets(String uid) {
    // Path: users/{uid}/learningSets
    return _learningSets(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(LearningSet.fromFirestore).toList());
  }

  Stream<List<Flashcard>> getFlashcards(String uid, String setId) {
    // Path: users/{uid}/learningSets/{setId}/flashcards
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
    final newDifficulty = difficulty.name;
    
    // 1. Read the current flashcard to get previous difficulty
    // Path: users/{uid}/learningSets/{setId}/flashcards/{cardId}
    final cardDoc = await _flashcards(uid, setId).doc(cardId).get();
    
    if (!cardDoc.exists) {
      throw Exception('Card not found');
    }
    
    final previousDifficulty = cardDoc.data()?['difficulty'] as String? ?? 'unreviewed';
    
    // 2. If difficulty hasn't changed, do nothing
    if (previousDifficulty == newDifficulty) return;
    
    // 3. Build the update map
    final Map<String, dynamic> progressUpdate = {};
    
    // 4. If was unreviewed, increment reviewed counter
    if (previousDifficulty == 'unreviewed') {
      progressUpdate['reviewed'] = FieldValue.increment(1);
    }
    
    // 5. If was previously rated (not unreviewed), decrement old counter
    if (previousDifficulty != 'unreviewed') {
      progressUpdate[previousDifficulty] = FieldValue.increment(-1);
    }
    
    // 6. Always increment new difficulty counter
    progressUpdate[newDifficulty] = FieldValue.increment(1);
    progressUpdate['lastStudiedAt'] = Timestamp.now();
    
    // 7. Update flashcard difficulty
    // Path: users/{uid}/learningSets/{setId}/flashcards/{cardId}
    await _flashcards(uid, setId).doc(cardId).update({
      'difficulty': newDifficulty,
      'lastReviewedAt': Timestamp.now(),
    });
    
    // 8. Update progress counters
    // Path: users/{uid}/learningSets/{setId}/meta/progress
    await _progressDoc(uid, setId).set(progressUpdate, SetOptions(merge: true));
  }

  Future<Progress> getProgress(String uid, String setId) async {
    // Path: users/{uid}/learningSets/{setId}/meta/progress
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

  /// Helper method to reset progress counters for a learning set
  /// Use this to fix corrupted progress data
  /// Path: users/{uid}/learningSets/{setId}/meta/progress
  Future<void> resetProgressCounters(String uid, String setId) async {
    await _progressDoc(uid, setId).set({
      'reviewed': 0,
      'easy': 0,
      'medium': 0,
      'hard': 0,
      'lastStudiedAt': null,
    }, SetOptions(merge: true));
  }

  /// Helper method to recalculate progress from actual flashcard data
  /// Use this to rebuild progress counters from scratch
  /// Reads from: users/{uid}/learningSets/{setId}/flashcards
  /// Writes to: users/{uid}/learningSets/{setId}/meta/progress
  Future<void> recalculateProgress(String uid, String setId) async {
    final flashcardsSnapshot = await _flashcards(uid, setId).get();
    
    int reviewed = 0;
    int easy = 0;
    int medium = 0;
    int hard = 0;
    DateTime? lastStudiedAt;
    
    for (final doc in flashcardsSnapshot.docs) {
      final data = doc.data();
      final difficulty = data['difficulty'] as String? ?? 'unreviewed';
      final lastReviewedAt = data['lastReviewedAt'] as Timestamp?;
      
      if (difficulty != 'unreviewed') {
        reviewed++;
        
        switch (difficulty) {
          case 'easy':
            easy++;
            break;
          case 'medium':
            medium++;
            break;
          case 'hard':
            hard++;
            break;
        }
        
        if (lastReviewedAt != null) {
          final reviewDate = lastReviewedAt.toDate();
          if (lastStudiedAt == null || reviewDate.isAfter(lastStudiedAt)) {
            lastStudiedAt = reviewDate;
          }
        }
      }
    }
    
    await _progressDoc(uid, setId).set({
      'totalCards': flashcardsSnapshot.docs.length,
      'reviewed': reviewed,
      'easy': easy,
      'medium': medium,
      'hard': hard,
      'lastStudiedAt': lastStudiedAt != null ? Timestamp.fromDate(lastStudiedAt) : null,
    }, SetOptions(merge: true));
  }
}
