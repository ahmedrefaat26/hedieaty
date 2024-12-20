/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as logger from "firebase-functions/logger";

import {onDocumentUpdated} from "firebase-functions/v2/firestore";

// const {
//   logger.info,
//   debug,
//   error,
//   logger.warn,
// } = require("firebase-functions/logger");
// const admin = require("firebase-admin");
import * as admin from "firebase-admin";

admin.initializeApp();

const giftPledgeNotification =
    onDocumentUpdated("gifts/{giftId}", async (event) => {
      if (!event.data) {
        logger.warn("Event data is undefined");
        return;
      }

      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();
      logger.info("beforeData:", beforeData);
      logger.info("afterData:", afterData);

      try {
        if (beforeData.status !== "pledged" && afterData.status === "pledged") {
          const {event_id: eventId, name, pledgedBy} = afterData;
          logger.info("eventId:", eventId);
          const event =
        await admin.firestore().collection("events").doc(eventId).get();
          const eventData = event.data();
          if (!eventData) {
            logger.error("Event data is undefined");
            return;
          }
          const userId = eventData["user_id"];
          logger.info("user_id:", userId);
          const user =
        await admin.firestore().collection("users").doc(userId).get();
          const userData = user.data();
          if (!userData) {
            logger.error("User data is undefined");
            return;
          }
          const pledger =
        await admin.firestore().collection("users").doc(pledgedBy).get();
          const pledgerData = pledger.data();
          if (!pledgerData) {
            logger.error("Pledger data is undefined");
            return;
          }
          const fcmToken = userData["fcmToken"];
          const pledgerName = pledgerData["name"];
          logger.info("fcmToken:", fcmToken);

          if (fcmToken) {
            const payload = {
              token: fcmToken,
              notification: {
                title: `${name} Gift Pledged!`,
                body: `${pledgerName} has pledged a gift for you!`,
              },
              //                 data: {
              //                   giftId: event.params.giftId,
              //                   eventId: eventDoc.data().id,
              //                 },
            };
            logger.info("payload:", payload);
            const response = await admin.messaging().send(payload);
            logger.info("Notification sent. Response:", response);
          } else {
            logger.warn("No FCM token found for user.");
          }
        } else {
          logger.warn("Gift status not changed to 'pledged'.");
        }
      } catch (e) {
        logger.error(e);
      }
    });

export {giftPledgeNotification};

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
