# App Store Submission Guide

## Apple App Store Subscription Rules

### In-App Purchase Requirements

Apple enforces strict rules for digital goods and services sold within iOS applications. All digital content, including subscriptions, premium features, and virtual items, must use Apple's In-App Purchase (IAP) system exclusively.

**Key Requirements:**

- Digital goods and subscriptions must use Apple In-App Purchase only
- Apple takes a 30% commission on all transactions (reduced to 15% for developers earning less than $1 million annually through the Small Business Program)
- External payment links are strictly prohibited within the app interface
- Free trials and subscription management must be implemented through Apple's subscription system
- Users must be able to view and cancel subscriptions directly from iOS Settings → Apple ID → Subscriptions

**Important Note for This Project:**

The current implementation uses Stripe for payment processing, which violates Apple's guidelines for digital subscriptions. Before submitting to the App Store, you must replace the Stripe integration with StoreKit 2 (Apple's In-App Purchase framework). The Stripe implementation can remain for the web version or for physical goods, but digital learning content subscriptions must use Apple IAP on iOS.

### Compliance Strategy

To make this app App Store compliant:

1. Implement StoreKit 2 for iOS subscription handling
2. Remove all Stripe payment UI from the iOS build
3. Configure subscription products in App Store Connect
4. Implement server-side receipt validation through Apple's servers
5. Update the `isPremium` status via Apple's server-to-server notifications

## Google Play Store Subscription Rules

### Google Play Billing Requirements

Google Play enforces similar rules to Apple, requiring all digital goods to use Google Play Billing.

**Key Requirements:**

- Google takes a 30% commission (reduced to 15% for the first $1 million in revenue annually)
- Google Play Billing is required for all digital goods and in-app subscriptions
- Alternative billing systems are now allowed in certain regions (EU, South Korea) following regulatory changes
- Users can manage and cancel subscriptions from Google Play Store → Account → Payments & subscriptions → Subscriptions
- Server-side validation through Google Play Developer API is required for security

**Compliance Strategy:**

Similar to iOS, replace Stripe with Google Play Billing for Android:

1. Implement the `in_app_purchase` Flutter package or `purchases_flutter` (RevenueCat)
2. Configure subscription products in Google Play Console
3. Implement server-side receipt verification
4. Handle Real-time Developer Notifications (RTDN) for subscription status updates

## Common Rejection Reasons

### Technical Issues

**Missing Privacy Policy URL**
- Both Apple and Google require a publicly accessible privacy policy
- Must be linked in App Store Connect / Google Play Console
- Must clearly explain data collection, usage, and third-party services (Firebase, Stripe)

**Broken Login or Authentication Flow**
- Reviewers will test account creation and login
- Ensure Firebase Authentication works reliably
- Provide test credentials if needed for review

**App Crashes on Launch**
- Test thoroughly on physical devices
- The current Stripe web compatibility issue would cause rejection
- Ensure all platform-specific code is properly conditionally compiled

**Placeholder Content or Lorem Ipsum Text**
- All UI text must be final and meaningful
- No "Coming Soon" features visible in the submitted version
- Ensure sample flashcard sets contain real educational content

### Policy Violations

**Misleading App Description**
- App functionality must match the description exactly
- Screenshots must represent actual app features
- Do not promise features that are not yet implemented

**External Payment Links for Digital Goods**
- The current Stripe implementation would be rejected on iOS
- No links to external websites for subscription purchases
- No mentions of pricing outside of IAP

**Missing Required Permissions Explanations**
- iOS requires purpose strings for all permissions in Info.plist
- Android requires clear explanations in the app listing
- This app needs explanations for internet access and notification permissions (if implemented)

**Incomplete Subscription Management**
- Users must be able to see their subscription status in the app
- Clear indication of free vs. premium features
- Restore purchases functionality must work correctly

## Basic App Listing

### App Identity

**App Name:** LearnFlow

**Subtitle:** Adaptive Flashcard Learning

**Category:** Education

**Keywords:** flashcards, learning, study, education, adaptive, memory, spaced repetition, exam prep, student tools, knowledge retention

### App Icon Description

**Background:** Deep blue gradient transitioning from rich navy at the top to lighter blue at the bottom, conveying trust and intelligence associated with learning.

**Icon:** White open book symbol positioned centrally, with clean lines and a minimalist design. A small lightning bolt emerges from the top-right corner of the book, suggesting fast, efficient learning and the adaptive intelligence of the platform.

**Style:** Clean and minimal aesthetic appropriate for the Education category. The icon remains recognizable at all sizes from 1024x1024 (App Store) down to 20x20 (notification icon). The high contrast between white icon and blue background ensures visibility on both light and dark device backgrounds.

### App Description

**Paragraph 1: What It Does**

LearnFlow transforms your study materials into intelligent flashcards that adapt to your learning pace. Simply paste your notes, lecture transcripts, or textbook excerpts, and the app instantly generates question-and-answer flashcard sets. The adaptive review system tracks your performance on each card, helping you focus on concepts that need more practice while reinforcing what you already know.

**Paragraph 2: Key Features**

Create unlimited flashcard sets from any text content with automatic question generation. Track your learning progress with detailed statistics showing how many cards you've mastered versus those requiring more review. The difficulty-based system categorizes each card as easy, medium, or hard based on your self-assessment, allowing you to prioritize challenging material. All your learning data syncs across devices through secure cloud storage, so you can study anywhere.

**Paragraph 3: Freemium Offer**

Start learning for free with up to 3 flashcard sets, perfect for trying the app or managing a few key subjects. When you're ready to expand your learning, upgrade to Premium for unlimited flashcard sets, ideal for students managing multiple courses or professionals pursuing continuous education. Premium unlocks the full potential of adaptive learning, letting you organize all your study materials in one place without restrictions.

### Screenshot Descriptions

**Screenshot 1: Login Screen**
- Clean authentication interface with email and password fields
- "Create Account" and "Sign In" buttons prominently displayed
- Minimalist design focusing on quick access to learning tools
- Firebase Authentication ensures secure account management

**Screenshot 2: Home Screen**
- Dashboard displaying all created flashcard sets as cards
- Each set shows title, card count, and creation date
- Floating action button for creating new sets
- Clear visual indication of free tier limit (3 sets) with upgrade prompt
- Quick access to study mode for each set

**Screenshot 3: Create Set Screen**
- Simple form with title input field
- Large text area for pasting study material
- Real-time preview of how many flashcards will be generated
- "Generate Flashcards" button to process content
- Instant feedback showing set creation progress

**Screenshot 4: Study Screen (Review Mode)**
- Full-screen flashcard display with question on front
- Tap to flip animation revealing the answer
- Three difficulty buttons at bottom: Easy (green), Medium (yellow), Hard (red)
- Progress indicator showing current card position in set
- Swipe gestures for natural card navigation

**Screenshot 5: Progress Screen**
- Circular progress chart showing overall completion percentage
- Breakdown of cards by difficulty level with color-coded bars
- Statistics: total cards, reviewed count, mastery percentage
- Last studied timestamp
- "Continue Studying" button to resume where you left off

## Pre-Submission Checklist

### Required Changes for App Store Compliance

- [ ] Replace Stripe with StoreKit 2 (iOS) and Google Play Billing (Android)
- [ ] Remove all external payment links and Stripe UI from mobile builds
- [ ] Configure subscription products in App Store Connect and Google Play Console
- [ ] Implement server-side receipt validation
- [ ] Add subscription management UI showing current plan and renewal date
- [ ] Implement "Restore Purchases" functionality
- [ ] Create privacy policy and host it publicly
- [ ] Add privacy policy URL to app store listings
- [ ] Test on physical iOS and Android devices
- [ ] Ensure no placeholder text or Lorem Ipsum remains
- [ ] Provide test account credentials for reviewers
- [ ] Add required permission explanations to Info.plist (iOS) and app listing (Android)
- [ ] Verify app does not crash on launch on all supported OS versions
- [ ] Test subscription flow end-to-end including cancellation

### Testing Recommendations

1. Test account creation and login with various email formats
2. Verify free tier limit enforcement (3 sets maximum)
3. Test flashcard generation with various text lengths and formats
4. Confirm progress tracking updates correctly after reviewing cards
5. Test subscription purchase flow (once IAP is implemented)
6. Verify subscription status syncs correctly across devices
7. Test "Restore Purchases" on a second device
8. Confirm users can cancel subscriptions through platform settings
9. Test offline functionality and data sync when connection returns
10. Verify all navigation flows work without dead ends

## Additional Resources

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Policy Center](https://play.google.com/about/developer-content-policy/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Google Play Billing Documentation](https://developer.android.com/google/play/billing)
- [Flutter In-App Purchase Plugin](https://pub.dev/packages/in_app_purchase)
