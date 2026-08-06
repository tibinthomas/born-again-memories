const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
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

/**
 * Applies a conservative automatic hold after three distinct users report the
 * same story, question, or answer. The content remains available to its author
 * and moderators through Firestore rules, while regular community feeds hide it.
 * A moderator can restore or remove it by changing moderationStatus.
 */
exports.onUgcReportCreated = onDocumentCreated(
  "ugcReports/{reportId}",
  async (event) => {
    const report = event.data?.data();
    if (!report || report.status !== "pending") return;

    const targetPath = report.targetPath;
    if (typeof targetPath !== "string") return;

    const segments = targetPath.split("/");
    const isStory = segments.length === 2 && segments[0] === "blogs";
    const isQuestion = segments.length === 2 && segments[0] === "forum";
    const isAnswer =
      segments.length === 4 &&
      segments[0] === "forum" &&
      segments[2] === "answers";
    if (!isStory && !isQuestion && !isAnswer) return;

    const db = getFirestore();
    const reports = await db
      .collection("ugcReports")
      .where("targetPath", "==", targetPath)
      .get();
    const reporterIds = new Set(
      reports.docs
        .filter((doc) => doc.get("status") === "pending")
        .map((doc) => doc.get("reporterId"))
        .filter(Boolean)
    );
    if (reporterIds.size < 3) return;

    const targetRef = db.doc(targetPath);
    const target = await targetRef.get();
    if (!target.exists || target.get("moderationStatus") === "hidden") return;

    const batch = db.batch();
    batch.update(targetRef, {
      moderationStatus: "hidden",
      moderationReason: "Automatically held after multiple user reports",
      moderatedAt: FieldValue.serverTimestamp(),
    });
    for (const reportDoc of reports.docs.filter(
      (doc) => doc.get("status") === "pending"
    )) {
      batch.update(reportDoc.ref, {
        autoActionTaken: true,
        reviewedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
);
