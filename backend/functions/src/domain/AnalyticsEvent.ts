import { Timestamp } from "firebase-admin/firestore";
import { ClientPlatform, PlaybackStrategy } from "./Device";

export type AnalyticsEventType =
  | "app_open"
  | "session_start"
  | "session_end"
  | "audio_play"
  | "favorite_add"
  | "favorite_remove";

/**
 * Firestore: `analytics_events/{eventId}`
 * Write-only from Cloud Functions — clients can never read or write this
 * collection directly (see firestore.rules); ingestion goes through the
 * `recordAnalyticsEvent` callable in api/client/analyticsEvents.ts.
 *
 * Volume note: per ARCHITECTURE.md §11, at scale this should stream via
 * Pub/Sub into BigQuery instead of Firestore. Not implemented yet — the
 * `analytics_daily` rollup (see AnalyticsDailyRollup below) is the interim
 * aggregation path for the admin panel.
 */
export interface AnalyticsEvent {
  id: string;
  uid: string | null; // null only if somehow ingested pre-auth; anonymous auth still has a uid
  type: AnalyticsEventType;
  audioId?: string; // present for audio_play, favorite_add, favorite_remove
  categoryId?: string;
  sessionId?: string;
  sessionDurationMs?: number; // present for session_end
  playbackStrategy?: PlaybackStrategy; // present for audio_play
  watchModel?: string;
  phoneModel?: string;
  bluetoothSpeakerBrand?: string;
  platform?: ClientPlatform;
  appVersion?: string;
  clientTimestamp: Timestamp; // when the event happened on-device
  receivedAt: Timestamp; // server ingestion time (clock skew reference)
}

export type AnalyticsEventInput = Omit<AnalyticsEvent, "id" | "uid" | "receivedAt">;

/**
 * Firestore: `analytics_daily/{date}` where date is `YYYY-MM-DD` (UTC).
 * Built by the scheduled `aggregateDailyAnalytics` function from the
 * previous day's `analytics_events`. Admin-panel read only (see rules).
 */
export interface AnalyticsDailyRollup {
  date: string;
  totalPlays: number;
  totalSessions: number;
  totalFavoritesAdded: number;
  totalFavoritesRemoved: number;
  activeUsers: number; // distinct uids seen across all event types
  avgSessionDurationMs: number;
  playsByAudio: Record<string, number>;
  playsByCategory: Record<string, number>;
  playsByStrategy: Record<PlaybackStrategy, number>;
  generatedAt: Timestamp;
}
