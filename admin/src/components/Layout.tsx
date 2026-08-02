import { NavLink, Outlet } from "react-router-dom";
import { useAuth } from "@/features/auth/AuthContext";
import { signOut } from "@/lib/api/auth";
import type { StaffRole } from "@/lib/api/types";

const NAV_ITEMS = [
  { to: "/", label: "Áudios", icon: "🎵", end: true },
  { to: "/categorias", label: "Categorias", icon: "🗂️" },
  { to: "/analytics", label: "Analytics", icon: "📊" },
  { to: "/notificacoes", label: "Notificações", icon: "🔔" },
  { to: "/promocoes", label: "Loja & Promoções", icon: "🏷️" },
];

const ROLE_LABEL: Record<StaffRole, string> = {
  admin: "Administrador",
  content_manager: "Gestor de conteúdo",
  viewer: "Visualização",
};

export function Layout() {
  const { staff } = useAuth();

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="flex w-60 shrink-0 flex-col border-r border-slate-200 bg-navy-950 text-white">
        <div className="flex items-center gap-2 px-5 py-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-coral-500 text-sm font-bold">
            VM
          </div>
          <div>
            <p className="text-sm font-semibold leading-tight">Vai Márcia</p>
            <p className="text-xs leading-tight text-navy-300">Painel Admin</p>
          </div>
        </div>

        <nav className="flex flex-1 flex-col gap-1 px-3 py-2">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                  isActive
                    ? "bg-coral-500 text-white"
                    : "text-navy-200 hover:bg-navy-800 hover:text-white"
                }`
              }
            >
              <span aria-hidden>{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="border-t border-navy-800 px-4 py-4 text-xs text-navy-300">
          Cores de marca são um placeholder até a definição visual oficial
          TogPlay.
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex items-center justify-between border-b border-slate-200 bg-white px-6 py-3">
          <div />
          <div className="flex items-center gap-3">
            {staff && (
              <div className="text-right">
                <p className="text-sm font-medium leading-tight text-slate-800">
                  {staff.user.email}
                </p>
                <p className="text-xs leading-tight text-slate-400">
                  {ROLE_LABEL[staff.claims.role]}
                </p>
              </div>
            )}
            <button
              onClick={() => signOut()}
              className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
            >
              Sair
            </button>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto px-6 py-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
