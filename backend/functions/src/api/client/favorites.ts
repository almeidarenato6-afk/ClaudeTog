/**
 * Design note: favorites are NOT a callable function.
 *
 * `toggleFavorite` is implemented as a direct client write to
 * `users/{uid}/favorites/{audioId}` (create to favorite, delete to
 * unfavorite), enforced by firestore.rules as owner-only. This is the
 * simpler correct design because:
 *
 *   1. There's no server-side validation to perform beyond "is this my own
 *      subcollection" — Firestore rules already express that precisely.
 *   2. It avoids a network round-trip through Cloud Functions for a very
 *      latency-sensitive, frequently-tapped UI action (see
 *      ARCHITECTURE.md §4's <150ms budget — favoriting sits in the same
 *      interaction path as playback).
 *   3. Firestore's offline persistence means the client gets optimistic,
 *      offline-first favorite toggling for free; a callable would require
 *      reimplementing that queuing client-side anyway.
 *
 * The one thing that DOES need server-side consistency — the denormalized
 * `AudioClip.favoriteCount` — is kept in sync by the `onFavoriteWrite`
 * Firestore trigger (see triggers/onFavoriteWrite.ts), which runs with
 * Admin SDK privileges regardless of how the favorite doc was written.
 *
 * `favorite_add` / `favorite_remove` analytics events are still sent
 * through `recordAnalyticsEvent` (see analyticsEvents.ts) since analytics
 * writes are always Cloud-Function-only.
 */
export {};
