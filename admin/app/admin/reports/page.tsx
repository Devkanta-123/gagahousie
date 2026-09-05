"use client";

import React from "react";
import {
  TrendingUp,
  Download,
  Users,
  Gamepad2,
} from "lucide-react";
import { RevenueChart } from "@/components/admin/RevenueChart";
import { Button } from "@/components/ui/Button";

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            Financial & Gameplay Analytics
          </h2>
          <p className="text-xs text-slate-400">
            Platform performance metrics, player retention, and game profitability insights
          </p>
        </div>

        <Button
          variant="outline"
          size="md"
          leftIcon={<Download className="w-4 h-4" />}
          onClick={() => alert("Generating full monthly PDF report...")}
        >
          Generate PDF Summary
        </Button>
      </div>

      {/* Main Revenue Chart */}
      <RevenueChart />

      {/* Breakdown Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg space-y-3">
          <div className="flex items-center gap-2 text-indigo-400">
            <Gamepad2 className="w-5 h-5" />
            <h3 className="text-sm font-bold text-white">Popular Game Formats</h3>
          </div>
          <div className="space-y-2 text-xs">
            <div className="flex justify-between text-slate-300">
              <span>Classic Housie 90</span>
              <span className="font-bold text-white">58% volume</span>
            </div>
            <div className="w-full bg-slate-800 rounded-full h-1.5">
              <div className="bg-indigo-500 h-1.5 rounded-full" style={{ width: "58%" }} />
            </div>

            <div className="flex justify-between text-slate-300 pt-1">
              <span>Speed 30</span>
              <span className="font-bold text-white">26% volume</span>
            </div>
            <div className="w-full bg-slate-800 rounded-full h-1.5">
              <div className="bg-purple-500 h-1.5 rounded-full" style={{ width: "26%" }} />
            </div>

            <div className="flex justify-between text-slate-300 pt-1">
              <span>Mega Jackpot</span>
              <span className="font-bold text-white">16% volume</span>
            </div>
            <div className="w-full bg-slate-800 rounded-full h-1.5">
              <div className="bg-amber-500 h-1.5 rounded-full" style={{ width: "16%" }} />
            </div>
          </div>
        </div>

        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg space-y-3">
          <div className="flex items-center gap-2 text-emerald-400">
            <TrendingUp className="w-5 h-5" />
            <h3 className="text-sm font-bold text-white">Platform Commission</h3>
          </div>
          <p className="text-2xl font-black text-emerald-400">₹1,84,500</p>
          <p className="text-xs text-slate-400">
            Average gross platform margin is <strong>18.5%</strong> across all active rooms.
          </p>
        </div>

        <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg space-y-3">
          <div className="flex items-center gap-2 text-purple-400">
            <Users className="w-5 h-5" />
            <h3 className="text-sm font-bold text-white">Player Retention</h3>
          </div>
          <p className="text-2xl font-black text-purple-400">76.2%</p>
          <p className="text-xs text-slate-400">
            Players returning to join 3 or more games per week.
          </p>
        </div>
      </div>
    </div>
  );
}
