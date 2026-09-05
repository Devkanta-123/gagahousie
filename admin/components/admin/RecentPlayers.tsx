"use client";

import React, { useState } from "react";
import Link from "next/link";
import {
  Users,
  Search,
  ExternalLink,
  Phone,
  Mail,
  Trophy,
} from "lucide-react";
import { PlayerItem, RECENT_PLAYERS } from "@/lib/mock-data";
import { Badge } from "@/components/ui/Badge";

interface RecentPlayersProps {
  limit?: number;
  showFilters?: boolean;
}

export function RecentPlayers({
  limit,
  showFilters = true,
}: RecentPlayersProps) {
  const [search, setSearch] = useState("");
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerItem | null>(null);

  const filteredPlayers = RECENT_PLAYERS.filter(
    (player) =>
      player.name.toLowerCase().includes(search.toLowerCase()) ||
      player.email.toLowerCase().includes(search.toLowerCase()) ||
      player.phone.includes(search)
  );

  const displayPlayers = limit
    ? filteredPlayers.slice(0, limit)
    : filteredPlayers;

  return (
    <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg flex flex-col">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-800">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-purple-500/10 border border-purple-500/20 text-purple-400">
            <Users className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
              Recent Players
              <span className="text-xs font-normal text-slate-400">
                ({RECENT_PLAYERS.length} total)
              </span>
            </h2>
            <p className="text-xs text-slate-400">
              Player activity, winnings & verification status
            </p>
          </div>
        </div>

        {limit && (
          <Link
            href="/admin/players"
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-purple-400 hover:text-purple-300 transition-colors self-start sm:self-auto"
          >
            View all players
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>
        )}
      </div>

      {/* Search Filter */}
      {showFilters && (
        <div className="py-3">
          <div className="relative">
            <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search player name, email, or phone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 bg-slate-800/50 border border-slate-700/80 rounded-xl text-xs text-slate-200 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-purple-500"
            />
          </div>
        </div>
      )}

      {/* Table Container */}
      <div className="overflow-x-auto -mx-5 px-5 mt-2">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-800/40 text-[11px] font-semibold uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <tr>
              <th className="py-3 px-3">Player Info</th>
              <th className="py-3 px-3">Contact</th>
              <th className="py-3 px-3 text-center">Games</th>
              <th className="py-3 px-3">Total Winnings</th>
              <th className="py-3 px-3">Status</th>
              <th className="py-3 px-3 text-right">Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {displayPlayers.length === 0 ? (
              <tr>
                <td colSpan={6} className="py-8 text-center text-slate-400">
                  No players found matching your query.
                </td>
              </tr>
            ) : (
              displayPlayers.map((player) => (
                <tr
                  key={player.id}
                  className="hover:bg-slate-800/30 transition-colors group"
                >
                  <td className="py-3 px-3 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-purple-500 to-indigo-600 flex items-center justify-center font-bold text-white text-xs shadow-md flex-shrink-0">
                        {player.name.charAt(0)}
                      </div>
                      <div className="flex flex-col">
                        <span className="font-bold text-white text-xs sm:text-sm group-hover:text-purple-300 transition-colors">
                          {player.name}
                        </span>
                        <span className="text-[11px] text-slate-400">
                          Joined {player.joinedDate}
                        </span>
                      </div>
                    </div>
                  </td>

                  <td className="py-3 px-3">
                    <div className="flex flex-col text-[11px] space-y-0.5">
                      <span className="text-slate-300 flex items-center gap-1">
                        <Mail className="w-3 h-3 text-slate-400" />
                        {player.email}
                      </span>
                      <span className="text-slate-400 flex items-center gap-1">
                        <Phone className="w-3 h-3 text-slate-400" />
                        {player.phone}
                      </span>
                    </div>
                  </td>

                  <td className="py-3 px-3 text-center whitespace-nowrap">
                    <span className="inline-flex items-center px-2 py-0.5 rounded-md bg-slate-800 text-slate-200 font-semibold text-xs border border-slate-700">
                      {player.gamesPlayed}
                    </span>
                  </td>

                  <td className="py-3 px-3 whitespace-nowrap">
                    <div className="flex items-center gap-1 font-bold text-emerald-400 text-xs sm:text-sm">
                      <Trophy className="w-3.5 h-3.5 text-emerald-400" />
                      <span>₹{player.totalWinnings.toLocaleString("en-IN")}</span>
                    </div>
                    <span className="text-[10px] text-slate-400">
                      Wallet: ₹{player.walletBalance.toLocaleString("en-IN")}
                    </span>
                  </td>

                  <td className="py-3 px-3 whitespace-nowrap">
                    <Badge variant={player.status} dot={player.status === "KYC Verified"}>
                      {player.status}
                    </Badge>
                  </td>

                  <td className="py-3 px-3 text-right whitespace-nowrap">
                    <button
                      onClick={() => setSelectedPlayer(player)}
                      className="px-2.5 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700 transition-colors text-xs font-medium"
                    >
                      View
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Player Detail Modal */}
      {selectedPlayer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl w-full max-w-md p-6 shadow-2xl space-y-4">
            <div className="flex items-center gap-3 border-b border-slate-800 pb-4">
              <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-purple-500 to-indigo-600 flex items-center justify-center font-bold text-white text-base shadow-lg">
                {selectedPlayer.name.charAt(0)}
              </div>
              <div className="flex-1">
                <h3 className="text-base font-bold text-white">
                  {selectedPlayer.name}
                </h3>
                <p className="text-xs text-slate-400">{selectedPlayer.email}</p>
              </div>
              <Badge variant={selectedPlayer.status}>
                {selectedPlayer.status}
              </Badge>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs">
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Total Winnings</span>
                <p className="text-base font-bold text-emerald-400 mt-0.5">
                  ₹{selectedPlayer.totalWinnings.toLocaleString("en-IN")}
                </p>
              </div>
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Wallet Balance</span>
                <p className="text-base font-bold text-indigo-400 mt-0.5">
                  ₹{selectedPlayer.walletBalance.toLocaleString("en-IN")}
                </p>
              </div>
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Games Played</span>
                <p className="text-sm font-bold text-white mt-0.5">
                  {selectedPlayer.gamesPlayed} matches
                </p>
              </div>
              <div className="bg-slate-800/40 p-3 rounded-xl border border-slate-800">
                <span className="text-slate-400">Last Active</span>
                <p className="text-sm font-semibold text-slate-300 mt-0.5">
                  {selectedPlayer.lastActive}
                </p>
              </div>
            </div>

            <div className="pt-2 flex justify-end gap-2">
              <button
                onClick={() => setSelectedPlayer(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Close
              </button>
              <Link
                href="/admin/players"
                onClick={() => setSelectedPlayer(null)}
                className="px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-xl text-xs font-semibold"
              >
                Manage Player
              </Link>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
