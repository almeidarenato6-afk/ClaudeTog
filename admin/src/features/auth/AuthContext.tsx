import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { subscribeAuthedStaff, type AuthedStaff } from "@/lib/api/auth";

interface AuthState {
  status: "loading" | "authed" | "unauthed";
  staff: AuthedStaff | null;
}

const AuthContext = createContext<AuthState>({
  status: "loading",
  staff: null,
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({
    status: "loading",
    staff: null,
  });

  useEffect(() => {
    return subscribeAuthedStaff((staff) => {
      setState({ status: staff ? "authed" : "unauthed", staff });
    });
  }, []);

  return <AuthContext.Provider value={state}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
