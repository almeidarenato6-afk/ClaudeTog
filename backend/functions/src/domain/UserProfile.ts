import { Timestamp } from "firebase-admin/firestore";

export type AuthProvider = "google" | "apple" | "email" | "anonymous";

/**
 * Firestore: `users/{uid}`
 * Owner-only read/write (see firestore.rules).
 *
 * Deliberately does NOT carry an admin-panel `role` field. Roles live only as
 * Firebase Auth custom claims (`request.auth.token.role`), set exclusively by
 * Cloud Functions with the Admin SDK — mirroring role into a client-writable
 * document would open a trivial privilege-escalation path.
 */
export interface UserProfile {
  uid: string;
  displayName: string | null;
  email: string | null;
  photoURL: string | null;
  authProvider: AuthProvider;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActiveAt: Timestamp;
}

export type UserProfileUpdateInput = Partial<
  Pick<UserProfile, "displayName" | "photoURL">
>;

/** Roles are custom claims only — see comment above. Kept here as the single source of truth for valid values. */
export type Role = "admin" | "content_manager" | "viewer";
export const ROLES: readonly Role[] = ["admin", "content_manager", "viewer"];
