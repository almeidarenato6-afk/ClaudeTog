import { Timestamp } from "firebase-admin/firestore";

export type AuthProvider = "google" | "apple" | "email" | "anonymous";

/**
 * Firestore: `users/{uid}`
 * Leitura/escrita restrita ao dono (veja firestore.rules).
 *
 * Deliberadamente NÃO carrega um campo `role` de painel admin. Os papéis vivem
 * apenas como custom claims do Firebase Auth (`request.auth.token.role`),
 * definidas exclusivamente por Cloud Functions com o Admin SDK — espelhar o
 * papel em um documento gravável pelo cliente abriria um caminho trivial de
 * escalonamento de privilégio.
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

/** Papéis são apenas custom claims — veja o comentário acima. Mantido aqui como a fonte única da verdade para os valores válidos. */
export type Role = "admin" | "content_manager" | "viewer";
export const ROLES: readonly Role[] = ["admin", "content_manager", "viewer"];
