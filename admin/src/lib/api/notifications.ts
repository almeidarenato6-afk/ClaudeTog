import {
  collection,
  getDocs,
  limit as fsLimit,
  orderBy,
  query,
  Timestamp,
} from "firebase/firestore";
import { httpsCallable } from "firebase/functions";
import { db, functions } from "@/lib/firebase";
import type { NotificationRecord, SendNotificationInput } from "./types";

const COLLECTION = "notifications";

interface NotificationDoc {
  title: string;
  body: string;
  target: NotificationRecord["target"];
  sentAt: Timestamp | null;
  status: NotificationRecord["status"];
  sentBy: string | null;
  recipientCount: number | null;
}

function fromDoc(id: string, data: NotificationDoc): NotificationRecord {
  return {
    id,
    title: data.title,
    body: data.body,
    target: data.target,
    sentAt: data.sentAt?.toDate().toISOString() ?? null,
    status: data.status,
    sentBy: data.sentBy,
    recipientCount: data.recipientCount,
  };
}

export async function listNotifications(): Promise<NotificationRecord[]> {
  const snap = await getDocs(
    query(
      collection(db, COLLECTION),
      orderBy("sentAt", "desc"),
      fsLimit(100),
    ),
  );
  return snap.docs.map((d) => fromDoc(d.id, d.data() as NotificationDoc));
}

export async function sendNotification(
  input: SendNotificationInput,
): Promise<{ id: string; recipientCount: number }> {
  const call = httpsCallable<
    SendNotificationInput,
    { id: string; recipientCount: number }
  >(functions, "sendNotification");
  const result = await call(input);
  return result.data;
}
