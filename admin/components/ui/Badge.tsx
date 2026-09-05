import React from "react";

export type BadgeVariant =
  | "active"
  | "completed"
  | "upcoming"
  | "cancelled"
  | "verified"
  | "pending"
  | "suspended"
  | "indigo"
  | "emerald"
  | "amber"
  | "rose"
  | "blue"
  | "purple"
  | "slate";

interface BadgeProps {
  children: React.ReactNode;
  variant?: BadgeVariant | string;
  className?: string;
  dot?: boolean;
}

export function Badge({
  children,
  variant = "slate",
  className = "",
  dot = false,
}: BadgeProps) {
  const normalized = (variant || "slate").toString().toLowerCase();

  let styles = "bg-slate-800 text-slate-300 border-slate-700";
  let dotColor = "bg-slate-400";

  switch (normalized) {
    case "active":
    case "emerald":
      styles = "bg-emerald-500/10 text-emerald-400 border-emerald-500/30";
      dotColor = "bg-emerald-400 animate-pulse";
      break;
    case "completed":
    case "blue":
      styles = "bg-blue-500/10 text-blue-400 border-blue-500/30";
      dotColor = "bg-blue-400";
      break;
    case "upcoming":
    case "amber":
    case "pending":
    case "pending kyc":
      styles = "bg-amber-500/10 text-amber-400 border-amber-500/30";
      dotColor = "bg-amber-400";
      break;
    case "cancelled":
    case "suspended":
    case "rose":
    case "failed":
      styles = "bg-rose-500/10 text-rose-400 border-rose-500/30";
      dotColor = "bg-rose-400";
      break;
    case "kyc verified":
    case "verified":
    case "indigo":
      styles = "bg-indigo-500/10 text-indigo-400 border-indigo-500/30";
      dotColor = "bg-indigo-400";
      break;
    case "purple":
      styles = "bg-purple-500/10 text-purple-400 border-purple-500/30";
      dotColor = "bg-purple-400";
      break;
  }

  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium border transition-colors ${styles} ${className}`}
    >
      {dot && <span className={`w-1.5 h-1.5 rounded-full ${dotColor}`} />}
      {children}
    </span>
  );
}
