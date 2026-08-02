import { Timestamp } from "firebase-admin/firestore";
import { db } from "../config/firebaseAdmin";
import {
  AnalyticsDailyRollup,
  AnalyticsEvent,
  AnalyticsEventInput,
} from "../domain/AnalyticsEvent";

const EVENTS_COLLECTION = "analytics_events";
const DAILY_COLLECTION = "analytics_daily";

export class AnalyticsRepository {
  private eventsCol = db.collection(EVENTS_COLLECTION);
  private dailyCol = db.collection(DAILY_COLLECTION);

  /** Batched ingestion — writes are cheap Firestore adds, fan-out aggregation happens nightly. */
  async recordEvents(uid: string | null, events: AnalyticsEventInput[]): Promise<void> {
    const batch = db.batch();
    const receivedAt = Timestamp.now();
    for (const event of events) {
      const ref = this.eventsCol.doc();
      const doc: AnalyticsEvent = { id: ref.id, uid, ...event, receivedAt };
      batch.set(ref, doc);
    }
    await batch.commit();
  }

  /** Fetch all events with `clientTimestamp` in `[start, end)`, for the scheduled rollup. */
  async listEventsInRange(start: Timestamp, end: Timestamp): Promise<AnalyticsEvent[]> {
    const snap = await this.eventsCol
      .where("clientTimestamp", ">=", start)
      .where("clientTimestamp", "<", end)
      .get();
    return snap.docs.map((d) => d.data() as AnalyticsEvent);
  }

  async saveDailyRollup(rollup: AnalyticsDailyRollup): Promise<void> {
    await this.dailyCol.doc(rollup.date).set(rollup);
  }

  async getDailyRollup(date: string): Promise<AnalyticsDailyRollup | null> {
    const snap = await this.dailyCol.doc(date).get();
    return snap.exists ? (snap.data() as AnalyticsDailyRollup) : null;
  }

  async listRecentRollups(limit: number): Promise<AnalyticsDailyRollup[]> {
    const snap = await this.dailyCol.orderBy("date", "desc").limit(limit).get();
    return snap.docs.map((d) => d.data() as AnalyticsDailyRollup);
  }
}
