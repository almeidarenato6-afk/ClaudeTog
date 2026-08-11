import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "./AuthContext";

/** Guarda de rota: redireciona para /login a menos que haja um claim de papel de staff válido. */
export function RequireStaff({ children }: { children: React.ReactNode }) {
  const { status } = useAuth();
  const location = useLocation();

  if (status === "loading") {
    return (
      <div className="flex h-screen items-center justify-center bg-slate-50">
        <div className="text-sm text-slate-400">Carregando…</div>
      </div>
    );
  }

  if (status === "unauthed") {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  return <>{children}</>;
}
