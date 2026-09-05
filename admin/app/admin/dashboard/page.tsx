"use client";

import React from "react";
import Link from "next/link";
import {
  PlusCircle,
  Grid3X3,
  Sparkles,
} from "lucide-react";
import { DASHBOARD_STATS } from "@/lib/mock-data";
import { StatCard } from "@/components/admin/StatCard";
import { RecentGames } from "@/components/admin/RecentGames";
import { RecentPlayers } from "@/components/admin/RecentPlayers";
import { RevenueChart } from "@/components/admin/RevenueChart";
import { LiveHousieActivity } from "@/components/admin/LiveHousieActivity";
import { Button } from "@/components/ui/Button";

export default function AdminDashboardPage() {
  return (
    <div className="space-y-6">
      {/* Welcome Banner / Quick Actions */}
      <div className="bg-gradient-to-r from-indigo-950/80 via-slate-900 to-purple-950/80 border border-indigo-500/20 rounded-3xl p-6 shadow-xl relative overflow-hidden flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="absolute -right-10 -bottom-10 w-60 h-60 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="space-y-1 relative z-10">
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-500/10 border border-indigo-500/20 text-indigo-300 text-xs font-semibold">
            <Sparkles className="w-3.5 h-3.5 text-indigo-400" />
            Live Platform Status • 12 Active Game Rooms
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-white tracking-tight">
            Welcome to Gaga Housie Control Hub
          </h2>
          <p className="text-xs sm:text-sm text-slate-400 max-w-xl">
            Real-time monitoring of live Housie rooms, player claims, ticket velocity, and financial settlements.
          </p>
        </div>

        <div className="flex items-center gap-2.5 relative z-10 flex-wrap">
          <Link href="/admin/games">
            <Button
              variant="primary"
              size="md"
              leftIcon={<PlusCircle className="w-4 h-4" />}
            >
              Create New Game
            </Button>
          </Link>
          <Link href="/admin/boards">
            <Button
              variant="secondary"
              size="md"
              leftIcon={<Grid3X3 className="w-4 h-4" />}
            >
              Live Caller
            </Button>
          </Link>
        </div>
      </div>

      {/* 6 Statistics Cards Grid */}
      <section>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
          {DASHBOARD_STATS.map((stat) => (
            <StatCard key={stat.id} stat={stat} />
          ))}
        </div>
      </section>

      {/* Analytics & Live Activity Grid */}
      <section className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <RevenueChart />
        </div>

        <div className="lg:col-span-1">
          <LiveHousieActivity />
        </div>
      </section>

      {/* Tables Section: Recent Games and Recent Players */}
      <section className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div>
          <RecentGames limit={5} showFilters={true} />
        </div>

        <div>
          <RecentPlayers limit={5} showFilters={true} />
        </div>
      </section>
    </div>
  );
}
