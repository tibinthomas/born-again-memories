const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

/**
 * Fires when a new milestone is created under any profile.
 * Sends a push notification to every user who has shared access
 * to this baby's memories (i.e. whose email is in the owner's
 * sharedWithEmails list and who has a stored FCM token).
 */
exports.onMilestoneCreated = onDocumentCreated(
  "users/{uid}/profiles/{profileId}/milestones/{milestoneId}",
  async (event) => {
    const { uid } = event.params;
    const milestone = event.data?.data();
    if (!milestone) return;

    const db = getFirestore();

    // Get the owner's user doc — contains sharedWithEmails + displayName.
    const ownerSnap = await db.doc(`users/${uid}`).get();
    const owner = ownerSnap.data();
    if (!owner) return;

    const sharedWith = owner.sharedWithEmails ?? [];
    if (sharedWith.length === 0) return;

    const senderName = owner.displayName || owner.email || "Someone";
    const milestoneTitle = milestone.title || "a new memory";

    // Look up FCM tokens for all invited users.
    const usersSnap = await db
      .collection("users")
      .where("email", "in", sharedWith.slice(0, 10)) // 'in' supports max 10
      .get();

    // Tokens live in each user's owner-only data subcollection
    // (users/{uid}/data/fcm), not on the publicly readable user doc.
    const tokenRefs = usersSnap.docs.map((d) => db.doc(`users/${d.id}/data/fcm`));
    const tokenSnaps = tokenRefs.length > 0 ? await db.getAll(...tokenRefs) : [];
    const tokens = tokenSnaps
      .map((s) => s.get("token"))
      .filter(Boolean);

    if (tokens.length === 0) return;

    // Send one multicast message to all tokens.
    const messaging = getMessaging();
    await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: `${senderName} added a new memory ✨`,
        body: milestoneTitle,
      },
      data: {
        type: "new_milestone",
        senderUid: uid,
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      android: {
        notification: {
          sound: "default",
          channelId: "shared_memories",
        },
      },
    });
  }
);
