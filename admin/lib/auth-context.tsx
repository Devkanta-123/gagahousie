"use client";

import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
} from "react";
import { useRouter } from "next/navigation";
import {
  AdminUser,
  AuthSession,
  LoginCredentials,
  getCurrentSession,
  loginWithCredentials,
  logoutUser,
} from "./auth";

interface AuthContextType {
  user: AdminUser | null;
  session: AuthSession | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (credentials: LoginCredentials) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<AuthSession | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const router = useRouter();

  // Load session on initial mount
  useEffect(() => {
    try {
      const activeSession = getCurrentSession();
      if (activeSession) {
        setSession(activeSession);
      }
    } catch (e) {
      console.error("Auth context session initialization error:", e);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const login = useCallback(
    async (credentials: LoginCredentials) => {
      setIsLoading(true);
      try {
        const response = await loginWithCredentials(credentials);
        if (response.success && response.session) {
          setSession(response.session);
          return { success: true };
        } else {
          return { success: false, error: response.error || "Authentication failed" };
        }
      } catch {
        return {
          success: false,
          error: "An unexpected error occurred during login. Please try again.",
        };
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  const logout = useCallback(async () => {
    setIsLoading(true);
    try {
      await logoutUser();
      setSession(null);
      router.push("/admin/login");
    } finally {
      setIsLoading(false);
    }
  }, [router]);

  return (
    <AuthContext.Provider
      value={{
        user: session?.user || null,
        session,
        isLoading,
        isAuthenticated: !!session,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
