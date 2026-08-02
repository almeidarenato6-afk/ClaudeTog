import { Timestamp } from "firebase-admin/firestore";

export type NotificationTarget =
  | { type: "topic"; topic: string }
  | { type: "segment"; segment: string } // resolved server-side to a set of tokens
  | { type: "uid"; uid: string };

/**
 * Firestore: `notifications_log/{notificationId}`
 * Written only by the `sendNotification` admin callable after dispatch to
 * FCM; readable by admin/content_manager/viewer roles for the panel's send
 * history. Not the message payload itself — FCM doesn't persist that.
 */
export interface NotificationRecord {
  id: string;
  title: string;
  body: string;
  imageUrl?: string;
  target: NotificationTarget;
  data?: Record<string, string>; // arbitrary client-handled deep-link payload
  sentBy: string; // admin uid
  sentAt: Timestamp;
  successCount: number;
  failureCount: number;
}
