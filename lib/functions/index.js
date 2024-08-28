const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotification = functions.https.onCall(async (data, context) => {
  const { userId, title, body } = data;

  // Get the user's FCM token from Firestore
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const fcmToken = userDoc.data().fcmToken;

  if (!fcmToken) {
    throw new functions.https.HttpsError('not-found', 'User does not have an FCM token');
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: fcmToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return { success: true };
  } catch (error) {
    console.log('Error sending message:', error);
    throw new functions.https.HttpsError('internal', 'Error sending notification');
  }
});