const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
// Keep v1 for legacy support if needed, but we are moving to v2 imports mainly.
// However, setGlobalOptions might be needed or specific defines.
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// 1. Create Share Link
// Generates a random token and saves it to the bill.
exports.createShareLink = onCall(async (request) => {
  // v2: request contains .data and .auth
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in");
  }

  const data = request.data;
  const billId = data.billId;
  const billRef = db.collection("bills").doc(billId);

  // Verify ownership or access
  const billSnap = await billRef.get();
  if (!billSnap.exists) {
    throw new HttpsError("not-found", "Bill not found");
  }
  const billData = billSnap.data();

  if (billData.ownerUserId !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Only owner can share");
  }

  const token = generateRandomToken();
  await billRef.update({
    shareToken: token,
    isLinkActive: true,
  });

  return { token: token, url: `https://splitzy-app.web.app/b/${token}` };
});

// 2. Revoke Share Link
exports.revokeShareLink = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be logged in");
  }

  const data = request.data;
  const billId = data.billId;
  const billRef = db.collection("bills").doc(billId);
  const billSnap = await billRef.get();
  if (!billSnap.exists) {
    throw new HttpsError("not-found", "Bill not found");
  }

  if (billSnap.data().ownerUserId !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Only owner can revoke");
  }

  await billRef.update({
    shareToken: admin.firestore.FieldValue.delete(),
    isLinkActive: false,
  });

  return { success: true };
});

// 3. Get Public Bill Snapshot
// Returns limited data for the web viewer.
exports.getPublicBillSnapshot = onCall(async (request) => {
  const data = request.data; // v2 does not enforce auth if not needed, but data is in request.data
  const token = data.token;
  if (!token) {
    throw new HttpsError("invalid-argument", "Missing token");
  }

  const billsQuery = await db.collection("bills")
    .where("shareToken", "==", token)
    .where("isLinkActive", "==", true)
    .limit(1)
    .get();

  if (billsQuery.empty) {
    throw new HttpsError("not-found", "Bill not found or link expired");
  }

  const billDoc = billsQuery.docs[0];
  const bill = billDoc.data();

  // Fetch sub-collections if items are separate, or if embedded:
  // Assuming embedded or fetched via ID.
  const itemsSnap = await billDoc.ref.collection("items").get();
  const items = itemsSnap.docs.map((d) => d.data());

  return {
    title: bill.title,
    createdAt: bill.createdAt.toDate().toISOString(),
    currency: bill.currency,
    items: items,
    taxCents: bill.taxCents,
    tipCents: bill.tipCents,
    // Do NOT return user IDs or private info
    participants: bill.participantNames || [],
  };
});

// 4. Notify Added User
// Triggered when a participant with a linkedUserId is added.
exports.onParticipantAdded = onDocumentCreated("bills/{billId}/participants/{participantId}", async (event) => {
  const snap = event.data;
  // If undefined (e.g. deleted), return
  if (!snap) return;

  const participant = snap.data();
  if (participant.linkedUserId) {
    // Send FCM
    const userRef = db.collection("users").doc(participant.linkedUserId);
    const userSnap = await userRef.get();
    if (userSnap.exists && userSnap.data().fcmToken) {
      const token = userSnap.data().fcmToken;
      await admin.messaging().send({
        token: token,
        notification: {
          title: "Splitzy",
          body: "You were added to a bill.",
        },
        data: {
          billId: event.params.billId, // v2 uses event.params
        },
      });
    }
  }
});

function generateRandomToken() {
  return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}
