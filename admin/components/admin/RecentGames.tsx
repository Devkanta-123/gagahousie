"use client";

import React, { useState } from "react";
import Link from "next/link";
import {
  Gamepad2,
  Search,
  ExternalLink,
  Users,
  Trophy,
  Calendar,
  Eye,
} from "lucide-react";
import { GameItem, RECENT_GAMES } from "@/lib/mock-data";
import { Badge } from "@/components/ui/Badge";

interface RecentGamesProps {
  limit?: number;
  showFilters?: boolean;
}

export function RecentGames({ limit, showFilters = true }: RecentGamesProps) {
  const [filter, setFilter] = useState<string>("All");
  const [search, setSearch] = useState<string>("");
  const [selectedGame, setSelectedGame] = useState<GameItem | null>(null);

  const filteredGames = RECENT_GAMES.filter((game) => {
    const matchesFilter =
      filter === "All" ? true : game.status.toLowerCase() === filter.toLowerCase();
    const matchesSearch =
      game.name.toLowerCase().includes(search.toLowerCase()) ||
      game.gameCode.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const displayGames = limit ? filteredGames.slice(0, limit) : filteredGames;

  return (
    <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg flex flex-col">
      {/* Section Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-800">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
            <Gamepad2 className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
              Recent Games
              <span className="text-xs font-normal text-slate-400">
                ({filteredGames.length} available)
              </span>
            </h2>
            <p className="text-xs text-slate-400">
              Live status, registrations, and prize pools
            </p>
          </div>
        </div>

        {limit && (
          <Link
            href="/admin/games"
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-400 hover:text-indigo-300 transition-colors self-start sm:self-auto"
          >
            View all games
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>
        )}
      </div>

      {/* Filter and Search Bar */}
      {showFilters && (
        <div className="py-3 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-2.5">
          {/* Status Tabs */}
          <div className="flex items-center gap-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/60 overflow-x-auto">
            {["All", "Active", "Upcoming", "Completed"].map((tab) => (
              <button
                key={tab}
                onClick={() => setFilter(tab)}
                className={`px-3 py-1 text-xs font-medium rounded-lg transition-all whitespace-nowrap ${
                  filter === tab
                    ? "bg-indigo-600 text-white shadow-sm"
                    : "text-slate-400 hover:text-slate-200"
                }`}
              >
                {tab}
              </button>
            ))}
          </div>

          {/* Search Bar */}
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Filter game name or ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full sm:w-56 pl-8 pr-3 py-1.5 bg-slate-800/50 border border-slate-700/80 rounded-xl text-xs text-slate-200 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>
        </div>
      )}

      {/* Table responsive container */}
      <div className="overflow-x-auto -mx-5 px-5 mt-2">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-800/40 text-[11px] font-semibold uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <tr>
              <th className="py-3 px-3">Game ID & Name</th>
              <th className="py-3 px-3">Schedule / Date</th>
              <th className="py-3 px-3">Players & Capacity</th>
              <th className="py-3 px-3">Prize Pool</th>
              <th className="py-3 px-3">Status</th>
              <th className="py-3 px-3 text-right">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {displayGames.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-8 text-center text-slate-400">
                  No games found matching your filter criteria.
                </td>
              </tr>
            ) : (
              displayGames.map((game) => {
                const fillPercentage = Math.min(
                  100,
                  Math.round((game.playersCount / game.maxPlayers) * 100)
                );

                return (
                  <tr
                    key={game.id}
                    className="hover:bg-slate-800/30 transition-colors group"
                  >
                    <td className="py-3.5 px-3">
                      <div className="flex flex-col">
                        <span className="font-bold text-white text-xs sm:text-sm group-hover:text-indigo-300 transition-colors flex items-center gap-1.5">
                          {game.name}
                          {game.status === "Active" && (
                            <span className="flex h-2 w-2 relative">
                              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                            </span>
                          )}
                        </span>
                        <div className="flex items-center gap-2 mt-0.5 text-[11px] text-slate-400">
                          <span className="font-mono text-indigo-400 font-medium">
                            #{game.gameCode}
                          </span>
                          <span>•</span>
                          <span>{game.gameType}</span>
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <div className="flex items-center gap-1.5 text-slate-300">
                        <Calendar className="w-3.5 h-3.5 text-slate-400" />
                        <span>{game.date}</span>
                      </div>
                    </td>

                    <td className="py-3.5 px-3">
                      <div className="flex flex-col gap-1 w-32 sm:w-40">
                        <div className="flex items-center justify-between text-[11px]">
                          <span className="flex items-center gap-1 text-slate-300 font-medium">
                            <Users className="w-3 h-3 text-slate-400" />
                            {game.playersCount} / {game.maxPlayers}
                          </span>
                          <span className="text-slate-400">{fillPercentage}%</span>
                        </div>
                        <div className="w-full bg-slate-800 rounded-full h-1.5 overflow-hidden">
                          <div
                            className={`h-full rounded-full transition-all ${
                              fillPercentage >= 90
                                ? "bg-gradient-to-r from-amber-500 to-rose-500"
                                : "bg-gradient-to-r from-indigo-500 to-emerald-500"
                            }`}
                            style={{ width: `${fillPercentage}%` }}
                          />
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <div className="flex items-center gap-1 font-bold text-amber-400">
                        <Trophy className="w-3.5 h-3.5 text-amber-400" />
                        <span>₹{game.prizePool.toLocaleString("en-IN")}</span>
                      </div>
                      <span className="text-[10px] text-slate-400">
                        Ticket: ₹{game.ticketPrice}
                      </span>
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <Badge variant={game.status} dot={game.status === "Active"}>
                        {game.status}
                      </Badge>
                    </td>

                    <td className="py-3.5 px-3 text-right whitespace-nowrap">
                      <button
                        onClick={() => setSelectedGame(game)}
                        className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700 transition-colors text-xs font-medium"
                      >
                        <Eye className="w-3.5 h-3.5" />
                        <span>Details</span>
                      </button>
                    </td>
                  </tr>
                );
              })
            )}
          </tbody>
        </table>
      </div>

      {/* Game Details Modal */}
      {selectedGame && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6 shadow-2xl space-y-4">
            <div className="flex items-start justify-between border-b border-slate-800 pb-3">
              <div>
                <span className="text-xs font-mono text-indigo-400 font-semibold">
                  #{selectedGame.gameCode}
                </span>
                <h3 className="text-lg font-bold text-white mt-0.5">
                  {selectedGame.name}
                </h3>
              </div>
              <Badge variant={selectedGame.status} dot={selectedGame.status === "Active"}>
                {selectedGame.status}
              </Badge>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Prize Pool</span>
                <p className="text-base font-bold text-amber-400 mt-0.5">
                  ₹{selectedGame.prizePool.toLocaleString("en-IN")}
                </p>
              </div>
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Ticket Cost</span>
                <p className="text-base font-bold text-emerald-400 mt-0.5">
                  ₹{selectedGame.ticketPrice}
                </p>
              </div>
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Players Registered</span>
                <p className="text-sm font-semibold text-white mt-0.5">
                  {selectedGame.playersCount} / {selectedGame.maxPlayers}
                </p>
              </div>
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Game Type</span>
                <p className="text-sm font-semibold text-white mt-0.5">
                  {selectedGame.gameType}
                </p>
              </div>
            </div>

            {selectedGame.winnerName && (
              <div className="p-3 bg-amber-500/10 border border-amber-500/20 rounded-xl text-xs">
                <span className="text-amber-300 font-medium">Winner: </span>
                <span className="text-white font-bold">{selectedGame.winnerName}</span>
              </div>
            )}

            <div className="pt-2 flex justify-end gap-2">
              <button
                onClick={() => setSelectedGame(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Close
              </button>
              <Link
                href="/admin/boards"
                onClick={() => setSelectedGame(null)}
                className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-xs font-semibold"
              >
                View Live Board
              </Link>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
