# Stripe Integration Setup Guide

This guide explains how to set up the full Stripe integration to process real test payments.

## Prerequisites

1. Firebase project on the Blaze (pay-as-you-go) plan
2. Stripe account (free test mode)
3. Firebase CLI installed (`npm install -g firebase-tools`)

## Step 1: Get Stripe API Keys

1. Go to https://dashboard.stripe.com/test/apikeys
2. Copy your **Publishable key** (starts with `pk_test_`)
3. Copy your **Secret key** (starts with `sk_test_`)

## Step 2: Configure Cloud Functions

1. Navigate to the functions directory:
```bash
cd functions
```

2. Install dependencies:
```bash
npm install
```

3. Set the Stripe secret key as an environment variable:
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY_HERE"
```

## Step 3: Deploy Cloud Functions

Deploy the functions to Firebase:
```bash
firebase deploy --only functions
```

This will deploy:
- `createCheckoutSession` - Creates Stripe checkout sessions
- `handleStripeWebhook` - Processes Stripe webhook events
- `enforceSetLimit` - Enforces free tier limits
- `onFlashcardDifficultyUpdated` - Updates progress tracking

## Step 4: Configure Stripe Webhook

1. Get your Cloud Function URL after deployment (it will be displayed in the terminal)
   - Example: `https://us-central1-YOUR_PROJECT.cloudfunctions.net/handleStripeWebhook`

2. Go to https://dashboard.stripe.com/test/webhooks

3. Click "Add endpoint"

4. Enter your webhook URL

5. Select events to listen for:
   - `checkout.session.completed`
   - `customer.subscription.deleted`
   - `customer.subscription.updated`

6. Copy the **Signing secret** (starts with `whsec_`)

7. Set it as an environment variable:
```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"
```

8. Redeploy functions:
```bash
firebase deploy --only functions
```

## Step 5: Update Flutter App

The app is already configured to use the real Stripe integration. Just make sure you have the correct publishable key in `lib/main.dart`:

```dart
await StripeService.initialize('pk_test_YOUR_PUBLISHABLE_KEY_HERE');
```

## Step 6: Test the Integration

1. Run the Flutter app on Android or iOS (not web)
2. Navigate to the paywall screen
3. Click "Upgrade Now"
4. The app will open Stripe Checkout in your browser
5. Use test card: `4242 4242 4242 4242`
   - Any future expiry date
   - Any 3-digit CVC
6. Complete the payment
7. The webhook will automatically update your premium status in Firestore
8. Return to the app and see your premium features unlocked

## Test Cards

Stripe provides various test cards for different scenarios:

- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **Insufficient funds**: `4000 0000 0000 9995`
- **3D Secure**: `4000 0025 0000 3155`

Full list: https://stripe.com/docs/testing

## Viewing Test Payments

1. Go to https://dashboard.stripe.com/test/payments
2. You'll see all test transactions
3. Click on any payment to see details
4. Check the webhook events to verify they were delivered

## Troubleshooting

### "Cloud Functions not deployed" error
- Make sure you're on the Firebase Blaze plan
- Run `firebase deploy --only functions`
- Check the Firebase Console for deployment errors

### Webhook not triggering
- Verify the webhook URL is correct
- Check that you selected the right events
- Look at webhook logs in Stripe Dashboard
- Ensure the webhook secret is set correctly

### Payment not updating premium status
- Check Cloud Function logs in Firebase Console
- Verify the webhook is being called (check Stripe Dashboard)
- Ensure `client_reference_id` is being passed correctly
- Check Firestore security rules allow the function to write

## Demo Mode Fallback

If Cloud Functions are not deployed or Stripe is not configured, the app will automatically fall back to demo mode with a mock payment form. This allows you to test the UI without a full Stripe setup.

## Production Considerations

Before going to production:

1. Switch to live Stripe keys (remove `_test_` from keys)
2. Update success/cancel URLs in `createCheckoutSession`
3. Implement proper error handling and logging
4. Add customer portal for subscription management
5. Consider using Stripe Customer Portal for self-service
6. Implement proper receipt validation
7. Add subscription status sync on app startup
8. Handle edge cases (refunds, disputes, etc.)

## Security Notes

- Never commit API keys to version control
- Use environment variables for all secrets
- Validate webhook signatures (already implemented)
- Never trust client-side subscription status
- Always verify payments server-side via webhooks
- Use HTTPS for all webhook endpoints
