"use client";

import React, { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Sparkles,
  Lock,
  Mail,
  Eye,
  EyeOff,
  AlertCircle,
  Shield,
  KeyRound,
  ArrowRight,
  Info,
  Loader2,
} from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { DEFAULT_ADMIN_CREDENTIALS } from "@/lib/auth";
import { Button } from "@/components/ui/Button";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { login, isAuthenticated, isLoading: authLoading } = useAuth();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // If already authenticated, redirect to dashboard
  useEffect(() => {
    if (!authLoading && isAuthenticated) {
      const redirectUrl = searchParams.get("redirect") || "/admin/dashboard";
      router.push(redirectUrl);
    }
  }, [authLoading, isAuthenticated, router, searchParams]);

  // Pre-fill demo credentials on button click for ease of testing
  const fillDemoCredentials = () => {
    setEmail(DEFAULT_ADMIN_CREDENTIALS.email);
    setPassword(DEFAULT_ADMIN_CREDENTIALS.password);
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Client-side validation
    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setError("Please enter your admin email address.");
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      setError("Please enter a valid email format (e.g., admin@gmail.com).");
      return;
    }

    if (!password) {
      setError("Please enter your admin password.");
      return;
    }

    setIsSubmitting(true);
    try {
      const result = await login({
        email: trimmedEmail,
        password,
        rememberMe,
      });

      if (result.success) {
        const redirectUrl = searchParams.get("redirect") || "/admin/dashboard";
        router.push(redirectUrl);
      } else {
        setError(result.error || "Authentication failed. Please verify credentials.");
      }
    } catch {
      setError("An unexpected error occurred. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-3xl p-6 sm:p-8 shadow-2xl backdrop-blur-xl">
      {/* Demo Credentials Quick Info Banner */}
      <div className="mb-6 p-3.5 bg-indigo-950/40 border border-indigo-500/30 rounded-2xl flex items-start justify-between gap-3 text-xs">
        <div className="flex items-start gap-2.5">
          <KeyRound className="w-4 h-4 text-indigo-400 flex-shrink-0 mt-0.5" />
          <div>
            <span className="font-semibold text-indigo-200">Default Demo Credentials</span>
            <p className="text-slate-300 mt-0.5">
              Email: <span className="font-mono text-white font-medium">admin@gmail.com</span>
              <br />
              Password: <span className="font-mono text-white font-medium">12345</span>
            </p>
          </div>
        </div>
        <button
          type="button"
          onClick={fillDemoCredentials}
          className="text-[11px] font-semibold text-indigo-400 hover:text-indigo-300 underline underline-offset-2 flex-shrink-0 transition-colors"
        >
          Fill Demo
        </button>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="mb-5 p-3.5 bg-rose-500/10 border border-rose-500/30 rounded-xl flex items-start gap-2.5 text-xs text-rose-400 animate-in fade-in slide-in-from-top-1 duration-200">
          <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5 text-rose-400" />
          <div className="flex-1 font-medium">{error}</div>
        </div>
      )}

      {/* Form */}
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Email Field */}
        <div className="space-y-1.5">
          <label
            htmlFor="email"
            className="block text-xs font-semibold text-slate-300"
          >
            Admin Email Address
          </label>
          <div className="relative">
            <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              id="email"
              type="email"
              placeholder="admin@gmail.com"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                if (error) setError(null);
              }}
              disabled={isSubmitting}
              className="w-full pl-10 pr-4 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all disabled:opacity-50"
              autoComplete="email"
              required
            />
          </div>
        </div>

        {/* Password Field */}
        <div className="space-y-1.5">
          <label
            htmlFor="password"
            className="block text-xs font-semibold text-slate-300"
          >
            Password
          </label>
          <div className="relative">
            <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              id="password"
              type={showPassword ? "text" : "password"}
              placeholder="••••••••"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                if (error) setError(null);
              }}
              disabled={isSubmitting}
              className="w-full pl-10 pr-11 py-2.5 bg-slate-800/80 border border-slate-700 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all disabled:opacity-50"
              autoComplete="current-password"
              required
            />
            <button
              type="button"
              onClick={() => setShowPassword((prev) => !prev)}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-200 p-1 focus:outline-none transition-colors"
              aria-label={showPassword ? "Hide password" : "Show password"}
            >
              {showPassword ? (
                <EyeOff className="w-4 h-4" />
              ) : (
                <Eye className="w-4 h-4" />
              )}
            </button>
          </div>
        </div>

        {/* Remember Me & Help */}
        <div className="flex items-center justify-between pt-1">
          <label className="flex items-center gap-2 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              className="w-4 h-4 rounded bg-slate-800 border-slate-700 text-indigo-600 focus:ring-indigo-500 focus:ring-offset-slate-900"
            />
            <span className="text-xs text-slate-400 hover:text-slate-300">
              Remember me for 30 days
            </span>
          </label>

          <span className="text-xs text-slate-400 flex items-center gap-1">
            <Shield className="w-3 h-3 text-indigo-400" />
            Protected Area
          </span>
        </div>

        {/* Submit Button */}
        <div className="pt-2">
          <Button
            type="submit"
            variant="primary"
            size="lg"
            className="w-full font-semibold"
            isLoading={isSubmitting}
            rightIcon={<ArrowRight className="w-4 h-4" />}
          >
            {isSubmitting ? "Signing in..." : "Sign In to Dashboard"}
          </Button>
        </div>
      </form>
    </div>
  );
}

export default function AdminLoginPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-slate-900 via-slate-950 to-black text-slate-100 relative overflow-hidden">
      {/* Background ambient glowing spheres */}
      <div className="absolute top-1/4 -left-20 w-96 h-96 bg-indigo-600/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 -right-20 w-96 h-96 bg-purple-600/10 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        {/* Brand Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 via-indigo-600 to-purple-600 shadow-xl shadow-indigo-500/25 mb-4 border border-indigo-400/30">
            <Sparkles className="w-8 h-8 text-white animate-pulse" />
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
            Gaga Housie Admin
          </h1>
          <p className="text-xs sm:text-sm text-slate-400 mt-1.5">
            Sign in to access the gaming management portal
          </p>
        </div>

        {/* Form wrapped in Suspense */}
        <Suspense
          fallback={
            <div className="bg-slate-900/90 border border-slate-800 rounded-3xl p-8 flex items-center justify-center min-h-[300px]">
              <Loader2 className="w-8 h-8 animate-spin text-indigo-500" />
            </div>
          }
        >
          <LoginForm />
        </Suspense>

        {/* Footer info */}
        <div className="text-center mt-6 text-xs text-slate-400 flex items-center justify-center gap-1.5">
          <Info className="w-3.5 h-3.5" />
          <span>Gaga Housie Admin Portal • v1.0.0 (Local Mock Auth)</span>
        </div>
      </div>
    </div>
  );
}
