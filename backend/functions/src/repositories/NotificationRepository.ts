import { Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebaseAdmin";
import { NotificationRecord, NotificationTarget } from "../domain/Notification";

const COLLECTION = "notifications_log";

export class NotificationRepository {
  private col = db.collection(COLLECTION);

  async log(entry: {
    title: string;
    body: string;
    imageUrl?: string;
    target: NotificationTarget;
    data?: Record<string, string>;
    sentBy: string;
    successCount: number;
    failureCount: number;
  }): Promise<NotificationRecord> {
    const ref = this.col.doc();
    const record: NotificationRecord = {
      id: ref.id,
      sentAt: Timestamp.now(),
      ...entry,
    };
    await ref.set(record);
    return record;
  }

  async listRecent(limit: number): Promise<NotificationRecord[]> {
    const snap = await this.col.orderBy("sentAt", "desc").limit(limit).get();
    return snap.docs.map((d) => d.data() as NotificationRecord);
  }
}
