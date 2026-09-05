"use client";

import React, { useState, useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Sidebar } from "@/components/admin/Sidebar";
import { Header } from "@/components/admin/Header";
import { useAuth } from "@/lib/auth-context";
import { Loader2 } from "lucide-react";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { isAuthenticated, isLoading } = useAuth();

  const [isCollapsed, setIsCollapsed] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  // If on login page, render children directly without admin chrome
  const isLoginPage = pathname === "/admin/login";

  // Client-side authentication guard for admin routes
  useEffect(() => {
    if (!isLoading && !isAuthenticated && !isLoginPage) {
      router.push(`/admin/login?redirect=${encodeURIComponent(pathname)}`);
    }
  }, [isLoading, isAuthenticated, isLoginPage, router, pathname]);

  if (isLoginPage) {
    return <>{children}</>;
  }

  // Show loading spinner during initial session verification
  if (isLoading) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center gap-3 text-slate-400">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-500" />
        <span className="text-xs font-medium">Verifying admin session...</span>
      </div>
    );
  }

  if (!isAuthenticated) {
    return null; // Will redirect via useEffect
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col">
      {/* Sidebar Navigation */}
      <Sidebar
        isCollapsed={isCollapsed}
        setIsCollapsed={setIsCollapsed}
        isMobileOpen={isMobileOpen}
        setIsMobileOpen={setIsMobileOpen}
      />

      {/* Main Content Area */}
      <div
        className={`flex-1 flex flex-col transition-all duration-300 ease-in-out ${
          isCollapsed ? "lg:pl-20" : "lg:pl-64"
        }`}
      >
        {/* Top Header */}
        <Header
          onToggleSidebar={() => {
            if (window.innerWidth < 1024) {
              setIsMobileOpen((prev) => !prev);
            } else {
              setIsCollapsed((prev) => !prev);
            }
          }}
          isCollapsed={isCollapsed}
        />

        {/* Dynamic Page Content */}
        <main className="flex-1 p-4 sm:p-6 lg:p-8 max-w-7xl w-full mx-auto space-y-6">
          {children}
        </main>

        {/* Global Admin Footer */}
        <footer className="mt-auto border-t border-slate-800/80 py-4 px-6 text-center text-xs text-slate-400 flex flex-col sm:flex-row items-center justify-between gap-2">
          <span>Gaga Housie Admin Portal © {new Date().getFullYear()}</span>
          <span className="text-slate-400">
            Internal Platform Management • Mock Mode (Ready for Supabase)
          </span>
        </footer>
      </div>
    </div>
  );
}
