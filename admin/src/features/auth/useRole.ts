import { useAuth } from "./AuthContext";
import { canMutate, isAdmin } from "@/lib/api/auth";
import type { StaffRole } from "@/lib/api/types";

/**
 * Local centralizado para decisões de UI baseadas em papel. `viewer` é
 * somente leitura em todo lugar: botões de mutação (criar/editar/excluir/
 * enviar/ativar) precisam checar `canWrite` antes de renderizar, não só
 * antes de submeter.
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
