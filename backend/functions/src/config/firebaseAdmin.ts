import { initializeApp, getApps, App } from "firebase-admin/app";
import { getFirestore, Firestore } from "firebase-admin/firestore";
import { getAuth, Auth } from "firebase-admin/auth";
import { getStorage, Storage } from "firebase-admin/storage";
import { getMessaging, Messaging } from "firebase-admin/messaging";

// Single Admin SDK app instance shared by every function in this codebase.
// Cloud Functions may cold-start multiple module instances, so guard against
// re-initializing when `getApps()` already has one (common in emulator + test runs).
export const app: App = getApps().length > 0 ? getApps()[0] : initializeApp();

export const db: Firestore = getFirestore(app);
export const auth: Auth = getAuth(app);
export const storage: Storage = getStorage(app);
export const messaging: Messaging = getMessaging(app);

// Firestore ignores `undefined` fields by default in the Admin SDK, but we set
// this explicitly so partial-update helpers (e.g. `{...patch}`) never crash
// when an optional field is omitted.
db.settings({ ignoreUndefinedProperties: true });
