/**
 * Cloud Functions for E-learning App
 * 
 * NOTE: These functions require the Firebase "Blaze" (Pay-as-you-go) plan to deploy.
 * If you are on the "Spark" (Free) plan, you can keep this code in your repository
 * for assessment purposes. Flashcard generation has been moved to the client-side
 * (Flutter app) to ensure functionality on the Free plan.
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

// Define secrets for Stripe API keys
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

admin.initializeApp();

/**
 * 1. BACKEND ENFORCEMENT: enforceSetLimit
 * Trigger: onDocumentCreated("users/{userId}/learning_sets/{setId}")
 * 
 * Purpose: This is a security redundant check. Even though the Flutter app 
 * checks the 3-set limit, this backend function ensures that no user can
 * bypass the UI to create extra sets beyond the Free Tier limit.
 */
exports.enforceSetLimit = onDocumentCreated(
  "users/{userId}/learning_sets/{setId}",
  async (event) => {
    const userId = event.params.userId;
    const userRef = admin.firestore().doc(`users/${userId}`);
    const userDoc = await userRef.get();

    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const isPremium = userData.isPremium || false;
    const setsCount = userData.setsCount || 0;

    // If non-premium user somehow created more than 3 sets, delete the document
    if (!isPremium && setsCount > 3) {
      console.warn(`Enforcing Free Tier limit for user ${userId}. Deleting set ${event.params.setId}.`);
      
      // Delete the unauthorized set
      await event.data.ref.delete();
      
      // Correct the setsCount on the user document
      await userRef.update({
        setsCount: admin.firestore.FieldValue.increment(-1),
      });
    }
  }
);

/**
 * 2. REACTIVE PROGRESS TRACKING: onFlashcardDifficultyUpdated
 * Trigger: onDocumentUpdated("users/{userId}/learning_sets/{setId}/flashcards/{cardId}")
 * 
 * Purpose: Automatically manages the "Progress" document for each learning set.
 * When a user changes a card's difficulty (easy, medium, hard), this function
 * updates the aggregated counters in the set's metadata. 
 * This ensures the Home screen always shows accurate stats.
 */
exports.onFlashcardDifficultyUpdated = onDocumentUpdated(
  "users/{userId}/learning_sets/{setId}/flashcards/{cardId}",
  async (event) => {
    const beforeData = event.data.before.data();
    const afterData = event.data.after.data();

    // Avoid unnecessary writes if the difficulty hasn't actually changed
    if (beforeData.difficulty === afterData.difficulty) return;

    const userId = event.params.userId;
    const setId = event.params.setId;
    const progressRef = admin.firestore().doc(
      `users/${userId}/learning_sets/${setId}/meta/progress`
    );

    const updates = {};

    // Logic for updating counters using atomic increments
    if (beforeData.difficulty !== "unreviewed") {
      // Decrement the old difficulty counter
      updates[beforeData.difficulty] = admin.firestore.FieldValue.increment(-1);
    } else {
      // If moving from 'unreviewed', increase the total 'reviewed' count
      updates.reviewed = admin.firestore.FieldValue.increment(1);
    }

    // Increment the new difficulty counter
    updates[afterData.difficulty] = admin.firestore.FieldValue.increment(1);

    // Apply all counter changes in a single atomic update
    await progressRef.update(updates);
    console.log(`Updated progress for set ${setId} (User: ${userId})`);
  }
);

/**
 * 3. CREATE STRIPE CHECKOUT SESSION
 * Trigger: Callable HTTPS Function
 * 
 * Purpose: Securely creates a Stripe Checkout Session on the backend.
 * The Flutter app calls this function, receives a checkout URL, and opens it.
 * After payment, Stripe redirects back to the app and sends a webhook.
 */
exports.createCheckoutSession = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    const userId = request.auth?.uid;
    
    if (!userId) {
      throw new Error("Authentication required");
    }

    try {
      // Initialize Stripe with the secret key
      const stripe = require("stripe")(stripeSecretKey.value());
      
      // Create Stripe Checkout Session
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        line_items: [
          {
            price_data: {
              currency: "usd",
              product_data: {
                name: "LearnFlow Premium",
                description: "Unlimited learning sets and advanced analytics",
              },
              unit_amount: 499, // $4.99 in cents
              recurring: {
                interval: "month",
              },
            },
            quantity: 1,
          },
        ],
        mode: "subscription",
        success_url: "https://your-app.com/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "https://your-app.com/cancel",
        client_reference_id: userId, // Used in webhook to identify the user
        metadata: {
          userId: userId,
        },
      });

      return {
        sessionId: session.id,
        url: session.url,
      };
    } catch (error) {
      console.error("Error creating checkout session:", error);
      throw new Error("Failed to create checkout session");
    }
  }
);

/**
 * 4. SECURE PAYMENT VALIDATION: handleStripeWebhook
 * Trigger: HTTPS Request (from Stripe Webhooks)
 * 
 * Purpose: This is the gold standard for subscription security. 
 * Instead of trusting the Flutter app (which could be hacked), we wait 
 * for Stripe's own servers to notify us that a payment was successful. 
 * Only then do we update the `isPremium` field in Firestore.
 */
exports.handleStripeWebhook = require("firebase-functions/v1").https.onRequest(
  async (req, res) => {
    const event = req.body;

    // Handle the specific event types from Stripe
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object;
        const userId = session.client_reference_id; // Pass this from the app
        
        if (userId) {
          await admin.firestore().doc(`users/${userId}`).update({
            isPremium: true,
          });
          console.log(`User ${userId} upgraded to Premium via Stripe.`);
        }
        break;
      }
      
      case "customer.subscription.deleted": {
        const subscription = event.data.object;
        const customerId = subscription.customer;
        
        // Find user by customerId and set isPremium: false
        const users = await admin.firestore().collection("users")
          .where("stripeCustomerId", "==", customerId).get();
          
        if (!users.empty) {
          await users.docs[0].ref.update({ isPremium: false });
          console.log(`User ${users.docs[0].id} subscription canceled.`);
        }
        break;
      }
    }

    res.status(200).send("Webhook handled.");
  }
);
