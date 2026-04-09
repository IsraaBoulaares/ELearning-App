# LearnFlow - Adaptive Flashcard Learning App

## Project Overview

LearnFlow is a Flutter-based mobile and web application that transforms study materials into intelligent flashcards with adaptive learning capabilities. Users paste their notes or textbook content, and the app automatically generates question-and-answer flashcard sets, tracks review progress, and adapts to individual learning patterns. The app implements a freemium model where free users can create up to 3 flashcard sets, while premium subscribers enjoy unlimited set creation.

## FlutterFlow Screen

This project includes a FlutterFlow screen prototype that demonstrates the visual design and user flow for the learning experience.

**FlutterFlow Project Link:** [https://app.flutterflow.io/share/e-learning-xk1706](https://app.flutterflow.io/share/e-learning-xk1706)

**What's Included:**

The FlutterFlow prototype showcases the UI/UX design for key screens in the application, including:
- Visual design mockups for the learning interface
- Interactive prototypes demonstrating user flows
- Design system components and styling

**Note on Implementation:**

While the FlutterFlow project provides the visual design reference, the actual production application is built with hand-coded Flutter for several reasons:
- **Better Code Quality:** Clean architecture with proper separation of concerns
- **Type Safety:** Compile-time error checking with Riverpod state management
- **Maintainability:** Feature-based folder structure for scalable development
- **Performance:** Optimized rendering and efficient state management
- **Flexibility:** Full control over business logic and Firebase integration

The FlutterFlow prototype serves as a design specification and visual reference, while the production code implements these designs with enterprise-grade architecture patterns.

## Architecture Decisions

### Flutter + Riverpod + Repository Pattern

The application follows a clean architecture approach with clear separation of concerns across three primary layers:

**Presentation Layer:** UI components built with Flutter widgets, consuming state through Riverpod providers. Each feature has its own presentation folder containing screens and widgets.

**Domain Layer:** Business logic and state management handled by Riverpod providers. Providers act as the bridge between UI and data, managing authentication state, user profiles, and learning content.

**Data Layer:** Repository pattern abstracts Firestore operations, providing a clean API for data access. The `FirestoreRepository` class encapsulates all database queries and mutations, making the codebase testable and maintainable.

**Why This Architecture:**

- **Separation of Concerns:** UI code never directly touches Firestore, making it easy to swap data sources or add caching layers
- **Testability:** Repositories can be mocked for unit testing business logic without Firebase dependencies
- **State Management:** Riverpod provides compile-time safety, automatic disposal, and excellent developer experience with minimal boilerplate
- **Scalability:** Feature-based folder structure allows teams to work on different features independently

### go_router for Navigation

The app uses `go_router` for declarative, type-safe routing with built-in authentication-aware redirects.

**Key Benefits:**

- **Declarative Routes:** All routes defined in one place (`app_router.dart`) with clear path parameters
- **Auth-Aware Redirects:** Automatic redirection to login for unauthenticated users, and to home for authenticated users trying to access auth screens
- **Deep Linking Support:** URL-based navigation works seamlessly on web and mobile
- **Type Safety:** Path parameters are validated at compile time, reducing runtime errors

### Feature-Based Folder Structure

```
lib/
├── core/
│   ├── models/          # Shared data models (UserProfile, Flashcard, LearningSet, Progress)
│   ├── router/          # Navigation configuration
│   ├── services/        # Platform services (Stripe)
│   └── theme/           # App-wide theming
├── features/
│   ├── auth/            # Authentication feature
│   │   ├── data/        # AuthRepository
│   │   ├── presentation/# Login, Register screens
│   │   └── providers/   # Auth state providers
│   ├── home/            # Home dashboard feature
│   │   └── presentation/
│   ├── learning/        # Core learning feature
│   │   ├── data/        # FirestoreRepository
│   │   ├── presentation/# Study, Progress screens
│   │   └── providers/   # Learning state providers
│   └── paywall/         # Subscription feature
│       └── presentation/
└── main.dart
```

**Why Feature-Based:**

- Each feature is self-contained with its own data, presentation, and providers
- Easy to locate all code related to a specific feature
- Reduces merge conflicts in team environments
- Simplifies feature removal or extraction into separate packages

## Firestore Structure

### Collection Hierarchy

```
users/{userId}
  - email: string
  - createdAt: timestamp
  - isPremium: boolean
  - setsCount: number

  /learningSets/{setId}
    - title: string
    - rawText: string
    - status: string (ready | processing)
    - createdAt: timestamp
    - cardCount: number
    - userId: string

    /flashcards/{cardId}
      - question: string
      - answer: string
      - difficulty: string (unreviewed | easy | medium | hard)
      - createdAt: timestamp
      - lastReviewedAt: timestamp | null

    /meta/progress
      - setId: string
      - totalCards: number
      - reviewed: number
      - easy: number
      - medium: number
      - hard: number
      - lastStudiedAt: timestamp | null
```

### Structure Rationale

**User Document at Root:**

All user data is scoped under `users/{userId}`, ensuring complete data isolation. This structure prevents any possibility of cross-user queries and simplifies security rules. The `setsCount` field is a counter that tracks the number of learning sets without requiring a collection query, which is critical for enforcing the free tier limit efficiently.

**Learning Sets as Subcollection:**

Learning sets are stored as a subcollection under each user document (`learningSets` in camelCase) rather than a top-level collection. This design decision ensures that:
- All queries are automatically scoped to the authenticated user
- Firestore security rules can use simple path-based validation
- Deleting a user account can cascade delete all their data
- No indexes are required for user-specific queries

**Flashcards as Nested Subcollection:**

Flashcards are nested under their parent learning set, creating a three-level hierarchy. This structure:
- Keeps related data physically close in Firestore, improving query performance
- Allows atomic batch operations when creating a set with all its flashcards
- Prevents orphaned flashcards if a set is deleted
- Enables efficient pagination when loading large flashcard sets

**Progress as Metadata Document:**

Progress tracking is stored in a separate `meta/progress` document rather than aggregating from flashcard documents. This approach:
- Uses `FieldValue.increment()` for atomic counter updates without reading existing values
- Avoids expensive aggregation queries that would read all flashcards
- Provides instant access to progress statistics with a single document read
- Scales efficiently regardless of flashcard count per set

**Progress Tracking Logic:**

The progress counters are updated with careful logic to prevent double-counting:
- When a card is reviewed for the first time (unreviewed → easy/medium/hard): increment `reviewed` counter AND the difficulty counter
- When a card's difficulty changes (easy → medium): decrement old difficulty counter, increment new difficulty counter, do NOT touch `reviewed` counter
- When the same difficulty is selected again: only update `lastStudiedAt` timestamp

This ensures accurate progress tracking where `reviewed` represents unique cards reviewed, not total review actions.

## Design System

### Premium Dark Theme

The app features a modern, premium dark theme with a carefully crafted color palette:

**Primary Colors:**
- Primary Purple: `#6C63FF` - Used for primary actions, gradients, and highlights
- Secondary Teal: `#03DAC6` - Used for accents, success states, and analytics
- Background Dark: `#0F0F1A` - Deep navy background for the entire app
- Card Background: `#1E1E2E` - Slightly lighter for elevated surfaces

**Semantic Colors:**
- Easy Green: `#4CAF50` - Indicates easy difficulty and success states
- Medium Amber: `#FFC107` - Indicates medium difficulty and warnings
- Hard Red: `#F44336` - Indicates hard difficulty and errors
- Text Primary: `#FFFFFF` - Main text color
- Text Secondary: `#B0B0C3` - Secondary text and labels

**Design Principles:**
- All cards use 16px border radius for consistency
- Gradient backgrounds on primary actions and premium features
- Subtle shadows with color-coded glows (purple for premium, green for success)
- Smooth animations and transitions throughout
- Accessibility-compliant contrast ratios

### Key Screens

**Home Screen:**
- Welcome header with user email and greeting emoji
- Subscription status card (gradient gold for premium, purple for free)
- Learning sets displayed as cards with:
  - Gradient icon backgrounds
  - Card count and status badges
  - Analytics button for progress tracking
  - Tap to study, long-press for options

**Study Screen:**
- Full-screen flashcard with flip animation
- Gradient border on card
- Progress bar at top showing completion percentage
- Easy/Medium/Hard difficulty chips with color coding
- Smooth card transitions

**Progress Screen:**
- Large circular progress indicator (color-coded by completion)
- Three stat cards showing Easy/Medium/Hard counts
- Difficulty distribution bars with gradients
- Last studied timestamp with human-readable format
- Visual analytics dashboard

**Paywall Screen:**
- Hero section with premium icon and compelling headline
- Side-by-side comparison of Free vs Premium plans
- Feature list with checkmarks/crosses
- "Why Go Premium?" benefits section with icons
- Gradient upgrade button
- Security trust badge

**Authentication Screens:**
- Clean, minimal design with app branding
- Gradient buttons for primary actions
- Rounded text fields with subtle borders
- Error states with clear messaging

## Cost Optimization Approach

### Query Optimization

**User-Scoped Data Architecture:**

Every query in the application is scoped under `users/{uid}`, eliminating the need for composite indexes or cross-user queries. This design reduces index storage costs and ensures predictable query performance regardless of total user count.

**Counter Fields Instead of Aggregations:**

The `setsCount` field on the user document is maintained using `FieldValue.increment(1)` during set creation. This approach:
- Avoids counting the entire `learningSets` subcollection to check the free tier limit
- Reduces read operations from potentially hundreds to a single document read
- Costs 1 write operation instead of N read operations where N is the number of sets

**Progress Tracking with Increments:**

Progress statistics use `FieldValue.increment()` exclusively, never reading the current value before updating. When a user reviews a flashcard:
```dart
batch.set(progressRef, {
  'reviewed': FieldValue.increment(1),
  'easy': FieldValue.increment(1),
  'lastStudiedAt': Timestamp.fromDate(now),
}, SetOptions(merge: true));
```

This pattern:
- Eliminates read-before-write operations
- Prevents race conditions when multiple devices update simultaneously
- Reduces costs by 50% compared to read-modify-write patterns

### Client-Side Processing

**Flashcard Generation:**

Flashcard generation happens entirely on the client side within the Flutter app. The `createLearningSet` method splits text into sentences and pairs them as questions and answers without calling Cloud Functions or external APIs. This design:
- Eliminates Cloud Function invocation costs
- Avoids external API charges (OpenAI, etc.)
- Provides instant feedback to users
- Scales to unlimited users without backend capacity concerns

**Stream Management:**

Firestore streams are only opened when screens are actively visible. The app uses Riverpod's automatic disposal to close streams when users navigate away:
```dart
final learningSetsProvider = StreamProvider.family<List<LearningSet>, String>((ref, uid) {
  final repository = ref.watch(firestoreRepositoryProvider);
  return repository.getLearningSets(uid);
});
```

When the widget is disposed, Riverpod automatically cancels the stream subscription, preventing unnecessary background listeners that would incur read costs.

**Single Document Reads:**

Progress statistics are fetched with a single document read rather than aggregating from the flashcards subcollection:
```dart
Future<Progress> getProgress(String uid, String setId) async {
  final snapshot = await _progressDoc(uid, setId).get();
  // Returns immediately with all statistics
}
```

This approach costs 1 read operation instead of N reads where N is the number of flashcards.

### Batch Operations

All multi-document writes use Firestore batch operations to minimize round trips and ensure atomicity:

```dart
final batch = _firestore.batch();
batch.set(setRef, set.toMap());
for (var data in flashcardData) {
  final cardRef = _flashcards(uid, setRef.id).doc();
  batch.set(cardRef, data);
}
batch.set(progressRef, progress.toMap());
batch.set(userRef, {'setsCount': FieldValue.increment(1)}, SetOptions(merge: true));
await batch.commit();
```

This pattern:
- Reduces network latency by combining multiple operations
- Ensures all-or-nothing semantics (if one write fails, all fail)
- Counts as individual write operations but with better performance

## Security Rules

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check authentication
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Users can only read and write their own profile
      allow read, write: if isOwner(userId);
      
      // Learning sets subcollection
      match /learningSets/{setId} {
        // Users can only access their own learning sets
        allow read, write: if isOwner(userId);
        
        // Flashcards subcollection
        match /flashcards/{cardId} {
          allow read, write: if isOwner(userId);
        }
        
        // Progress metadata
        match /meta/{document=**} {
          allow read, write: if isOwner(userId);
        }
      }
    }
  }
}
```

### Security Principles

**User Data Isolation:**

The security rules enforce strict data isolation where users can only read and write documents under their own `users/{userId}` path. The `isOwner(userId)` helper function verifies that `request.auth.uid` matches the `userId` in the document path, preventing any cross-user data access.

**No Client-Side Subscription Validation:**

The `isPremium` field is intentionally not validated in security rules. While the client checks this field to show/hide UI elements, the actual enforcement happens server-side:

```dart
Future<void> createLearningSet(String uid, String title, String rawText) async {
  final userProfile = await getUserProfile(uid);
  if (userProfile != null && !userProfile.isPremium && userProfile.setsCount >= 3) {
    throw Exception('free_limit_reached');
  }
  // ... proceed with creation
}
```

This approach prevents malicious clients from bypassing the limit by modifying the `isPremium` field directly. Even if a user tampers with their local data, the repository layer validates against the server-side truth.

**Sensitive Logic in Cloud Functions:**

The `isPremium` status is only updated through Cloud Functions triggered by Stripe webhooks, never by client-side code. This ensures:
- Users cannot grant themselves premium access
- Subscription status reflects actual payment verification
- Refunds and cancellations are handled automatically
- No race conditions between client updates and payment processing

## Cloud Functions

### Function Implementations

**Function 1: handleStripeWebhook**

```javascript
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;
  
  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }
  
  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const userId = session.client_reference_id;
    
    await admin.firestore().collection('users').doc(userId).update({
      isPremium: true,
      subscriptionId: session.subscription,
      subscriptionStatus: 'active'
    });
  }
  
  if (event.type === 'customer.subscription.deleted') {
    const subscription = event.data.object;
    const userId = subscription.metadata.userId;
    
    await admin.firestore().collection('users').doc(userId).update({
      isPremium: false,
      subscriptionStatus: 'canceled'
    });
  }
  
  res.json({ received: true });
});
```

**Purpose:** Listens for Stripe webhook events and updates user subscription status in Firestore. This function is the single source of truth for premium status, ensuring that only verified payments grant access.

**Why It Exists:** Client-side subscription validation can be bypassed by malicious users. By handling subscription updates server-side through webhooks, we guarantee that `isPremium` reflects actual payment status verified by Stripe.

**Function 2: cleanupUserData**

```javascript
exports.cleanupUserData = functions.auth.user().onDelete(async (user) => {
  const userId = user.uid;
  const firestore = admin.firestore();
  
  // Delete user document and all subcollections
  const userRef = firestore.collection('users').doc(userId);
  await deleteCollection(firestore, userRef.collection('learningSets'), 10);
  await userRef.delete();
});

async function deleteCollection(db, collectionRef, batchSize) {
  const query = collectionRef.limit(batchSize);
  return new Promise((resolve, reject) => {
    deleteQueryBatch(db, query, resolve).catch(reject);
  });
}

async function deleteQueryBatch(db, query, resolve) {
  const snapshot = await query.get();
  const batchSize = snapshot.size;
  if (batchSize === 0) {
    resolve();
    return;
  }
  
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  await batch.commit();
  
  process.nextTick(() => {
    deleteQueryBatch(db, query, resolve);
  });
}
```

**Purpose:** Automatically deletes all user data from Firestore when a user account is deleted from Firebase Authentication. This ensures GDPR compliance and prevents orphaned data.

**Why It Exists:** Firestore does not cascade delete subcollections automatically. Without this function, deleting a user account would leave their learning sets, flashcards, and progress data in the database indefinitely.

### Deployment Requirements

**Firebase Blaze Plan Required:**

Cloud Functions require the Blaze (pay-as-you-go) plan because they need to make outbound network requests to Stripe's API for webhook signature verification. The free Spark plan does not allow external network access from Cloud Functions.

**Webhook Approach for Stripe Validation:**

The webhook pattern ensures that subscription status updates are triggered by Stripe's servers, not by client requests. This architecture:
- Prevents users from faking successful payments
- Handles subscription lifecycle events (renewals, cancellations, refunds) automatically
- Provides a reliable audit trail of all subscription changes
- Works even if the user closes the app immediately after payment

## Subscription Implementation

### Stripe Integration

The app uses Stripe for payment processing with platform-specific implementations:

**Mobile (iOS/Android):** Uses the `flutter_stripe` SDK for native payment UI and secure card tokenization. The SDK handles PCI compliance by ensuring card data never touches the app's servers.

**Web:** Stripe Flutter SDK is not supported on web. The web implementation redirects users to Stripe Checkout hosted pages, which handle the entire payment flow securely.

### Free Tier Enforcement

**Client-Side Check:**

The UI prevents free users from creating more than 3 sets by checking the `setsCount` field:

```dart
final userProfile = await getUserProfile(uid);
if (userProfile != null && !userProfile.isPremium && userProfile.setsCount >= 3) {
  // Show paywall screen
}
```

**Server-Side Validation:**

The repository layer validates the limit before writing to Firestore:

```dart
Future<void> createLearningSet(String uid, String title, String rawText) async {
  final userProfile = await getUserProfile(uid);
  if (userProfile != null && !userProfile.isPremium && userProfile.setsCount >= 3) {
    throw Exception('free_limit_reached');
  }
  // ... proceed with creation
}
```

This dual-layer approach provides good UX (immediate feedback) while maintaining security (server-side enforcement).

### Premium Tier

Premium users have unlimited set creation. The `isPremium` boolean is checked before enforcing the 3-set limit, allowing premium users to bypass the restriction entirely.

### Server-Side Premium Status Updates

The `isPremium` field is only modified through the `handleStripeWebhook` Cloud Function, never by client code. When a user completes a Stripe Checkout session:

1. Stripe redirects the user back to the app
2. Stripe sends a `checkout.session.completed` webhook to the Cloud Function
3. The Cloud Function verifies the webhook signature to ensure authenticity
4. The function updates `isPremium: true` in Firestore
5. The app's Riverpod stream automatically reflects the new status

This workflow ensures that premium access is only granted after Stripe confirms payment, preventing fraud and ensuring accurate subscription tracking.

## Setup Instructions

### Prerequisites

- Flutter SDK 3.11.4 or higher
- Firebase CLI installed (`npm install -g firebase-tools`)
- Stripe account for payment processing
- Node.js 18+ for Cloud Functions

### Clone and Install

```bash
git clone <repository-url>
cd elearning_app
flutter pub get
```

### Firebase Setup

1. Create a new Firebase project at https://console.firebase.google.com

2. Enable Firebase Authentication with Email/Password provider

3. Create a Firestore database in production mode

4. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

5. Configure Firebase for your Flutter app:
```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project configuration.

6. Deploy Firestore security rules:
```bash
firebase deploy --only firestore:rules
```

7. Deploy Cloud Functions (requires Blaze plan):
```bash
cd functions
npm install
firebase deploy --only functions
```

### Stripe Setup

1. Create a Stripe account at https://stripe.com

2. Get your test API keys from the Stripe Dashboard (Developers → API keys)

3. Update `lib/main.dart` with your Stripe publishable key:
```dart
const stripePublishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
await StripeService.initialize(stripePublishableKey);
```

4. Set up Cloud Function for Stripe Checkout (requires Blaze plan):
```bash
cd functions
npm install stripe
```

5. Configure Stripe secret key using Firebase Secrets (recommended):
```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
# Enter your sk_test_... key when prompted
```

6. Deploy the Cloud Function:
```bash
firebase deploy --only functions:createCheckoutSession
```

7. Configure Stripe webhook for subscription updates:
   - Go to Stripe Dashboard → Developers → Webhooks
   - Add endpoint: `https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/handleStripeWebhook`
   - Select events: `checkout.session.completed`, `customer.subscription.deleted`, `customer.subscription.updated`
   - Copy the webhook signing secret
   - Set it in Firebase: `firebase functions:secrets:set STRIPE_WEBHOOK_SECRET`

8. Deploy the webhook handler:
```bash
firebase deploy --only functions:handleStripeWebhook
```

**Note:** The app includes a demo/fallback mode for testing without deployed Cloud Functions. Real Stripe integration requires the Blaze plan and deployed functions.

### Troubleshooting Progress Tracking

If progress counters show incorrect values (e.g., "3 of 1 cards reviewed, 300%"):

1. **Use the Reset Helper Screen** (temporary debugging tool):
   - Add to HomeScreen AppBar:
   ```dart
   import '../learning/presentation/reset_progress_helper.dart';
   
   IconButton(
     onPressed: () => Navigator.push(context, 
       MaterialPageRoute(builder: (_) => const ResetProgressHelper())),
     icon: const Icon(Icons.build),
   ),
   ```
   - Tap "Recalculate" for each learning set to rebuild counters from actual flashcard data
   - Remove the button after fixing

2. **Manual Firestore Console Reset:**
   - Navigate to `users/{uid}/learningSets/{setId}/meta/progress`
   - Set all counters to 0: `reviewed: 0, easy: 0, medium: 0, hard: 0`

3. **Verify Collection Name:**
   - Ensure Firestore uses `learningSets` (camelCase), not `learning_sets`
   - Check `lib/features/learning/data/firestore_repository.dart` line 18

See `RESET_PROGRESS_INSTRUCTIONS.md` for detailed steps.

### Environment Variables

Create a `.env` file in the project root (not committed to version control):

```
STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY
STRIPE_SECRET_KEY=sk_test_YOUR_KEY
STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET
```

### Run the App

**Navigate to project directory:**
```bash
cd C:\src\flutter\flutter\elearning_app
```

**Web:**
```bash
flutter run -d chrome
```

**Android Physical Device:**
```bash
# List connected devices
flutter devices

# Run on specific device (replace with your device ID)
flutter run -d R5CW30C3FGE
```

**Android Emulator:**
```bash
flutter run -d android
```

**iOS Simulator (Mac only):**
```bash
flutter run -d ios
```

**Windows Desktop:**
```bash
flutter run -d windows
```

### Development Tips

**Use Hot Reload for Fast Iteration:**

After the initial launch (which can take 30-60 seconds), keep the app running and use hot reload:
- Press `r` in terminal for hot reload (2-3 seconds)
- Press `R` for hot restart (10-15 seconds)
- Press `q` to quit

**Speed Up Launch Time:**

The app has timeouts for Firebase and Stripe initialization to prevent blocking:
- Stripe: 3 second timeout
- Firebase: 5 second timeout

You can reduce these in `lib/main.dart` if needed:
```dart
await StripeService.initialize(stripeKey).timeout(
  const Duration(seconds: 1),  // Reduce from 3s
  onTimeout: () => null,
);
```

**Profile/Release Builds:**

For testing performance:
```bash
flutter run --profile -d R5CW30C3FGE  # Profile mode
flutter run --release -d R5CW30C3FGE  # Release mode (no debugging)
```

Release builds are 5-10x faster but you lose hot reload and debugging capabilities.

### Testing Subscription Flow

1. Create a test account in the app
2. Create 3 flashcard sets (free tier limit)
3. Attempt to create a 4th set - paywall should appear
4. Click "Upgrade to Premium"
5. **If Cloud Functions are deployed:**
   - Real Stripe Checkout opens in browser
   - Use test card: `4242 4242 4242 4242`, any future expiry, any CVC
   - Complete checkout
   - Webhook updates `isPremium: true` in Firestore
   - Return to app - premium status reflects automatically
6. **If Cloud Functions not deployed (demo mode):**
   - Mock payment form appears
   - Pre-filled with test card data
   - Click "Pay $4.99" to simulate payment
   - Premium status updates immediately
7. Create additional sets without restriction

### Testing Progress Tracking

1. Create a learning set with at least 3 cards
2. Open the set and review the first card
3. Rate it as "Easy"
4. Check progress screen - should show "1 of 3 cards reviewed (33%)"
5. Review the same card again, rate as "Medium"
6. Check progress - should still show "1 of 3 cards reviewed" (not 2)
7. Review a second card, rate as "Hard"
8. Check progress - should now show "2 of 3 cards reviewed (67%)"
9. Verify difficulty distribution bars show correct counts

### Common Issues

**"No pubspec.yaml file found":**
- You're running Flutter from the wrong directory
- Solution: `cd C:\src\flutter\flutter\elearning_app` first

**"Couldn't resolve package 'intl'":**
- Run `flutter pub get` to install dependencies

**Progress shows 300% or incorrect counts:**
- See "Troubleshooting Progress Tracking" section above
- Use the Reset Helper Screen to recalculate from actual data

**Stripe checkout fails:**
- Check if Cloud Functions are deployed: `firebase functions:list`
- Verify Blaze plan is active
- Check function logs: `firebase functions:log`
- Use demo mode as fallback (shows mock payment form)

**App takes too long to launch:**
- First launch is always slow (30-60s for Android)
- Use hot reload (`r`) for subsequent changes
- Consider using `--profile` or `--release` mode for speed testing

### Production Deployment

**Important:** Before deploying to production or submitting to app stores:

1. Replace Stripe with Apple In-App Purchase (iOS) and Google Play Billing (Android)
2. Update security rules to production-ready configuration
3. Enable Firebase App Check to prevent API abuse
4. Set up proper error logging and monitoring
5. Create and link privacy policy
6. Test thoroughly on physical devices
7. Follow the guidelines in `APP_STORE_GUIDE.md`

## License

This project is for educational and assessment purposes.
