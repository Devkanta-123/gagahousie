"use client";

import React, { useState } from "react";
import {
  Users,
  Search,
  Mail,
  Phone,
} from "lucide-react";
import { RECENT_PLAYERS, PlayerItem } from "@/lib/mock-data";
import { Badge } from "@/components/ui/Badge";

export default function PlayersPage() {
  const [players, setPlayers] = useState<PlayerItem[]>(RECENT_PLAYERS);
  const [filter, setFilter] = useState<string>("All");
  const [search, setSearch] = useState<string>("");
  const [selectedPlayer, setSelectedPlayer] = useState<PlayerItem | null>(null);

  const filteredPlayers = players.filter((player) => {
    const matchesFilter =
      filter === "All" ? true : player.status.toLowerCase() === filter.toLowerCase();
    const matchesSearch =
      player.name.toLowerCase().includes(search.toLowerCase()) ||
      player.email.toLowerCase().includes(search.toLowerCase()) ||
      player.phone.includes(search);
    return matchesFilter && matchesSearch;
  });

  const toggleKycStatus = (playerId: string) => {
    setPlayers(
      players.map((p) => {
        if (p.id === playerId) {
          const newStatus = p.status === "KYC Verified" ? "Pending KYC" : "KYC Verified";
          return { ...p, status: newStatus };
        }
        return p;
      })
    );
    if (selectedPlayer && selectedPlayer.id === playerId) {
      setSelectedPlayer((prev) =>
        prev
          ? {
              ...prev,
              status: prev.status === "KYC Verified" ? "Pending KYC" : "KYC Verified",
            }
          : null
      );
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            Players Directory
          </h2>
          <p className="text-xs text-slate-400">
            Manage user accounts, verify KYC documents, and monitor wallet balances
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="px-3.5 py-1.5 rounded-xl bg-slate-900 border border-slate-800 text-xs text-slate-300 flex items-center gap-2">
            <Users className="w-4 h-4 text-purple-400" />
            <span>Total: <strong>2,450 Players</strong></span>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-4 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 shadow-lg">
        <div className="flex items-center gap-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/60 overflow-x-auto">
          {["All", "Active", "KYC Verified", "Pending KYC"].map((tab) => (
            <button
              key={tab}
              onClick={() => setFilter(tab)}
              className={`px-3.5 py-1.5 text-xs font-medium rounded-lg transition-all whitespace-nowrap ${
                filter === tab
                  ? "bg-purple-600 text-white shadow-sm"
                  : "text-slate-400 hover:text-slate-200"
              }`}
            >
              {tab}
            </button>
          ))}
        </div>

        <div className="relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search player name, email, or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full sm:w-72 pl-9 pr-4 py-2 bg-slate-800/50 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
        </div>
      </div>

      {/* Players Table */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg overflow-x-auto">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-800/40 text-[11px] font-semibold uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <tr>
              <th className="py-3.5 px-3">Player Info</th>
              <th className="py-3.5 px-3">Contact</th>
              <th className="py-3.5 px-3">Joined Date</th>
              <th className="py-3.5 px-3 text-center">Games</th>
              <th className="py-3.5 px-3">Wallet & Winnings</th>
              <th className="py-3.5 px-3">KYC Status</th>
              <th className="py-3.5 px-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filteredPlayers.map((player) => (
              <tr
                key={player.id}
                className="hover:bg-slate-800/30 transition-colors group"
              >
                <td className="py-3.5 px-3 whitespace-nowrap">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-purple-500 to-indigo-600 flex items-center justify-center font-bold text-white text-sm shadow-md">
                      {player.name.charAt(0)}
                    </div>
                    <div>
                      <h4 className="font-bold text-white text-sm group-hover:text-purple-300 transition-colors">
                        {player.name}
                      </h4>
                      <span className="text-[11px] text-slate-400">
                        ID: #{player.id}
                      </span>
                    </div>
                  </div>
                </td>

                <td className="py-3.5 px-3">
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

                <td className="py-3.5 px-3 whitespace-nowrap text-slate-400">
                  {player.joinedDate}
                </td>

                <td className="py-3.5 px-3 text-center whitespace-nowrap">
                  <span className="px-2.5 py-1 rounded-lg bg-slate-800 border border-slate-700 font-semibold text-white">
                    {player.gamesPlayed}
                  </span>
                </td>

                <td className="py-3.5 px-3 whitespace-nowrap">
                  <div className="flex flex-col">
                    <span className="font-bold text-emerald-400 text-xs sm:text-sm">
                      ₹{player.totalWinnings.toLocaleString("en-IN")} Won
                    </span>
                    <span className="text-[11px] text-indigo-300 font-medium">
                      ₹{player.walletBalance.toLocaleString("en-IN")} in wallet
                    </span>
                  </div>
                </td>

                <td className="py-3.5 px-3 whitespace-nowrap">
                  <Badge variant={player.status} dot={player.status === "KYC Verified"}>
                    {player.status}
                  </Badge>
                </td>

                <td className="py-3.5 px-3 text-right whitespace-nowrap">
                  <div className="flex items-center justify-end gap-1.5">
                    <button
                      onClick={() => toggleKycStatus(player.id)}
                      className={`px-2.5 py-1 rounded-lg text-xs font-semibold border transition-colors ${
                        player.status === "KYC Verified"
                          ? "bg-slate-800 text-slate-300 border-slate-700 hover:bg-amber-500/10 hover:text-amber-300 hover:border-amber-500/30"
                          : "bg-emerald-500/10 text-emerald-300 border-emerald-500/30 hover:bg-emerald-500/20"
                      }`}
                    >
                      {player.status === "KYC Verified" ? "Revoke KYC" : "Verify KYC"}
                    </button>
                    <button
                      onClick={() => setSelectedPlayer(player)}
                      className="px-2.5 py-1 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 border border-slate-700 text-xs font-medium"
                    >
                      Details
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Player Modal */}
      {selectedPlayer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-md p-6 shadow-2xl space-y-4">
            <div className="flex items-center gap-3 border-b border-slate-800 pb-4">
              <div className="w-12 h-12 rounded-full bg-gradient-to-tr from-purple-500 to-indigo-600 flex items-center justify-center font-bold text-white text-lg">
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
            </div>

            <div className="pt-3 flex justify-between gap-2 border-t border-slate-800">
              <button
                onClick={() => toggleKycStatus(selectedPlayer.id)}
                className="px-3.5 py-2 rounded-xl text-xs font-semibold bg-indigo-600/20 text-indigo-300 border border-indigo-500/30 hover:bg-indigo-600/30"
              >
                Toggle KYC Status
              </button>
              <button
                onClick={() => setSelectedPlayer(null)}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-semibold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
