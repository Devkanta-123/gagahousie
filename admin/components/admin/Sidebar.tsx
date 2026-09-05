"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Gamepad2,
  Users,
  Grid3X3,
  Trophy,
  ArrowLeftRight,
  BarChart3,
  Settings,
  LogOut,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  Shield,
  X,
} from "lucide-react";
import { useAuth } from "@/lib/auth-context";

interface SidebarProps {
  isCollapsed: boolean;
  setIsCollapsed: React.Dispatch<React.SetStateAction<boolean>>;
  isMobileOpen: boolean;
  setIsMobileOpen: React.Dispatch<React.SetStateAction<boolean>>;
}

interface NavItem {
  label: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badge?: string;
}

const NAV_ITEMS: NavItem[] = [
  {
    label: "Dashboard",
    href: "/admin/dashboard",
    icon: LayoutDashboard,
  },
  {
    label: "Games",
    href: "/admin/games",
    icon: Gamepad2,
    badge: "12 Live",
  },
  {
    label: "Players",
    href: "/admin/players",
    icon: Users,
  },
  {
    label: "Housie Boards",
    href: "/admin/boards",
    icon: Grid3X3,
  },
  {
    label: "Winners",
    href: "/admin/winners",
    icon: Trophy,
    badge: "New",
  },
  {
    label: "Transactions",
    href: "/admin/transactions",
    icon: ArrowLeftRight,
  },
  {
    label: "Reports",
    href: "/admin/reports",
    icon: BarChart3,
  },
  {
    label: "Settings",
    href: "/admin/settings",
    icon: Settings,
  },
];

export function Sidebar({
  isCollapsed,
  setIsCollapsed,
  isMobileOpen,
  setIsMobileOpen,
}: SidebarProps) {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  const handleLogout = async () => {
    if (confirm("Are you sure you want to sign out of Admin Panel?")) {
      await logout();
    }
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isMobileOpen && (
        <div
          className="fixed inset-0 bg-black/70 backdrop-blur-sm z-40 lg:hidden transition-opacity duration-300"
          onClick={() => setIsMobileOpen(false)}
          aria-hidden="true"
        />
      )}

      {/* Sidebar Container */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 flex flex-col bg-slate-900 border-r border-slate-800 text-slate-200 transition-all duration-300 ease-in-out
          ${isMobileOpen ? "translate-x-0" : "-translate-x-full lg:translate-x-0"}
          ${isCollapsed ? "lg:w-20" : "lg:w-64"}
          w-72 shadow-2xl lg:shadow-none
        `}
      >
        {/* Sidebar Header / Brand */}
        <div className="h-16 flex items-center justify-between px-4 border-b border-slate-800/80 bg-slate-900/50">
          <Link
            href="/admin/dashboard"
            className="flex items-center gap-3 overflow-hidden group focus:outline-none"
            onClick={() => setIsMobileOpen(false)}
          >
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 via-indigo-600 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/25 flex-shrink-0 group-hover:scale-105 transition-transform">
              <Sparkles className="w-5 h-5 text-white animate-pulse" />
            </div>
            {(!isCollapsed || isMobileOpen) && (
              <div className="flex flex-col truncate">
                <span className="font-bold text-base tracking-tight text-white flex items-center gap-1.5">
                  Gaga Housie
                  <span className="text-[10px] uppercase font-semibold px-1.5 py-0.5 rounded bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                    Admin
                  </span>
                </span>
                <span className="text-xs text-slate-400 truncate">
                  Gaming Control Hub
                </span>
              </div>
            )}
          </Link>

          {/* Mobile close button */}
          <button
            onClick={() => setIsMobileOpen(false)}
            className="lg:hidden p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 focus:outline-none"
            aria-label="Close sidebar"
          >
            <X className="w-5 h-5" />
          </button>

          {/* Desktop collapse toggle button */}
          <button
            onClick={() => setIsCollapsed((prev) => !prev)}
            className="hidden lg:flex p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-slate-800 focus:outline-none transition-colors"
            title={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
            aria-label={isCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {isCollapsed ? (
              <ChevronRight className="w-4 h-4" />
            ) : (
              <ChevronLeft className="w-4 h-4" />
            )}
          </button>
        </div>

        {/* Navigation Menu */}
        <div className="flex-1 overflow-y-auto py-4 px-3 space-y-1.5 custom-scrollbar">
          <div className="px-3 pb-2">
            {(!isCollapsed || isMobileOpen) && (
              <p className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
                Menu Management
              </p>
            )}
          </div>

          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive =
              pathname === item.href ||
              (item.href !== "/admin/dashboard" && pathname.startsWith(item.href));

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setIsMobileOpen(false)}
                title={isCollapsed && !isMobileOpen ? item.label : undefined}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 group relative
                  ${
                    isActive
                      ? "bg-gradient-to-r from-indigo-600/90 to-indigo-700/70 text-white shadow-md shadow-indigo-600/20 border border-indigo-500/30"
                      : "text-slate-400 hover:text-slate-100 hover:bg-slate-800/60"
                  }
                  ${isCollapsed && !isMobileOpen ? "justify-center px-2" : ""}
                `}
              >
                <Icon
                  className={`w-5 h-5 flex-shrink-0 transition-transform group-hover:scale-110 ${
                    isActive ? "text-white" : "text-slate-400 group-hover:text-slate-200"
                  }`}
                />

                {(!isCollapsed || isMobileOpen) && (
                  <span className="truncate flex-1">{item.label}</span>
                )}

                {(!isCollapsed || isMobileOpen) && item.badge && (
                  <span
                    className={`text-[10px] font-semibold px-2 py-0.5 rounded-full ${
                      item.badge.includes("Live")
                        ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30"
                        : "bg-indigo-500/20 text-indigo-300 border border-indigo-500/30"
                    }`}
                  >
                    {item.badge}
                  </span>
                )}

                {/* Tooltip for collapsed desktop mode */}
                {isCollapsed && !isMobileOpen && (
                  <div className="absolute left-full ml-3 px-2.5 py-1 bg-slate-800 text-white text-xs rounded-md shadow-xl whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50 border border-slate-700">
                    {item.label}
                  </div>
                )}
              </Link>
            );
          })}
        </div>

        {/* Admin Profile & Logout Section at Bottom */}
        <div className="p-3 border-t border-slate-800 bg-slate-900/90 space-y-2">
          {/* Admin Profile Card */}
          <div
            className={`flex items-center gap-3 p-2 rounded-xl bg-slate-800/40 border border-slate-800 transition-colors
              ${isCollapsed && !isMobileOpen ? "justify-center p-1.5" : ""}
            `}
          >
            <div className="relative flex-shrink-0">
              <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-600 flex items-center justify-center font-bold text-white shadow-inner text-sm">
                {user?.name ? user.name.charAt(0) : "A"}
              </div>
              <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-emerald-500 ring-2 ring-slate-900" />
            </div>

            {(!isCollapsed || isMobileOpen) && (
              <div className="flex flex-col min-w-0 flex-1">
                <span className="text-sm font-semibold text-white truncate">
                  {user?.name || "Administrator"}
                </span>
                <span className="text-xs text-slate-400 truncate flex items-center gap-1">
                  <Shield className="w-3 h-3 text-indigo-400" />
                  {user?.role || "Super Admin"}
                </span>
              </div>
            )}
          </div>

          {/* Logout Button */}
          <button
            onClick={handleLogout}
            title={isCollapsed && !isMobileOpen ? "Logout" : undefined}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 border border-transparent hover:border-rose-500/20 transition-all duration-200 group
              ${isCollapsed && !isMobileOpen ? "justify-center px-2" : ""}
            `}
          >
            <LogOut className="w-5 h-5 flex-shrink-0 transition-transform group-hover:-translate-x-0.5" />
            {(!isCollapsed || isMobileOpen) && <span>Logout</span>}
          </button>
        </div>
      </aside>
    </>
  );
}
