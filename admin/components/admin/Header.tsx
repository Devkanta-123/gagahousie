"use client";

import React, { useState, useRef, useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import {
  Menu,
  Search,
  Bell,
  CheckCircle2,
  LogOut,
  User,
  Settings,
  ChevronDown,
  Sparkles,
  RefreshCw,
  Trophy,
  CreditCard,
  Gamepad2,
} from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { ADMIN_NOTIFICATIONS, NotificationItem } from "@/lib/mock-data";

interface HeaderProps {
  onToggleSidebar: () => void;
  isCollapsed: boolean;
}

const ROUTE_TITLES: Record<string, { title: string; subtitle: string }> = {
  "/admin/dashboard": {
    title: "Admin Dashboard",
    subtitle: "Real-time overview of gaming metrics and live operations",
  },
  "/admin/games": {
    title: "Games Management",
    subtitle: "Create, schedule, monitor and control Housie game rooms",
  },
  "/admin/players": {
    title: "Players Directory",
    subtitle: "Manage registered users, wallet balances, and KYC verification",
  },
  "/admin/boards": {
    title: "Housie Boards & Live Calls",
    subtitle: "Inspect active 1-90 number callers and ticket distribution",
  },
  "/admin/winners": {
    title: "Winners & Claims",
    subtitle: "Verify prize claims for Early 5, Lines, and Full House",
  },
  "/admin/transactions": {
    title: "Transactions Ledger",
    subtitle: "Audit deposits, ticket purchases, withdrawals, and payouts",
  },
  "/admin/reports": {
    title: "Reports & Analytics",
    subtitle: "Revenue breakdown, player retention, and game volume charts",
  },
  "/admin/settings": {
    title: "System Settings",
    subtitle: "Configure game rules, prize percentages, and admin preferences",
  },
};

export function Header({ onToggleSidebar }: HeaderProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout } = useAuth();

  const [searchQuery, setSearchQuery] = useState("");
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [notifications, setNotifications] = useState<NotificationItem[]>(ADMIN_NOTIFICATIONS);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  const unreadCount = notifications.filter((n) => !n.read).length;

  const currentRouteMeta =
    ROUTE_TITLES[pathname] || {
      title: "Admin Management",
      subtitle: "Gaga Housie Gaming Platform Administration",
    };

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        setShowNotifications(false);
      }
      if (profileRef.current && !profileRef.current.contains(event.target as Node)) {
        setShowProfileMenu(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleMarkAllRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const handleRefresh = () => {
    setIsRefreshing(true);
    setTimeout(() => {
      setIsRefreshing(false);
    }, 600);
  };

  const getNotifIcon = (type: NotificationItem["type"]) => {
    switch (type) {
      case "winner":
        return <Trophy className="w-4 h-4 text-amber-400" />;
      case "payment":
        return <CreditCard className="w-4 h-4 text-emerald-400" />;
      case "game":
        return <Gamepad2 className="w-4 h-4 text-indigo-400" />;
      default:
        return <Sparkles className="w-4 h-4 text-blue-400" />;
    }
  };

  return (
    <header className="sticky top-0 z-30 h-16 bg-slate-900/90 backdrop-blur-md border-b border-slate-800 px-4 lg:px-6 flex items-center justify-between gap-4">
      {/* Left side: Toggle button & Current Page Title */}
      <div className="flex items-center gap-3 min-w-0">
        <button
          onClick={onToggleSidebar}
          className="p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors"
          aria-label="Toggle navigation sidebar"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div className="flex flex-col min-w-0">
          <h1 className="text-base lg:text-lg font-bold text-white tracking-tight truncate flex items-center gap-2">
            {currentRouteMeta.title}
          </h1>
          <p className="text-xs text-slate-400 hidden sm:block truncate">
            {currentRouteMeta.subtitle}
          </p>
        </div>
      </div>

      {/* Right side: Search UI, Quick Actions, Notification, Profile */}
      <div className="flex items-center gap-2 lg:gap-3 flex-shrink-0">
        {/* Search Bar */}
        <div className="relative hidden md:block w-56 lg:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            placeholder="Search games, players, IDs..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-8 py-1.5 bg-slate-800/80 border border-slate-700 text-xs text-slate-200 placeholder-slate-400 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all"
          />
          {searchQuery && (
            <button
              onClick={() => setSearchQuery("")}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white text-xs"
            >
              ×
            </button>
          )}
        </div>

        {/* Refresh button */}
        <button
          onClick={handleRefresh}
          className={`p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 focus:outline-none transition-all ${
            isRefreshing ? "rotate-180" : ""
          }`}
          title="Refresh live data"
        >
          <RefreshCw className={`w-4 h-4 ${isRefreshing ? "animate-spin text-indigo-400" : ""}`} />
        </button>

        {/* Notifications Dropdown */}
        <div className="relative" ref={notifRef}>
          <button
            onClick={() => setShowNotifications((prev) => !prev)}
            className="relative p-2 rounded-xl text-slate-400 hover:text-white hover:bg-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors"
            aria-label="View notifications"
          >
            <Bell className="w-5 h-5" />
            {unreadCount > 0 && (
              <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-rose-500 rounded-full ring-2 ring-slate-900 animate-pulse" />
            )}
          </button>

          {/* Notifications Flyout */}
          {showNotifications && (
            <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl overflow-hidden z-50 animate-in fade-in zoom-in-95 duration-150">
              <div className="p-3.5 border-b border-slate-800 flex items-center justify-between bg-slate-800/40">
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-sm text-white">Notifications</span>
                  {unreadCount > 0 && (
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                      {unreadCount} new
                    </span>
                  )}
                </div>
                {unreadCount > 0 && (
                  <button
                    onClick={handleMarkAllRead}
                    className="text-xs text-indigo-400 hover:text-indigo-300 transition-colors"
                  >
                    Mark all read
                  </button>
                )}
              </div>

              <div className="max-h-80 overflow-y-auto divide-y divide-slate-800/50">
                {notifications.length === 0 ? (
                  <div className="p-6 text-center text-xs text-slate-400">
                    No new notifications
                  </div>
                ) : (
                  notifications.map((notif) => (
                    <div
                      key={notif.id}
                      className={`p-3.5 flex gap-3 hover:bg-slate-800/50 transition-colors cursor-pointer ${
                        !notif.read ? "bg-indigo-950/20" : ""
                      }`}
                      onClick={() => {
                        setNotifications((prev) =>
                          prev.map((n) => (n.id === notif.id ? { ...n, read: true } : n))
                        );
                      }}
                    >
                      <div className="w-8 h-8 rounded-lg bg-slate-800 flex items-center justify-center flex-shrink-0 mt-0.5 border border-slate-700">
                        {getNotifIcon(notif.type)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center justify-between">
                          <p className="text-xs font-semibold text-slate-200 truncate">
                            {notif.title}
                          </p>
                          <span className="text-[10px] text-slate-400 flex-shrink-0 ml-2">
                            {notif.timestamp}
                          </span>
                        </div>
                        <p className="text-xs text-slate-400 mt-0.5 line-clamp-2">
                          {notif.message}
                        </p>
                      </div>
                      {!notif.read && (
                        <div className="w-2 h-2 rounded-full bg-indigo-500 self-center flex-shrink-0" />
                      )}
                    </div>
                  ))
                )}
              </div>

              <div className="p-2 border-t border-slate-800 bg-slate-900/90 text-center">
                <button
                  onClick={() => setShowNotifications(false)}
                  className="text-xs text-slate-400 hover:text-slate-200 transition-colors py-1"
                >
                  Close notifications
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Vertical Divider */}
        <div className="h-6 w-px bg-slate-800 hidden sm:block" />

        {/* Admin Profile Dropdown */}
        <div className="relative" ref={profileRef}>
          <button
            onClick={() => setShowProfileMenu((prev) => !prev)}
            className="flex items-center gap-2.5 p-1.5 pl-2 rounded-xl bg-slate-800/50 hover:bg-slate-800 border border-slate-700/60 transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-indigo-500 via-indigo-600 to-purple-600 flex items-center justify-center font-bold text-white text-xs shadow-md">
              {user?.name ? user.name.charAt(0) : "A"}
            </div>
            <div className="text-left hidden sm:block">
              <p className="text-xs font-semibold text-white leading-tight">
                {user?.name || "Administrator"}
              </p>
              <p className="text-[10px] text-slate-400 font-medium">
                {user?.role || "Super Admin"}
              </p>
            </div>
            <ChevronDown className="w-3.5 h-3.5 text-slate-400 hidden sm:block" />
          </button>

          {/* Profile Dropdown Menu */}
          {showProfileMenu && (
            <div className="absolute right-0 mt-2 w-56 bg-slate-900 border border-slate-800 rounded-2xl shadow-2xl p-2 z-50 animate-in fade-in zoom-in-95 duration-150">
              <div className="px-3 py-2.5 border-b border-slate-800 mb-1 bg-slate-800/30 rounded-xl">
                <p className="text-xs font-bold text-white">{user?.name || "Administrator"}</p>
                <p className="text-[11px] text-slate-400 truncate">{user?.email || "admin@gmail.com"}</p>
                <div className="mt-1.5 inline-flex items-center gap-1 text-[10px] text-emerald-400 font-semibold bg-emerald-500/10 px-2 py-0.5 rounded-md border border-emerald-500/20">
                  <CheckCircle2 className="w-3 h-3" />
                  Authenticated Admin
                </div>
              </div>

              <div className="space-y-0.5">
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    router.push("/admin/settings");
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-300 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
                >
                  <User className="w-4 h-4 text-slate-400" />
                  Admin Profile
                </button>
                <button
                  onClick={() => {
                    setShowProfileMenu(false);
                    router.push("/admin/settings");
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-slate-300 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
                >
                  <Settings className="w-4 h-4 text-slate-400" />
                  System Settings
                </button>
              </div>

              <div className="border-t border-slate-800 my-1 pt-1">
                <button
                  onClick={async () => {
                    setShowProfileMenu(false);
                    if (confirm("Are you sure you want to log out?")) {
                      await logout();
                    }
                  }}
                  className="w-full flex items-center gap-2.5 px-3 py-2 text-xs font-medium text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 rounded-lg transition-colors"
                >
                  <LogOut className="w-4 h-4" />
                  Sign Out
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
