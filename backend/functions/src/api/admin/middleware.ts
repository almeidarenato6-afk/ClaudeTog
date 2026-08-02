import { CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { Role } from "../../domain/UserProfile";

/**
 * Throws if the caller isn't authenticated or doesn't carry one of `allowedRoles`
 * as their `role` custom claim. Call this first thing in every admin-panel
 * callable — mutating admin endpoints must never rely on client-side checks.
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

/** Shorthand for the common "must be able to mutate content" check. */
export function requireContentManager(request: CallableRequest): string {
  return requireRole(request, ["admin", "content_manager"]);
}

/** Shorthand for admin-only mutations (roles, notifications, promotions). */
export function requireAdmin(request: CallableRequest): string {
  return requireRole(request, ["admin"]);
}
