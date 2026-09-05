"use client";

import React, { useState } from "react";
import { Volume2, Flame } from "lucide-react";
import { Badge } from "@/components/ui/Badge";

// Sample active board numbers called
const CALLED_NUMBERS = [7, 14, 23, 31, 42, 55, 68, 79, 88, 90, 3, 19, 27, 45, 62, 73];

export function LiveHousieActivity() {
  const [soundEnabled, setSoundEnabled] = useState(false);

  return (
    <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg flex flex-col space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-800">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-400">
            <Flame className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-white tracking-tight flex items-center gap-2">
              Live Room Activity
              <span className="flex h-2 w-2 relative">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
            </h3>
            <p className="text-xs text-slate-400">Game #GH-9042 • Mega Tambola Dhamaka</p>
          </div>
        </div>

        <button
          onClick={() => setSoundEnabled((prev) => !prev)}
          className={`p-1.5 rounded-lg border text-xs flex items-center gap-1 transition-colors ${
            soundEnabled
              ? "bg-indigo-600/20 text-indigo-300 border-indigo-500/40"
              : "bg-slate-800 text-slate-400 border-slate-700 hover:text-white"
          }`}
          title="Toggle caller audio alert"
        >
          <Volume2 className="w-3.5 h-3.5" />
          <span className="text-[10px] hidden sm:inline">{soundEnabled ? "Mute" : "Audio"}</span>
        </button>
      </div>

      {/* Latest Number Called Showcase */}
      <div className="bg-gradient-to-r from-indigo-950/60 via-slate-900 to-purple-950/60 border border-indigo-500/20 rounded-xl p-4 flex items-center justify-between">
        <div>
          <span className="text-[11px] font-semibold uppercase tracking-wider text-indigo-300">
            Current Number Called
          </span>
          <p className="text-xs text-slate-400 mt-0.5">Call #16 • 42 numbers remaining</p>
        </div>

        <div className="flex items-center gap-3">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-amber-400 to-amber-600 text-slate-950 font-black text-2xl flex items-center justify-center shadow-lg shadow-amber-500/25 ring-4 ring-amber-500/20 animate-bounce">
            73
          </div>
        </div>
      </div>

      {/* Called Numbers Grid */}
      <div>
        <div className="flex items-center justify-between mb-2">
          <span className="text-xs font-semibold text-slate-300">Recent Numbers Called</span>
          <span className="text-[10px] text-slate-400">16 / 90</span>
        </div>

        <div className="flex flex-wrap gap-1.5 max-h-24 overflow-y-auto pr-1">
          {CALLED_NUMBERS.map((num, i) => (
            <span
              key={i}
              className={`w-7 h-7 rounded-lg text-xs font-bold flex items-center justify-center transition-all ${
                i === CALLED_NUMBERS.length - 1
                  ? "bg-amber-500 text-slate-950 ring-2 ring-amber-400 font-extrabold"
                  : "bg-slate-800 text-slate-200 border border-slate-700/80"
              }`}
            >
              {num}
            </span>
          ))}
        </div>
      </div>

      {/* Prize Pattern Claim Status */}
      <div className="pt-2 border-t border-slate-800 space-y-2">
        <span className="text-xs font-semibold text-slate-300">Winning Patterns Claim Status</span>
        <div className="grid grid-cols-2 gap-2 text-xs">
          <div className="p-2 rounded-lg bg-slate-800/40 border border-slate-800 flex items-center justify-between">
            <span className="text-slate-400">Early 5</span>
            <Badge variant="completed">Claimed</Badge>
          </div>
          <div className="p-2 rounded-lg bg-slate-800/40 border border-slate-800 flex items-center justify-between">
            <span className="text-slate-400">Top Line</span>
            <Badge variant="completed">Claimed</Badge>
          </div>
          <div className="p-2 rounded-lg bg-slate-800/40 border border-slate-800 flex items-center justify-between">
            <span className="text-slate-400">Middle Line</span>
            <Badge variant="active">In Play</Badge>
          </div>
          <div className="p-2 rounded-lg bg-slate-800/40 border border-slate-800 flex items-center justify-between">
            <span className="text-slate-400">Full House</span>
            <Badge variant="active">In Play</Badge>
          </div>
        </div>
      </div>
    </div>
  );
}
