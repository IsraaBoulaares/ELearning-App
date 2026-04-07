import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/flashcard.dart';
import '../../../core/models/learning_set.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/user_profile.dart';
import '../data/firestore_repository.dart';

typedef FlashcardScope = ({String uid, String setId});

typedef ProgressScope = ({String uid, String setId});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreRepositoryProvider = Provider<FirestoreRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return FirestoreRepository(firestore);
});

final learningSetStreamProvider =
    StreamProvider.family<List<LearningSet>, String>((ref, uid) {
      final repository = ref.watch(firestoreRepositoryProvider);
      return repository.getLearningSets(uid);
    });

final flashcardStreamProvider =
    StreamProvider.family<List<Flashcard>, FlashcardScope>((ref, scope) {
      final repository = ref.watch(firestoreRepositoryProvider);
      return repository.getFlashcards(scope.uid, scope.setId);
    });

final progressProvider = FutureProvider.family<Progress, ProgressScope>((
  ref,
  scope,
) {
  final repository = ref.watch(firestoreRepositoryProvider);
  return repository.getProgress(scope.uid, scope.setId);
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  final repository = ref.watch(firestoreRepositoryProvider);
  return repository.getUserProfileStream(uid);
});
