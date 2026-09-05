import React from "react";
import {
  Gamepad2,
  Activity,
  CheckCircle,
  Users,
  Calendar,
  IndianRupee,
  TrendingUp,
  TrendingDown,
} from "lucide-react";
import { StatItem } from "@/lib/mock-data";

interface StatCardProps {
  stat: StatItem;
}

export function StatCard({ stat }: StatCardProps) {
  const getIcon = () => {
    switch (stat.iconName) {
      case "gamepad":
        return <Gamepad2 className="w-5 h-5" />;
      case "activity":
        return <Activity className="w-5 h-5" />;
      case "check-circle":
        return <CheckCircle className="w-5 h-5" />;
      case "users":
        return <Users className="w-5 h-5" />;
      case "calendar":
        return <Calendar className="w-5 h-5" />;
      case "indian-rupee":
        return <IndianRupee className="w-5 h-5" />;
      default:
        return <Activity className="w-5 h-5" />;
    }
  };

  const getThemeStyles = () => {
    switch (stat.colorTheme) {
      case "emerald":
        return {
          iconBg: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20",
          glow: "hover:border-emerald-500/30 hover:shadow-emerald-500/5",
          accent: "text-emerald-400",
        };
      case "blue":
        return {
          iconBg: "bg-blue-500/10 text-blue-400 border-blue-500/20",
          glow: "hover:border-blue-500/30 hover:shadow-blue-500/5",
          accent: "text-blue-400",
        };
      case "purple":
        return {
          iconBg: "bg-purple-500/10 text-purple-400 border-purple-500/20",
          glow: "hover:border-purple-500/30 hover:shadow-purple-500/5",
          accent: "text-purple-400",
        };
      case "amber":
        return {
          iconBg: "bg-amber-500/10 text-amber-400 border-amber-500/20",
          glow: "hover:border-amber-500/30 hover:shadow-amber-500/5",
          accent: "text-amber-400",
        };
      case "rose":
        return {
          iconBg: "bg-rose-500/10 text-rose-400 border-rose-500/20",
          glow: "hover:border-rose-500/30 hover:shadow-rose-500/5",
          accent: "text-rose-400",
        };
      default: // indigo
        return {
          iconBg: "bg-indigo-500/10 text-indigo-400 border-indigo-500/20",
          glow: "hover:border-indigo-500/30 hover:shadow-indigo-500/5",
          accent: "text-indigo-400",
        };
    }
  };

  const styles = getThemeStyles();

  return (
    <div
      className={`relative bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg transition-all duration-300 hover:-translate-y-1 hover:shadow-xl ${styles.glow} overflow-hidden group`}
    >
      {/* Background ambient gradient */}
      <div className="absolute -top-12 -right-12 w-28 h-28 bg-gradient-to-br from-indigo-500/5 to-purple-500/5 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-500 pointer-events-none" />

      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-400">
            {stat.title}
          </p>
          <h3 className="text-2xl lg:text-3xl font-extrabold text-white mt-1.5 tracking-tight">
            {stat.value}
          </h3>
        </div>

        <div
          className={`p-3 rounded-xl border ${styles.iconBg} transition-transform group-hover:scale-110 duration-200 flex-shrink-0`}
        >
          {getIcon()}
        </div>
      </div>

      <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
        <div className="flex items-center gap-1.5 font-medium">
          {stat.isPositive ? (
            <span className="flex items-center gap-0.5 text-emerald-400 font-semibold bg-emerald-500/10 px-1.5 py-0.5 rounded-md">
              <TrendingUp className="w-3 h-3" />
              {stat.change}
            </span>
          ) : (
            <span className="flex items-center gap-0.5 text-rose-400 font-semibold bg-rose-500/10 px-1.5 py-0.5 rounded-md">
              <TrendingDown className="w-3 h-3" />
              {stat.change}
            </span>
          )}
          <span className="text-slate-400 text-[11px] truncate">{stat.period}</span>
        </div>
      </div>
    </div>
  );
}
