"use client";

import React, { useState } from "react";
import {
  Sliders,
  Save,
  CheckCircle,
  User,
  Sparkles,
} from "lucide-react";
import { useAuth } from "@/lib/auth-context";
import { Button } from "@/components/ui/Button";

export default function SettingsPage() {
  const { user } = useAuth();
  const [saved, setSaved] = useState(false);

  // Settings mock state
  const [commissionRate, setCommissionRate] = useState(15);
  const [autoCallSpeed, setAutoCallSpeed] = useState(3);
  const [maxTicketsPerPlayer, setMaxTicketsPerPlayer] = useState(6);
  const [earlyFivePrizeShare, setEarlyFivePrizeShare] = useState(10);
  const [fullHousePrizeShare, setFullHousePrizeShare] = useState(50);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  };

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            System Settings & Game Rules
          </h2>
          <p className="text-xs text-slate-400">
            Configure platform parameters, game room caller delays, and prize distribution splits
          </p>
        </div>

        {saved && (
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-semibold animate-in fade-in">
            <CheckCircle className="w-4 h-4" />
            Settings Saved Successfully
          </div>
        )}
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* Admin Profile Section */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 shadow-xl space-y-4">
          <div className="flex items-center gap-2.5 pb-3 border-b border-slate-800">
            <User className="w-5 h-5 text-indigo-400" />
            <h3 className="font-bold text-sm text-white">Admin Account Information</h3>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-xs">
            <div>
              <label className="block text-slate-300 font-medium mb-1">Admin Display Name</label>
              <input
                type="text"
                disabled
                value={user?.name || "Administrator"}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white opacity-80 cursor-not-allowed"
              />
            </div>
            <div>
              <label className="block text-slate-300 font-medium mb-1">Admin Email</label>
              <input
                type="email"
                disabled
                value={user?.email || "admin@gmail.com"}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white opacity-80 cursor-not-allowed"
              />
            </div>
          </div>
        </div>

        {/* Game Rules & Timing Configuration */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 shadow-xl space-y-4">
          <div className="flex items-center gap-2.5 pb-3 border-b border-slate-800">
            <Sliders className="w-5 h-5 text-purple-400" />
            <h3 className="font-bold text-sm text-white">Housie Gameplay & Rules Engine</h3>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
            <div>
              <label className="block text-slate-300 font-medium mb-1">
                Auto Caller Delay (Seconds)
              </label>
              <input
                type="number"
                min={2}
                max={15}
                value={autoCallSpeed}
                onChange={(e) => setAutoCallSpeed(Number(e.target.value))}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-slate-300 font-medium mb-1">
                Max Tickets / Player per Game
              </label>
              <input
                type="number"
                min={1}
                max={12}
                value={maxTicketsPerPlayer}
                onChange={(e) => setMaxTicketsPerPlayer(Number(e.target.value))}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-slate-300 font-medium mb-1">
                Platform Commission Fee (%)
              </label>
              <input
                type="number"
                min={5}
                max={30}
                value={commissionRate}
                onChange={(e) => setCommissionRate(Number(e.target.value))}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
              />
            </div>
          </div>
        </div>

        {/* Prize Pool Distribution Percentage Defaults */}
        <div className="bg-slate-900/80 border border-slate-800 rounded-3xl p-6 shadow-xl space-y-4">
          <div className="flex items-center gap-2.5 pb-3 border-b border-slate-800">
            <Sparkles className="w-5 h-5 text-amber-400" />
            <h3 className="font-bold text-sm text-white">Prize Pool Distribution Splits</h3>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-xs">
            <div>
              <label className="block text-slate-300 font-medium mb-1">Early 5 (%)</label>
              <input
                type="number"
                value={earlyFivePrizeShare}
                onChange={(e) => setEarlyFivePrizeShare(Number(e.target.value))}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white"
              />
            </div>

            <div>
              <label className="block text-slate-300 font-medium mb-1">Top Line (%)</label>
              <input
                type="number"
                defaultValue={12}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white"
              />
            </div>

            <div>
              <label className="block text-slate-300 font-medium mb-1">Middle Line (%)</label>
              <input
                type="number"
                defaultValue={12}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white"
              />
            </div>

            <div>
              <label className="block text-slate-300 font-medium mb-1">Full House (%)</label>
              <input
                type="number"
                value={fullHousePrizeShare}
                onChange={(e) => setFullHousePrizeShare(Number(e.target.value))}
                className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white"
              />
            </div>
          </div>
        </div>

        {/* Save Button */}
        <div className="flex justify-end">
          <Button
            type="submit"
            variant="primary"
            size="lg"
            leftIcon={<Save className="w-4 h-4" />}
          >
            Save System Configurations
          </Button>
        </div>
      </form>
    </div>
  );
}
