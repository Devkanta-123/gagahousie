"use client";

import React, { useState } from "react";
import {
  Trophy,
  Search,
  CheckCircle2,
  Download,
} from "lucide-react";
import { RECENT_WINNERS } from "@/lib/mock-data";
import { Button } from "@/components/ui/Button";

export default function WinnersPage() {
  const [winners] = useState(RECENT_WINNERS);
  const [search, setSearch] = useState("");

  const filteredWinners = winners.filter(
    (w) =>
      w.playerName.toLowerCase().includes(search.toLowerCase()) ||
      w.gameName.toLowerCase().includes(search.toLowerCase()) ||
      w.patternWon.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            Winners & Claim Settlements
          </h2>
          <p className="text-xs text-slate-400">
            Verify Housie ticket winning patterns and oversee automatic prize credit payouts
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="md"
            leftIcon={<Download className="w-4 h-4" />}
            onClick={() => alert("Exporting winners report...")}
          >
            Export Ledger
          </Button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-4 flex items-center justify-between shadow-lg">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search winner name, game, or winning pattern..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-800/50 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-amber-500"
          />
        </div>
      </div>

      {/* Winners List Table */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg overflow-x-auto">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-800/40 text-[11px] font-semibold uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <tr>
              <th className="py-3.5 px-3">Winner Player</th>
              <th className="py-3.5 px-3">Game Details</th>
              <th className="py-3.5 px-3">Pattern Claimed</th>
              <th className="py-3.5 px-3">Prize Amount</th>
              <th className="py-3.5 px-3">Claim Timestamp</th>
              <th className="py-3.5 px-3">Verification</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filteredWinners.map((winner) => (
              <tr
                key={winner.id}
                className="hover:bg-slate-800/30 transition-colors group"
              >
                <td className="py-3.5 px-3 whitespace-nowrap">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-full bg-gradient-to-tr from-amber-500 to-amber-600 flex items-center justify-center font-bold text-slate-950 text-xs shadow-md">
                      {winner.playerName.charAt(0)}
                    </div>
                    <span className="font-bold text-white text-sm group-hover:text-amber-300 transition-colors">
                      {winner.playerName}
                    </span>
                  </div>
                </td>

                <td className="py-3.5 px-3">
                  <div className="flex flex-col">
                    <span className="text-white font-medium">{winner.gameName}</span>
                    <span className="text-indigo-400 font-mono text-[11px]">
                      #{winner.gameCode}
                    </span>
                  </div>
                </td>

                <td className="py-3.5 px-3 whitespace-nowrap">
                  <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-amber-500/10 text-amber-300 font-semibold border border-amber-500/20">
                    <Trophy className="w-3.5 h-3.5" />
                    {winner.patternWon}
                  </span>
                </td>

                <td className="py-3.5 px-3 whitespace-nowrap">
                  <span className="text-sm font-bold text-emerald-400">
                    ₹{winner.prizeAmount.toLocaleString("en-IN")}
                  </span>
                </td>

                <td className="py-3.5 px-3 whitespace-nowrap text-slate-400">
                  {winner.claimedAt}
                </td>

                <td className="py-3.5 px-3 whitespace-nowrap">
                  <span className="inline-flex items-center gap-1 text-emerald-400 text-xs font-semibold bg-emerald-500/10 px-2 py-0.5 rounded-md border border-emerald-500/20">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    Verified & Credited
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
