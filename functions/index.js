const admin = require("firebase-admin");
const functions = require("firebase-functions");

// ⚠️ Use environment variable for security
// Set STRIPE_SECRET_KEY in Firebase Functions config:
// firebase functions:config:set stripe.secret_key="your_stripe_secret_key"
const stripeKey = functions.config().stripe?.secret_key || process.env.STRIPE_SECRET_KEY || "";
if (!stripeKey) {
  console.error("⚠️ Stripe secret key not configured. Set it in Firebase Functions config.");
}
const stripe = require("stripe")(stripeKey);

admin.initializeApp();

// 🔔 Firestore Trigger: Send FCM Notification
exports.sendNotification = functions.firestore
    .document("notification_requests/{docId}")
    .onCreate(async (snap, context) => {
      const {receiverToken, title, body} = snap.data();

      const message = {
        token: receiverToken,
        notification: {
          title: title,
          body: body,
        },
        android: {
          notification: {
            sound: "default",
            priority: "high",
          },
        },
      };

      try {
        await admin.messaging().send(message);
        console.log("Notification sent successfully");
        await snap.ref.delete();
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    });

// 💳 Callable: Create Stripe Payment Intent
exports.createPaymentIntent = functions.https.onCall(
    async (data, context) => {
      const amount = data.amount;

      try {
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amount,
          currency: "usd",
          automatic_payment_methods: {
            enabled: true,
          },
        });

        return {
          clientSecret: paymentIntent.client_secret,
        };
      } catch (error) {
        console.error("Stripe Error:", error.message);
        throw new functions.https.HttpsError(
            "internal",
            "Unable to create payment intent",
        );
      }
    },
);

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Collection of engaging content
const jokes = [
  {
    title: '😄 Dino Joke Time!',
    body: 'Why did the dino go to the doctor? Because he had a "rawr" throat! 🦖',
  },
  {
    title: '🤣 Connect Humor',
    body: 'What do you call a task that\'s always late? A "deadline"! 😅',
  },
  {
    title: '😆 Fun Fact',
    body: 'Did you know? Helping others releases endorphins - nature\'s way of saying "you\'re awesome!" 🌟',
  },
  {
    title: '🎉 Motivation Boost',
    body: 'Remember: Every task completed is a step toward making someone\'s day better! 💪',
  },
  {
    title: '🦖 Dino Wisdom',
    body: 'Even dinosaurs had to start somewhere. Your journey to helping others starts with one task! 🚀',
  },
];

const tips = [
  {
    title: '💡 Pro Tip',
    body: 'Complete your profile to get more task requests! People trust users with complete profiles.',
  },
  {
    title: '🎯 Task Success',
    body: 'Clear communication is key! Always ask questions if you\'re unsure about a task.',
  },
  {
    title: '⭐ Rating Boost',
    body: 'Deliver quality work and ask for ratings - they help you get more opportunities!',
  },
  {
    title: '🔍 Smart Searching',
    body: 'Use filters to find tasks that match your skills and location!',
  },
  {
    title: '💰 Earn More',
    body: 'Set competitive prices and provide excellent service to build a loyal client base!',
  },
];

const motivational = [
  {
    title: '🌟 You\'re Amazing!',
    body: 'Every task you complete makes the world a better place. Keep up the great work!',
  },
  {
    title: '💪 Power Move',
    body: 'Your skills are valuable. Don\'t underestimate the impact you can make!',
  },
  {
    title: '🎯 Goal Achiever',
    body: 'Small steps lead to big changes. Every task is progress toward your goals!',
  },
  {
    title: '🔥 On Fire!',
    body: 'You\'re building something amazing - a network of people who trust and value your work!',
  },
  {
    title: '🚀 Rising Star',
    body: 'Your dedication to helping others is inspiring. The community needs people like you!',
  },
];

// Helper function to get random content
function getRandomContent() {
  const contentTypes = [jokes, tips, motivational];
  const selectedType = contentTypes[Math.floor(Math.random() * contentTypes.length)];
  return selectedType[Math.floor(Math.random() * selectedType.length)];
}

// Scheduled function to send engagement notifications
exports.sendEngagementNotifications = functions.pubsub
  .schedule('0 10 * * *') // Run daily at 10 AM
  .timeZone('Asia/Karachi')
  .onRun(async (context) => {
    try {
      console.log('🕐 Starting daily engagement notifications...');
      
      // Get all users who haven't received a notification today
      const today = new Date().toISOString().split('T')[0];
      const usersSnapshot = await db.collection('users')
        .where('lastEngagementNotification', '!=', today)
        .get();

      console.log(`📱 Found ${usersSnapshot.size} users to notify`);

      const batch = db.batch();
      let notificationCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        const preferences = userData.notificationPreferences || {};

        // Check if user has disabled notifications
        if (preferences.daily === false) {
          console.log(`⏭️ Skipping user ${userDoc.id} - notifications disabled`);
          continue;
        }

        if (!fcmToken) {
          console.log(`⚠️ No FCM token for user ${userDoc.id}`);
          continue;
        }

        // Get random content
        const content = getRandomContent();

        // Send FCM notification
        try {
          const message = {
            token: fcmToken,
            notification: {
              title: content.title,
              body: content.body,
            },
            data: {
              type: 'engagement',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            android: {
              notification: {
                channelId: 'engagement_channel',
                color: '#00C7BE',
                icon: '@mipmap/ic_launcher',
                priority: 'high',
              },
            },
          };

          const response = await admin.messaging().send(message);
          console.log(`✅ Notification sent to ${userDoc.id}: ${response}`);

          // Update user's last notification date
          batch.update(userDoc.ref, {
            lastEngagementNotification: today,
            engagementNotificationsCount: admin.firestore.FieldValue.increment(1),
          });

          notificationCount++;
        } catch (error) {
          console.error(`❌ Failed to send notification to ${userDoc.id}:`, error);
        }
      }

      // Commit batch updates
      await batch.commit();
      console.log(`🎉 Successfully sent ${notificationCount} engagement notifications`);

      return { success: true, notificationsSent: notificationCount };
    } catch (error) {
      console.error('❌ Error in sendEngagementNotifications:', error);
      throw error;
    }
  });

// HTTP function to send immediate notification (for testing)
exports.sendImmediateEngagementNotification = functions.https.onRequest(async (req, res) => {
  try {
    const { userId } = req.body;
    
    if (!userId) {
      res.status(400).json({ error: 'userId is required' });
      return;
    }

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      res.status(400).json({ error: 'No FCM token found for user' });
      return;
    }

    const content = getRandomContent();
    const message = {
      token: fcmToken,
      notification: {
        title: content.title,
        body: content.body,
      },
      data: {
        type: 'engagement',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        notification: {
          channelId: 'engagement_channel',
          color: '#00C7BE',
          icon: '@mipmap/ic_launcher',
          priority: 'high',
        },
      },
    };

    const response = await admin.messaging().send(message);
    
    res.json({ 
      success: true, 
      messageId: response,
      content: content 
    });
  } catch (error) {
    console.error('❌ Error sending immediate notification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Function to handle scheduled notifications from Firestore
exports.processScheduledNotifications = functions.firestore
  .document('scheduled_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    try {
      const notificationData = snap.data();
      const { userId, title, body, scheduledTime, sent } = notificationData;

      if (sent) {
        console.log('⏭️ Notification already sent');
        return;
      }

      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.log('❌ User not found');
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log('❌ No FCM token found');
        return;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: 'scheduled_engagement',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'engagement_channel',
            color: '#00C7BE',
            icon: '@mipmap/ic_launcher',
            priority: 'high',
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Scheduled notification sent: ${response}`);

      // Mark as sent
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });

    } catch (error) {
      console.error('❌ Error processing scheduled notification:', error);
    }
  });
