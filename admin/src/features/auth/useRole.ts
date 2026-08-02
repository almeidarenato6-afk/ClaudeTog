import { useAuth } from "./AuthContext";
import { canMutate, isAdmin } from "@/lib/api/auth";
import type { StaffRole } from "@/lib/api/types";

/**
 * Central place for role-gated UI decisions. `viewer` is read-only
 * everywhere: mutate buttons (create/edit/delete/send/toggle) must check
 * `canWrite` before rendering, not just before submitting.
 */
export function useRole() {
  const { staff } = useAuth();
  const role: StaffRole | null = staff?.claims.role ?? null;

  return {
    role,
    canWrite: role ? canMutate(role) : false,
    isAdmin: role ? isAdmin(role) : false,
  };
}
