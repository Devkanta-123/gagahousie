"use client";

import React, { useState } from "react";
import {
  Plus,
  Search,
  Calendar,
  Play,
  Trash2,
  Edit,
} from "lucide-react";
import { RECENT_GAMES, GameItem } from "@/lib/mock-data";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";

export default function GamesManagementPage() {
  const [games, setGames] = useState<GameItem[]>(RECENT_GAMES);
  const [filter, setFilter] = useState<string>("All");
  const [search, setSearch] = useState<string>("");
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Form state for creating a new game
  const [newGame, setNewGame] = useState({
    name: "",
    gameType: "Classic Housie" as GameItem["gameType"],
    ticketPrice: 50,
    maxPlayers: 100,
    prizePool: 25000,
    date: "Today, 09:30 PM",
  });

  const handleCreateGame = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newGame.name) return;

    const created: GameItem = {
      id: `g_${Date.now()}`,
      gameCode: `GH-${Math.floor(1000 + Math.random() * 9000)}`,
      name: newGame.name,
      date: newGame.date,
      time: "21:30",
      playersCount: 0,
      maxPlayers: Number(newGame.maxPlayers),
      ticketPrice: Number(newGame.ticketPrice),
      prizePool: Number(newGame.prizePool),
      status: "Upcoming",
      gameType: newGame.gameType,
    };

    setGames([created, ...games]);
    setShowCreateModal(false);
    setNewGame({
      name: "",
      gameType: "Classic Housie",
      ticketPrice: 50,
      maxPlayers: 100,
      prizePool: 25000,
      date: "Today, 09:30 PM",
    });
  };

  const filteredGames = games.filter((game) => {
    const matchesFilter =
      filter === "All" ? true : game.status.toLowerCase() === filter.toLowerCase();
    const matchesSearch =
      game.name.toLowerCase().includes(search.toLowerCase()) ||
      game.gameCode.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Top Action Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            Games Management
          </h2>
          <p className="text-xs text-slate-400">
            Create, schedule, configure prize pools and oversee live Housie game rooms
          </p>
        </div>

        <Button
          variant="primary"
          onClick={() => setShowCreateModal(true)}
          leftIcon={<Plus className="w-4 h-4" />}
        >
          Create Game Room
        </Button>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-4 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 shadow-lg">
        <div className="flex items-center gap-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/60 overflow-x-auto">
          {["All", "Active", "Upcoming", "Completed"].map((tab) => (
            <button
              key={tab}
              onClick={() => setFilter(tab)}
              className={`px-3.5 py-1.5 text-xs font-medium rounded-lg transition-all whitespace-nowrap ${
                filter === tab
                  ? "bg-indigo-600 text-white shadow-sm"
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
            placeholder="Search by name or code..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full sm:w-64 pl-9 pr-4 py-2 bg-slate-800/50 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>

      {/* Games Grid / Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredGames.map((game) => {
          const fillPercentage = Math.min(
            100,
            Math.round((game.playersCount / game.maxPlayers) * 100)
          );

          return (
            <div
              key={game.id}
              className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg hover:border-slate-700 transition-all flex flex-col justify-between space-y-4 group"
            >
              <div>
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <span className="text-xs font-mono font-semibold text-indigo-400">
                      #{game.gameCode}
                    </span>
                    <h3 className="text-base font-bold text-white group-hover:text-indigo-300 transition-colors mt-0.5">
                      {game.name}
                    </h3>
                  </div>
                  <Badge variant={game.status} dot={game.status === "Active"}>
                    {game.status}
                  </Badge>
                </div>

                <div className="mt-3 flex items-center gap-2 text-xs text-slate-400">
                  <span className="px-2 py-0.5 rounded-md bg-slate-800 border border-slate-700 text-slate-300">
                    {game.gameType}
                  </span>
                  <span>•</span>
                  <span className="flex items-center gap-1">
                    <Calendar className="w-3.5 h-3.5" />
                    {game.date}
                  </span>
                </div>
              </div>

              {/* Progress & Stats */}
              <div className="space-y-2 bg-slate-800/30 p-3 rounded-xl border border-slate-800/80">
                <div className="flex items-center justify-between text-xs">
                  <span className="text-slate-400">Registration</span>
                  <span className="font-semibold text-white">
                    {game.playersCount} / {game.maxPlayers} ({fillPercentage}%)
                  </span>
                </div>
                <div className="w-full bg-slate-800 rounded-full h-2 overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-indigo-500 to-purple-500 rounded-full transition-all"
                    style={{ width: `${fillPercentage}%` }}
                  />
                </div>

                <div className="pt-2 flex items-center justify-between text-xs border-t border-slate-800">
                  <div>
                    <span className="text-[10px] text-slate-400">Prize Pool</span>
                    <p className="font-bold text-amber-400">
                      ₹{game.prizePool.toLocaleString("en-IN")}
                    </p>
                  </div>
                  <div className="text-right">
                    <span className="text-[10px] text-slate-400">Ticket</span>
                    <p className="font-bold text-emerald-400">₹{game.ticketPrice}</p>
                  </div>
                </div>
              </div>

              {/* Card Actions */}
              <div className="flex items-center justify-between pt-1 text-xs">
                {game.status === "Active" ? (
                  <span className="text-emerald-400 flex items-center gap-1 font-semibold">
                    <Play className="w-3.5 h-3.5 animate-pulse" />
                    Live calling in progress
                  </span>
                ) : (
                  <span className="text-slate-400">{game.time} Start time</span>
                )}

                <div className="flex items-center gap-1.5">
                  <button
                    onClick={() => alert(`Editing game ${game.gameCode}`)}
                    className="p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white transition-colors"
                    title="Edit Game"
                  >
                    <Edit className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() =>
                      setGames(games.filter((g) => g.id !== game.id))
                    }
                    className="p-1.5 rounded-lg bg-slate-800 hover:bg-rose-500/20 text-slate-300 hover:text-rose-400 transition-colors"
                    title="Delete Game"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Create Game Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-lg p-6 shadow-2xl space-y-4">
            <div className="flex items-center justify-between border-b border-slate-800 pb-3">
              <h3 className="text-lg font-bold text-white">Create Housie Room</h3>
              <button
                onClick={() => setShowCreateModal(false)}
                className="text-slate-400 hover:text-white text-sm"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateGame} className="space-y-3.5 text-xs">
              <div>
                <label className="block text-slate-300 font-medium mb-1">
                  Game Title / Name
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Super Jackpot Tambola"
                  value={newGame.name}
                  onChange={(e) => setNewGame({ ...newGame, name: e.target.value })}
                  className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none text-xs"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-medium mb-1">
                    Game Format
                  </label>
                  <select
                    value={newGame.gameType}
                    onChange={(e) =>
                      setNewGame({
                        ...newGame,
                        gameType: e.target.value as GameItem["gameType"],
                      })
                    }
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none text-xs"
                  >
                    <option value="Classic Housie">Classic Housie</option>
                    <option value="Speed 30">Speed 30</option>
                    <option value="Mega Jackpot">Mega Jackpot</option>
                    <option value="High Stakes">High Stakes</option>
                  </select>
                </div>

                <div>
                  <label className="block text-slate-300 font-medium mb-1">
                    Schedule
                  </label>
                  <input
                    type="text"
                    value={newGame.date}
                    onChange={(e) => setNewGame({ ...newGame, date: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none text-xs"
                  />
                </div>
              </div>

              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="block text-slate-300 font-medium mb-1">
                    Ticket Price (₹)
                  </label>
                  <input
                    type="number"
                    min={5}
                    value={newGame.ticketPrice}
                    onChange={(e) =>
                      setNewGame({ ...newGame, ticketPrice: Number(e.target.value) })
                    }
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none text-xs"
                  />
                </div>

                <div>
                  <label className="block text-slate-300 font-medium mb-1">
                    Max Capacity
                  </label>
                  <input
                    type="number"
                    min={10}
                    value={newGame.maxPlayers}
                    onChange={(e) =>
                      setNewGame({ ...newGame, maxPlayers: Number(e.target.value) })
                    }
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none text-xs"
                  />
                </div>

                <div>
                  <label className="block text-slate-300 font-medium mb-1">
                    Prize Pool (₹)
                  </label>
                  <input
                    type="number"
                    min={100}
                    value={newGame.prizePool}
                    onChange={(e) =>
                      setNewGame({ ...newGame, prizePool: Number(e.target.value) })
                    }
                    className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none text-xs"
                  />
                </div>
              </div>

              <div className="pt-3 flex justify-end gap-2 border-t border-slate-800">
                <button
                  type="button"
                  onClick={() => setShowCreateModal(false)}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl font-semibold shadow-lg shadow-indigo-600/30"
                >
                  Publish Game
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
