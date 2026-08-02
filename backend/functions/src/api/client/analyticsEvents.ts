import { onCall, HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { Timestamp } from "firebase-admin/firestore";
import { REGION, config } from "../../config/env";
import { AnalyticsRepository } from "../../repositories/AnalyticsRepository";

const analyticsRepository = new AnalyticsRepository();

const eventSchema = z.object({
  type: z.enum([
    "app_open",
    "session_start",
    "session_end",
    "audio_play",
    "favorite_add",
    "favorite_remove",
  ]),
  audioId: z.string().optional(),
  categoryId: z.string().optional(),
  sessionId: z.string().optional(),
  sessionDurationMs: z.number().int().nonnegative().optional(),
  playbackStrategy: z.enum(["DIRECT", "RELAY", "PHONE_ONLY"]).optional(),
  watchModel: z.string().optional(),
  phoneModel: z.string().optional(),
  bluetoothSpeakerBrand: z.string().optional(),
  platform: z.enum(["ios", "android", "wearos", "watchos", "garmin"]).optional(),
  appVersion: z.string().optional(),
  clientTimestampMs: z.number().int().positive(),
});

const recordAnalyticsEventSchema = z.object({
  events: z.array(eventSchema).min(1).max(config.limits.maxAnalyticsEventsPerBatch),
});

/**
 * Batched analytics ingestion. Clients queue events locally (offline-first)
 * and flush them here periodically, so this accepts an array rather than one
 * event per call. Firestore write here is the interim store; per
 * ARCHITECTURE.md §11 this should eventually stream through Pub/Sub into
 * BigQuery for high-volume export — not implemented yet.
 */
export const recordAnalyticsEvent = onCall({ region: REGION }, async (request) => {
  const uid = request.auth?.uid ?? null;

  const parsed = recordAnalyticsEventSchema.safeParse(request.data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", parsed.error.message);
  }

  const events = parsed.data.events.map(({ clientTimestampMs, ...rest }) => ({
    ...rest,
    clientTimestamp: Timestamp.fromMillis(clientTimestampMs),
  }));

  await analyticsRepository.recordEvents(uid, events);
  return { accepted: events.length };
});
