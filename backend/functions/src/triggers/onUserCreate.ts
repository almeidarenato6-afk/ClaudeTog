// O firebase-functions v2 ainda não expõe um trigger de auth `onCreate` não
// bloqueante (apenas os triggers de identidade bloqueantes `beforeUserCreated`/
// `beforeUserSignedIn` em v2/identity). Misturar o trigger de auth v1 em um
// codebase por outro lado v2 é a abordagem documentada até o Google lançar um
// equivalente v2.
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

/** Cria o doc de perfil `users/{uid}` assim que um usuário do Firebase Auth existe. */
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
