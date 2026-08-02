import { Timestamp } from "firebase-admin/firestore";

/**
 * Firestore: `users/{uid}/favorites/{audioId}`
 * Owner-only read/write, written directly by the client (see
 * api/client/favorites.ts for why this isn't a callable).
 */
export interface Favorite {
  audioId: string;
  createdAt: Timestamp;
}
