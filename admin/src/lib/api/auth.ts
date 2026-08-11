import {
  onIdTokenChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
  type User,
} from "firebase/auth";
import { auth } from "@/lib/firebase";
import type { StaffClaims, StaffRole } from "./types";

export interface AuthedStaff {
  user: User;
  claims: StaffClaims;
}

/** Espera-se que as Cloud Functions definam esse custom claim nas contas de staff. */
const ROLE_CLAIM_KEY = "role";

function parseRole(raw: unknown): StaffRole | null {
  return raw === "admin" || raw === "content_manager" || raw === "viewer"
    ? raw
    : null;
}

export async function signIn(email: string, password: string) {
  const credential = await signInWithEmailAndPassword(auth, email, password);
  return credential.user;
}

export async function signOut() {
  await firebaseSignOut(auth);
}

/**
 * Assina mudanças de autenticação + custom claim. Dispara `null` quando
 * deslogado, ou quando logado mas sem um claim `role` válido (ou seja, não
 * é staff) — quem chamar deve tratar isso como "não autorizado", não como
 * "carregando".
 */
export function subscribeAuthedStaff(
  callback: (staff: AuthedStaff | null) => void,
) {
  return onIdTokenChanged(auth, async (user) => {
    if (!user) {
      callback(null);
      return;
    }
    const tokenResult = await user.getIdTokenResult();
    const role = parseRole(tokenResult.claims[ROLE_CLAIM_KEY]);
    if (!role) {
      callback(null);
      return;
    }
    callback({ user, claims: { role } });
  });
}

export function canMutate(role: StaffRole): boolean {
  return role === "admin" || role === "content_manager";
}

export function isAdmin(role: StaffRole): boolean {
  return role === "admin";
}
