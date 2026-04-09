# Reset Progress Counters - Instructions

## The Problem
Progress tracking was showing incorrect values (e.g., "3 of 1 cards reviewed, 300%") because the `reviewed` counter was being incremented multiple times for the same card.

## The Fix
The `updateFlashcardDifficulty()` method has been rewritten with correct logic:
- Only increments `reviewed` counter when a card goes from `unreviewed` to any difficulty
- When changing difficulty (easy → medium), it decrements the old counter and increments the new one
- Does NOT increment `reviewed` when changing between difficulties

## How to Reset Your Data

### Option 1: Use the Helper Screen (Recommended)

1. **Add a temporary button to your HomeScreen** to access the reset helper:

```dart
// In home_screen.dart, add this to the AppBar actions:
IconButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ResetProgressHelper(),
      ),
    );
  },
  icon: const Icon(Icons.build),
  tooltip: 'Reset Progress',
),
```

2. **Import the helper**:
```dart
import '../learning/presentation/reset_progress_helper.dart';
```

3. **Run the app** and tap the build icon in the AppBar

4. **For each learning set**, you have two options:
   - **Reset to 0**: Sets all counters to zero (use if you want to start fresh)
   - **Recalculate**: Reads all flashcards and rebuilds counters from actual data (use if you want to preserve existing reviews)

5. **Remove the button** after fixing your data

### Option 2: Manual Firestore Console Reset

1. Open Firebase Console: https://console.firebase.google.com
2. Go to Firestore Database
3. Navigate to: `users/{uid}/learning_sets/{setId}/meta/progress`
4. For each progress document, set:
   ```
   reviewed: 0
   easy: 0
   medium: 0
   hard: 0
   lastStudiedAt: null
   ```

### Option 3: Programmatic Reset (for all sets at once)

Add this temporary method to your app:

```dart
Future<void> resetAllProgress() async {
  final uid = 'YOUR_USER_ID';
  final repo = ref.read(firestoreRepositoryProvider);
  final sets = await repo.getLearningSets(uid).first;
  
  for (final set in sets) {
    await repo.resetProgressCounters(uid, set.id);
    // Or use recalculateProgress to preserve existing reviews:
    // await repo.recalculateProgress(uid, set.id);
  }
}
```

## Testing the Fix

1. Reset your progress counters using one of the methods above
2. Open a learning set
3. Review a card and rate it (Easy/Medium/Hard)
4. Check the progress screen - should show "1 of X cards reviewed"
5. Review the same card again with a different difficulty
6. Progress should still show "1 of X cards reviewed" (not increment)
7. Review a different card
8. Progress should now show "2 of X cards reviewed"

## Files Changed

- `lib/features/learning/data/firestore_repository.dart` - Fixed updateFlashcardDifficulty logic
- `lib/features/learning/presentation/reset_progress_helper.dart` - Helper screen to reset data
- Added `resetProgressCounters()` and `recalculateProgress()` helper methods

## Cleanup

After fixing your data, you can:
1. Remove the reset button from HomeScreen
2. Delete `lib/features/learning/presentation/reset_progress_helper.dart`
3. Delete this instruction file
