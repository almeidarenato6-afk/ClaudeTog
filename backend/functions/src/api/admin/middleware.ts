import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { Role } from "../../domain/UserProfile";

/**
 * Lança um erro se quem chamou não estiver autenticado ou não carregar um dos
 * `allowedRoles` como sua custom claim `role`. Chame isso como a primeira coisa
 * em todo callable de painel admin — endpoints admin que fazem mutação nunca
 * devem confiar em checagens do lado do cliente.
 */
export function requireRole(request: CallableRequest, allowedRoles: Role[]): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Sign-in required.");
  }
  const role = request.auth?.token.role as Role | undefined;
  if (!role || !allowedRoles.includes(role)) {
    throw new HttpsError(
      "permission-denied",
      `Requires one of roles [${allowedRoles.join(", ")}].`
    );
  }
  return uid;
}

/** Atalho para a checagem comum de "precisa poder alterar conteúdo". */
export function requireContentManager(request: CallableRequest): string {
  return requireRole(request, ["admin", "content_manager"]);
}

/** Atalho para mutações restritas a admin (papéis, notificações, promoções). */
export function requireAdmin(request: CallableRequest): string {
  return requireRole(request, ["admin"]);
}
