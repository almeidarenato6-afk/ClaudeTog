// firebase-functions v2 does not yet expose a non-blocking `onCreate` auth
// trigger (only the blocking `beforeUserCreated`/`beforeUserSignedIn` identity
// triggers under v2/identity). Mixing the v1 auth trigger into an otherwise
// v2 codebase is the documented approach until Google ships a v2 equivalent.
import * as functionsV1 from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";
import { UserRepository } from "../repositories/UserRepository";
import { UserProfile, AuthProvider } from "../domain/UserProfile";

const userRepository = new UserRepository();

function resolveAuthProvider(providerData: { providerId: string }[]): AuthProvider {
  const providerId = providerData[0]?.providerId;
  if (providerId === "google.com") return "google";
  if (providerId === "apple.com") return "apple";
  if (providerId === "password") return "email";
  return "anonymous";
}

/** Creates the `users/{uid}` profile doc as soon as a Firebase Auth user exists. */
export const onUserCreate = functionsV1.auth.user().onCreate(async (user) => {
  const now = Timestamp.now();
  const profile: UserProfile = {
    uid: user.uid,
    displayName: user.displayName ?? null,
    email: user.email ?? null,
    photoURL: user.photoURL ?? null,
    authProvider: resolveAuthProvider(user.providerData),
    createdAt: now,
    updatedAt: now,
    lastActiveAt: now,
  };
  await userRepository.createProfile(profile);
});
