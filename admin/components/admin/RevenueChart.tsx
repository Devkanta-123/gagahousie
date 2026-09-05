"use client";

import React, { useState } from "react";
import {
  BarChart3,
  ArrowUpRight,
} from "lucide-react";
import { REVENUE_CHART_DATA, MONTHLY_REVENUE_DATA, RevenueDataPoint } from "@/lib/mock-data";

export function RevenueChart() {
  const [period, setPeriod] = useState<"weekly" | "monthly">("weekly");
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);

  const data: RevenueDataPoint[] =
    period === "weekly" ? REVENUE_CHART_DATA : MONTHLY_REVENUE_DATA;

  // Calculate totals and max values for SVG scaling
  const maxTicketSales = Math.max(...data.map((d) => d.ticketSales));
  const maxPayouts = Math.max(...data.map((d) => d.prizePayouts));
  const maxValue = Math.max(maxTicketSales, maxPayouts) * 1.15; // with padding

  const totalTicketSales = data.reduce((acc, curr) => acc + curr.ticketSales, 0);
  const totalPayouts = data.reduce((acc, curr) => acc + curr.prizePayouts, 0);
  const totalNetRevenue = data.reduce((acc, curr) => acc + curr.netRevenue, 0);

  // SVG dimensions
  const svgWidth = 600;
  const svgHeight = 220;
  const paddingX = 40;
  const paddingY = 30;
  const chartWidth = svgWidth - paddingX * 2;
  const chartHeight = svgHeight - paddingY * 2;

  // Compute points for SVG paths
  const getCoordinates = (val: number, index: number) => {
    const x = paddingX + (index / (data.length - 1)) * chartWidth;
    const y = svgHeight - paddingY - (val / maxValue) * chartHeight;
    return { x, y };
  };

  const salesPoints = data.map((d, i) => getCoordinates(d.ticketSales, i));
  const payoutPoints = data.map((d, i) => getCoordinates(d.prizePayouts, i));

  // Build SVG path strings
  const buildSmoothPath = (points: { x: number; y: number }[]) => {
    if (points.length === 0) return "";
    let d = `M ${points[0].x},${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const p0 = points[i];
      const p1 = points[i + 1];
      const cx = (p0.x + p1.x) / 2;
      d += ` C ${cx},${p0.y} ${cx},${p1.y} ${p1.x},${p1.y}`;
    }
    return d;
  };

  const salesLinePath = buildSmoothPath(salesPoints);
  const payoutLinePath = buildSmoothPath(payoutPoints);

  const salesAreaPath =
    salesPoints.length > 0
      ? `${salesLinePath} L ${salesPoints[salesPoints.length - 1].x},${
          svgHeight - paddingY
        } L ${salesPoints[0].x},${svgHeight - paddingY} Z`
      : "";

  const activePoint =
    hoveredIndex !== null ? data[hoveredIndex] : data[data.length - 1];

  return (
    <div className="bg-slate-900/80 border border-slate-800 rounded-2xl p-5 shadow-lg flex flex-col">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-800">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400">
            <BarChart3 className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-white tracking-tight flex items-center gap-2">
              Revenue Overview
              <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
                <ArrowUpRight className="w-3 h-3" />
                +14.8% growth
              </span>
            </h2>
            <p className="text-xs text-slate-400">
              Ticket collections vs prize payouts and net platform profit
            </p>
          </div>
        </div>

        {/* Period Selector Tabs */}
        <div className="flex items-center gap-1 bg-slate-800/60 p-1 rounded-xl border border-slate-700/60 self-start sm:self-auto">
          <button
            onClick={() => setPeriod("weekly")}
            className={`px-3 py-1 text-xs font-medium rounded-lg transition-all ${
              period === "weekly"
                ? "bg-indigo-600 text-white shadow-sm"
                : "text-slate-400 hover:text-slate-200"
            }`}
          >
            Last 7 Days
          </button>
          <button
            onClick={() => setPeriod("monthly")}
            className={`px-3 py-1 text-xs font-medium rounded-lg transition-all ${
              period === "monthly"
                ? "bg-indigo-600 text-white shadow-sm"
                : "text-slate-400 hover:text-slate-200"
            }`}
          >
            Monthly
          </button>
        </div>
      </div>

      {/* Metric Quick Badges */}
      <div className="grid grid-cols-3 gap-2.5 py-4 border-b border-slate-800/60 text-xs">
        <div className="bg-slate-800/30 p-2.5 rounded-xl border border-slate-800/80">
          <div className="flex items-center gap-1.5 text-slate-400 text-[11px]">
            <span className="w-2 h-2 rounded-full bg-indigo-500" />
            <span>Ticket Sales</span>
          </div>
          <p className="text-sm sm:text-base font-bold text-white mt-1">
            ₹{totalTicketSales.toLocaleString("en-IN")}
          </p>
        </div>

        <div className="bg-slate-800/30 p-2.5 rounded-xl border border-slate-800/80">
          <div className="flex items-center gap-1.5 text-slate-400 text-[11px]">
            <span className="w-2 h-2 rounded-full bg-amber-500" />
            <span>Prize Payouts</span>
          </div>
          <p className="text-sm sm:text-base font-bold text-white mt-1">
            ₹{totalPayouts.toLocaleString("en-IN")}
          </p>
        </div>

        <div className="bg-slate-800/30 p-2.5 rounded-xl border border-slate-800/80">
          <div className="flex items-center gap-1.5 text-slate-400 text-[11px]">
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            <span>Platform Margin</span>
          </div>
          <p className="text-sm sm:text-base font-bold text-emerald-400 mt-1">
            ₹{totalNetRevenue.toLocaleString("en-IN")}
          </p>
        </div>
      </div>

      {/* SVG Chart Container */}
      <div className="pt-2 relative">
        <svg
          viewBox={`0 0 ${svgWidth} ${svgHeight}`}
          className="w-full h-48 sm:h-56 overflow-visible"
        >
          <defs>
            <linearGradient id="salesGrad" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#6366f1" stopOpacity="0.4" />
              <stop offset="100%" stopColor="#6366f1" stopOpacity="0.0" />
            </linearGradient>
            <linearGradient id="payoutGrad" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#f59e0b" stopOpacity="0.3" />
              <stop offset="100%" stopColor="#f59e0b" stopOpacity="0.0" />
            </linearGradient>
          </defs>

          {/* Grid lines */}
          {[0.25, 0.5, 0.75, 1].map((ratio, i) => {
            const y = svgHeight - paddingY - ratio * chartHeight;
            return (
              <g key={i}>
                <line
                  x1={paddingX}
                  y1={y}
                  x2={svgWidth - paddingX}
                  y2={y}
                  stroke="#334155"
                  strokeDasharray="4 4"
                  strokeOpacity="0.4"
                />
                <text
                  x={paddingX - 6}
                  y={y + 3}
                  textAnchor="end"
                  fill="#64748b"
                  fontSize="9"
                >
                  ₹{Math.round((maxValue * ratio) / 1000)}k
                </text>
              </g>
            );
          })}

          {/* Sales Area Fill */}
          <path d={salesAreaPath} fill="url(#salesGrad)" />

          {/* Sales Line */}
          <path
            d={salesLinePath}
            fill="none"
            stroke="#6366f1"
            strokeWidth="3"
            strokeLinecap="round"
          />

          {/* Payout Line */}
          <path
            d={payoutLinePath}
            fill="none"
            stroke="#f59e0b"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeDasharray="6 3"
          />

          {/* Data Points and Interaction Circles */}
          {data.map((d, i) => {
            const sPt = salesPoints[i];
            const isHovered = hoveredIndex === i;

            return (
              <g key={i}>
                {isHovered && (
                  <line
                    x1={sPt.x}
                    y1={paddingY}
                    x2={sPt.x}
                    y2={svgHeight - paddingY}
                    stroke="#818cf8"
                    strokeWidth="1.5"
                    strokeDasharray="3 3"
                  />
                )}

                <circle
                  cx={sPt.x}
                  cy={sPt.y}
                  r={isHovered ? 6 : 4}
                  fill="#0f172a"
                  stroke="#6366f1"
                  strokeWidth={isHovered ? 3 : 2}
                  className="transition-all duration-150"
                />

                <rect
                  x={sPt.x - 20}
                  y={0}
                  width="40"
                  height={svgHeight}
                  fill="transparent"
                  className="cursor-pointer"
                  onMouseEnter={() => setHoveredIndex(i)}
                  onMouseLeave={() => setHoveredIndex(null)}
                />

                <text
                  x={sPt.x}
                  y={svgHeight - 10}
                  textAnchor="middle"
                  fill={isHovered ? "#ffffff" : "#94a3b8"}
                  fontWeight={isHovered ? "bold" : "normal"}
                  fontSize="11"
                >
                  {d.date}
                </text>
              </g>
            );
          })}
        </svg>

        {activePoint && (
          <div className="mt-2 bg-slate-800/80 border border-slate-700/80 rounded-xl p-2.5 flex items-center justify-between text-xs backdrop-blur-sm">
            <span className="font-semibold text-white">
              {activePoint.date} Summary:
            </span>
            <div className="flex items-center gap-4">
              <span className="text-indigo-400">
                Sales: <strong>₹{activePoint.ticketSales.toLocaleString("en-IN")}</strong>
              </span>
              <span className="text-amber-400">
                Payouts: <strong>₹{activePoint.prizePayouts.toLocaleString("en-IN")}</strong>
              </span>
              <span className="text-emerald-400">
                Net: <strong>₹{activePoint.netRevenue.toLocaleString("en-IN")}</strong>
              </span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
