"use client";

import React, { useState } from "react";
import {
  Search,
  Download,
} from "lucide-react";
import { RECENT_TRANSACTIONS, TransactionItem } from "@/lib/mock-data";
import { Badge } from "@/components/ui/Badge";
import { Button } from "@/components/ui/Button";

export default function TransactionsPage() {
  const [transactions] = useState<TransactionItem[]>(RECENT_TRANSACTIONS);
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState("All");

  const filteredTransactions = transactions.filter((t) => {
    const matchesFilter = filter === "All" ? true : t.type.toLowerCase().includes(filter.toLowerCase());
    const matchesSearch =
      t.playerName.toLowerCase().includes(search.toLowerCase()) ||
      t.transactionRef.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            Financial Ledger & Transactions
          </h2>
          <p className="text-xs text-slate-400">
            Real-time audit log of wallet deposits, ticket purchases, withdrawals, and game winnings
          </p>
        </div>

        <Button
          variant="outline"
          size="md"
          leftIcon={<Download className="w-4 h-4" />}
          onClick={() => alert("Downloading transaction CSV report...")}
        >
          Download CSV
        </Button>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-4 flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 shadow-lg">
        <div className="flex items-center gap-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/60 overflow-x-auto">
          {["All", "Deposit", "Ticket Purchase", "Prize Payout", "Withdrawal"].map((tab) => (
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
            placeholder="Search reference # or player..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full sm:w-64 pl-9 pr-4 py-2 bg-slate-800/50 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg overflow-x-auto">
        <table className="w-full text-left text-xs text-slate-300">
          <thead className="bg-slate-800/40 text-[11px] font-semibold uppercase tracking-wider text-slate-400 border-b border-slate-800">
            <tr>
              <th className="py-3.5 px-3">Transaction Ref</th>
              <th className="py-3.5 px-3">Player Name</th>
              <th className="py-3.5 px-3">Type</th>
              <th className="py-3.5 px-3">Amount</th>
              <th className="py-3.5 px-3">Method</th>
              <th className="py-3.5 px-3">Status</th>
              <th className="py-3.5 px-3 text-right">Timestamp</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-800/60">
            {filteredTransactions.map((tx) => (
              <tr key={tx.id} className="hover:bg-slate-800/30 transition-colors">
                <td className="py-3.5 px-3 font-mono font-semibold text-indigo-400 whitespace-nowrap">
                  {tx.transactionRef}
                </td>
                <td className="py-3.5 px-3 font-bold text-white whitespace-nowrap">
                  {tx.playerName}
                </td>
                <td className="py-3.5 px-3 whitespace-nowrap">
                  <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-800 border border-slate-700">
                    {tx.type}
                  </span>
                </td>
                <td className="py-3.5 px-3 font-bold text-sm whitespace-nowrap">
                  <span
                    className={
                      tx.type === "Deposit" || tx.type === "Ticket Purchase"
                        ? "text-white"
                        : "text-emerald-400"
                    }
                  >
                    ₹{tx.amount.toLocaleString("en-IN")}
                  </span>
                </td>
                <td className="py-3.5 px-3 text-slate-400 whitespace-nowrap">
                  {tx.paymentMethod}
                </td>
                <td className="py-3.5 px-3 whitespace-nowrap">
                  <Badge variant={tx.status}>{tx.status}</Badge>
                </td>
                <td className="py-3.5 px-3 text-right text-slate-400 whitespace-nowrap">
                  {tx.date}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
