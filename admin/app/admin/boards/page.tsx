"use client";

import React, { useState, useEffect, useCallback } from "react";
import {
  Play,
  Pause,
  RotateCcw,
  Volume2,
  VolumeX,
} from "lucide-react";
import { Button } from "@/components/ui/Button";

export default function HousieBoardsPage() {
  const [calledNumbers, setCalledNumbers] = useState<number[]>([
    7, 14, 23, 31, 42, 55, 68, 79, 88, 90, 3, 19, 27, 45, 62, 73,
  ]);
  const [currentNumber, setCurrentNumber] = useState<number | null>(73);
  const [autoPlay, setAutoPlay] = useState(false);
  const [audioMuted, setAudioMuted] = useState(false);

  const callNextRandomNumber = useCallback(() => {
    const uncalled = Array.from({ length: 90 }, (_, i) => i + 1).filter(
      (n) => !calledNumbers.includes(n)
    );

    if (uncalled.length === 0) {
      setAutoPlay(false);
      alert("All 90 numbers have been called!");
      return;
    }

    const next = uncalled[Math.floor(Math.random() * uncalled.length)];
    setCalledNumbers((prev) => [...prev, next]);
    setCurrentNumber(next);
  }, [calledNumbers]);

  // Auto caller timer
  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (autoPlay) {
      timer = setInterval(() => {
        callNextRandomNumber();
      }, 3000);
    }
    return () => clearInterval(timer);
  }, [autoPlay, callNextRandomNumber]);

  const resetBoard = () => {
    if (confirm("Reset current Housie game board?")) {
      setCalledNumbers([]);
      setCurrentNumber(null);
      setAutoPlay(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight">
            Housie Boards & Live Number Caller
          </h2>
          <p className="text-xs text-slate-400">
            Official 1-90 board visualization and live number generator control for Game #GH-9042
          </p>
        </div>

        {/* Board Controls */}
        <div className="flex items-center gap-2">
          <Button
            variant={autoPlay ? "danger" : "primary"}
            size="md"
            onClick={() => setAutoPlay(!autoPlay)}
            leftIcon={autoPlay ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
          >
            {autoPlay ? "Pause Auto Caller" : "Start Auto Caller (3s)"}
          </Button>

          <Button
            variant="secondary"
            size="md"
            onClick={callNextRandomNumber}
            disabled={autoPlay}
          >
            Call Single
          </Button>

          <Button
            variant="outline"
            size="md"
            onClick={resetBoard}
            leftIcon={<RotateCcw className="w-4 h-4" />}
          >
            Reset
          </Button>
        </div>
      </div>

      {/* Main Board Grid and Caller Spotlight */}
      <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
        {/* Number Spotlight Banner */}
        <div className="lg:col-span-1 bg-slate-900/90 border border-slate-800 rounded-3xl p-6 shadow-xl flex flex-col items-center justify-center text-center space-y-4">
          <span className="text-xs font-semibold uppercase tracking-wider text-indigo-400">
            Last Number Called
          </span>

          <div className="w-32 h-32 rounded-3xl bg-gradient-to-br from-amber-400 via-amber-500 to-amber-600 flex items-center justify-center text-slate-950 font-black text-6xl shadow-2xl shadow-amber-500/30 ring-8 ring-amber-500/20">
            {currentNumber ?? "--"}
          </div>

          <div className="space-y-1">
            <p className="text-sm font-bold text-white">
              {calledNumbers.length} / 90 Numbers Called
            </p>
            <p className="text-xs text-slate-400">
              {90 - calledNumbers.length} remaining in basket
            </p>
          </div>

          {/* Quick Audio Mute */}
          <button
            onClick={() => setAudioMuted(!audioMuted)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 rounded-xl text-xs text-slate-300 transition-colors"
          >
            {audioMuted ? <VolumeX className="w-3.5 h-3.5 text-rose-400" /> : <Volume2 className="w-3.5 h-3.5 text-emerald-400" />}
            <span>{audioMuted ? "Sound Muted" : "Voice Sound On"}</span>
          </button>
        </div>

        {/* 1-90 Interactive Grid */}
        <div className="lg:col-span-3 bg-slate-900/90 border border-slate-800 rounded-3xl p-6 shadow-xl">
          <div className="flex items-center justify-between pb-4 border-b border-slate-800 mb-4">
            <h3 className="font-bold text-sm text-white">
              Official 90 Numbers Board
            </h3>
            <div className="flex items-center gap-3 text-xs">
              <span className="flex items-center gap-1.5 text-amber-400">
                <span className="w-3 h-3 rounded-md bg-amber-500" />
                Called
              </span>
              <span className="flex items-center gap-1.5 text-slate-400">
                <span className="w-3 h-3 rounded-md bg-slate-800 border border-slate-700" />
                Pending
              </span>
            </div>
          </div>

          {/* 10 x 9 Grid */}
          <div className="grid grid-cols-10 gap-2">
            {Array.from({ length: 90 }, (_, i) => i + 1).map((num) => {
              const isCalled = calledNumbers.includes(num);
              const isLatest = currentNumber === num;

              return (
                <div
                  key={num}
                  className={`h-9 sm:h-11 rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center transition-all ${
                    isLatest
                      ? "bg-amber-400 text-slate-950 ring-4 ring-amber-400/30 scale-105 shadow-lg font-black"
                      : isCalled
                      ? "bg-indigo-600 text-white shadow-md shadow-indigo-600/30 border border-indigo-400/40"
                      : "bg-slate-800/60 text-slate-400 border border-slate-700/50 hover:border-slate-600"
                  }`}
                >
                  {num}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
