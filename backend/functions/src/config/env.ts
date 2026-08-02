/**
 * Central place for environment-derived configuration. Cloud Functions v2 reads
 * runtime configuration from environment variables (set via `firebase functions:secrets:set`
 * for secrets, or `.env.<projectId>` files for plain config) rather than the deprecated
 * `functions.config()` API.
 */

export const REGION = process.env.FUNCTIONS_REGION ?? "southamerica-east1";

export const config = {
  region: REGION,
  // Default FCM topic every device subscribes to on registration; used for
  // "broadcast to everyone" admin notifications.
  fcmDefaultTopic: "all_users",
  // Soft ceilings enforced in callable handlers (defense in depth on top of
  // Storage rules, since Storage rules alone can't cap batch Firestore writes).
  limits: {
    maxAnalyticsEventsPerBatch: 50,
    maxStarterPackAudios: 20,
  },
} as const;
