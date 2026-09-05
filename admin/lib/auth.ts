/**
 * Authentication Module for Gaga Housie Admin Panel
 * 
 * TEMPORARY MOCK AUTHENTICATION IMPLEMENTATION
 * --------------------------------------------
 * This module handles authentication using a mock session stored in secure cookies
 * and browser storage.
 * 
 * FUTURE SUPABASE INTEGRATION:
 * When ready to integrate Supabase, replace the internal implementation of these
 * functions with Supabase Auth calls (e.g., supabase.auth.signInWithPassword,
 * supabase.auth.signOut, supabase.auth.getSession) without modifying the consumer
 * components or pages.
 */

export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: string;
  avatar?: string;
  lastLogin?: string;
}

export interface AuthSession {
  token: string;
  user: AdminUser;
  expiresAt: number;
  rememberMe: boolean;
}

export interface LoginCredentials {
  email: string;
  password: string;
  rememberMe?: boolean;
}

export interface AuthResponse {
  success: boolean;
  session?: AuthSession;
  error?: string;
}

// Temporary default admin credentials
export const DEFAULT_ADMIN_CREDENTIALS = {
  email: "admin@gmail.com",
  password: "12345",
};

export const MOCK_ADMIN_USER: AdminUser = {
  id: "admin_001",
  name: "Administrator",
  email: "admin@gmail.com",
  role: "Super Admin",
  lastLogin: new Date().toISOString(),
};

const SESSION_COOKIE_NAME = "gaga_admin_session";
const SESSION_STORAGE_KEY = "gaga_housie_admin_session";

/**
 * Helper to set cookie in browser
 */
function setCookie(name: string, value: string, days: number = 7) {
  if (typeof document === "undefined") return;
  const date = new Date();
  date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
  const expires = "; expires=" + date.toUTCString();
  document.cookie = `${name}=${encodeURIComponent(value)}${expires}; path=/; SameSite=Lax`;
}

/**
 * Helper to delete cookie
 */
function deleteCookie(name: string) {
  if (typeof document === "undefined") return;
  document.cookie = `${name}=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT; SameSite=Lax`;
}

/**
 * Helper to get cookie by name
 */
function getCookie(name: string): string | null {
  if (typeof document === "undefined") return null;
  const nameEQ = name + "=";
  const ca = document.cookie.split(";");
  for (let i = 0; i < ca.length; i++) {
    let c = ca[i];
    while (c.charAt(0) === " ") c = c.substring(1, c.length);
    if (c.indexOf(nameEQ) === 0) {
      return decodeURIComponent(c.substring(nameEQ.length, c.length));
    }
  }
  return null;
}

/**
 * Authenticate admin with credentials
 */
export async function loginWithCredentials(
  credentials: LoginCredentials
): Promise<AuthResponse> {
  // Simulate network latency for realistic UX
  await new Promise((resolve) => setTimeout(resolve, 600));

  const trimmedEmail = credentials.email.trim().toLowerCase();
  const trimmedPassword = credentials.password.trim();

  // Validate presence
  if (!trimmedEmail || !trimmedPassword) {
    return {
      success: false,
      error: "Please enter both email address and password.",
    };
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(trimmedEmail)) {
    return {
      success: false,
      error: "Please enter a valid email address format.",
    };
  }

  // Verify against mock credentials
  if (
    trimmedEmail === DEFAULT_ADMIN_CREDENTIALS.email.toLowerCase() &&
    trimmedPassword === DEFAULT_ADMIN_CREDENTIALS.password
  ) {
    const expiresDays = credentials.rememberMe ? 30 : 1;
    const expiresAt = Date.now() + expiresDays * 24 * 60 * 60 * 1000;

    const session: AuthSession = {
      token: `mock_admin_token_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
      user: {
        ...MOCK_ADMIN_USER,
        lastLogin: new Date().toISOString(),
      },
      expiresAt,
      rememberMe: Boolean(credentials.rememberMe),
    };

    // Save session in cookie and localStorage
    if (typeof window !== "undefined") {
      const sessionStr = JSON.stringify(session);
      setCookie(SESSION_COOKIE_NAME, sessionStr, expiresDays);
      try {
        localStorage.setItem(SESSION_STORAGE_KEY, sessionStr);
      } catch {
        // Ignore localStorage quota errors
      }
    }

    return {
      success: true,
      session,
    };
  }

  return {
    success: false,
    error: "Invalid email or password. Please check your credentials and try again.",
  };
}

/**
 * Get the current active session
 */
export function getCurrentSession(): AuthSession | null {
  if (typeof window === "undefined") return null;

  try {
    // Check cookie first
    const cookieData = getCookie(SESSION_COOKIE_NAME);
    if (cookieData) {
      const parsed: AuthSession = JSON.parse(cookieData);
      if (parsed.expiresAt && parsed.expiresAt > Date.now()) {
        return parsed;
      }
    }

    // Fallback to localStorage
    const localData = localStorage.getItem(SESSION_STORAGE_KEY);
    if (localData) {
      const parsed: AuthSession = JSON.parse(localData);
      if (parsed.expiresAt && parsed.expiresAt > Date.now()) {
        // Re-sync cookie
        setCookie(
          SESSION_COOKIE_NAME,
          localData,
          parsed.rememberMe ? 30 : 1
        );
        return parsed;
      }
    }
  } catch (err) {
    console.error("Error reading auth session:", err);
  }

  return null;
}

/**
 * Check if the current user is authenticated
 */
export function isAuthenticated(): boolean {
  const session = getCurrentSession();
  return session !== null;
}

/**
 * Logout the active user and clear session data
 */
export async function logoutUser(): Promise<void> {
  // Simulate quick network latency
  await new Promise((resolve) => setTimeout(resolve, 300));

  if (typeof window !== "undefined") {
    deleteCookie(SESSION_COOKIE_NAME);
    try {
      localStorage.removeItem(SESSION_STORAGE_KEY);
    } catch {
      // Ignore
    }
  }
}
