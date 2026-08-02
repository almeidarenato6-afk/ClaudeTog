import { useState, type FormEvent } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { signIn } from "@/lib/api/auth";
import { useAuth } from "./AuthContext";
import { Button } from "@/components/Button";
import { FormField } from "@/components/FormField";

export function LoginPage() {
  const { status } = useAuth();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (status === "authed") {
    const redirectTo =
      (location.state as { from?: Location } | null)?.from?.pathname ?? "/";
    return <Navigate to={redirectTo} replace />;
  }

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await signIn(email, password);
    } catch (err) {
      setError(
        "Não foi possível entrar. Verifique e-mail e senha e tente novamente.",
      );
      console.error(err);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-navy-950 px-4">
      <div className="w-full max-w-sm rounded-2xl bg-white p-8 shadow-xl">
        <div className="mb-6 flex flex-col items-center gap-2 text-center">
          <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-coral-500 text-xl font-bold text-white">
            VM
          </div>
          <h1 className="text-lg font-semibold text-slate-900">
            Vai Márcia · Admin
          </h1>
          <p className="text-sm text-slate-500">
            Acesso restrito à equipe TogPlay
          </p>
        </div>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <FormField label="E-mail" htmlFor="email">
            <input
              id="email"
              type="email"
              required
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-coral-500"
              placeholder="voce@togplay.com"
            />
          </FormField>

          <FormField label="Senha" htmlFor="password">
            <input
              id="password"
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-coral-500"
              placeholder="••••••••"
            />
          </FormField>

          {error && (
            <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </p>
          )}

          <Button type="submit" loading={submitting} className="mt-2 w-full">
            Entrar
          </Button>
        </form>

        <p className="mt-6 text-center text-xs text-slate-400">
          Sem acesso? Peça a um administrador para conceder seu papel
          (admin, content_manager ou viewer).
        </p>
      </div>
    </div>
  );
}
