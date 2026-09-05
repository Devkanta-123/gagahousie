/**
 * Mock Data Repository for Gaga Housie Admin Panel
 * 
 * ORGANIZED STATIC/DEMO DATA
 * --------------------------
 * All demo records are centralized here rather than being hardcoded across components.
 * When backend/Supabase integration is added, replace these mock exports with
 * API queries and real-time Supabase subscriptions.
 */

export interface StatItem {
  id: string;
  title: string;
  value: string;
  rawValue?: number;
  change: string;
  isPositive: boolean;
  period: string;
  iconName: "gamepad" | "activity" | "check-circle" | "users" | "calendar" | "indian-rupee";
  colorTheme: "indigo" | "emerald" | "amber" | "blue" | "purple" | "rose";
}

export interface GameItem {
  id: string;
  gameCode: string;
  name: string;
  date: string;
  time: string;
  playersCount: number;
  maxPlayers: number;
  ticketPrice: number;
  prizePool: number;
  status: "Active" | "Completed" | "Upcoming" | "Cancelled";
  gameType: "Classic Housie" | "Speed 30" | "Mega Jackpot" | "High Stakes";
  numbersCalled?: number;
  winnerName?: string;
}

export interface PlayerItem {
  id: string;
  name: string;
  avatar: string;
  email: string;
  phone: string;
  gamesPlayed: number;
  totalWinnings: number;
  walletBalance: number;
  status: "Active" | "KYC Verified" | "Suspended" | "Pending KYC";
  joinedDate: string;
  lastActive: string;
}

export interface RevenueDataPoint {
  date: string;
  ticketSales: number;
  prizePayouts: number;
  netRevenue: number;
  activePlayers: number;
}

export interface WinnerItem {
  id: string;
  gameCode: string;
  gameName: string;
  playerName: string;
  playerAvatar: string;
  patternWon: "Early 5" | "Top Line" | "Middle Line" | "Bottom Line" | "Full House" | "Corner 4";
  prizeAmount: number;
  claimedAt: string;
  isVerified: boolean;
}

export interface TransactionItem {
  id: string;
  transactionRef: string;
  playerName: string;
  type: "Ticket Purchase" | "Prize Payout" | "Deposit" | "Withdrawal";
  amount: number;
  status: "Completed" | "Pending" | "Failed";
  date: string;
  paymentMethod: "UPI" | "Wallet" | "NetBanking" | "Card";
}

export interface NotificationItem {
  id: string;
  title: string;
  message: string;
  timestamp: string;
  type: "game" | "winner" | "payment" | "kyc" | "system";
  read: boolean;
}

// -------------------------------------------------------------
// DASHBOARD STATISTICS
// -------------------------------------------------------------
export const DASHBOARD_STATS: StatItem[] = [
  {
    id: "total-games",
    title: "Total Games",
    value: "128",
    rawValue: 128,
    change: "+12%",
    isPositive: true,
    period: "from last month",
    iconName: "gamepad",
    colorTheme: "indigo",
  },
  {
    id: "active-games",
    title: "Active Games",
    value: "12",
    rawValue: 12,
    change: "Live Now",
    isPositive: true,
    period: "3 filling fast",
    iconName: "activity",
    colorTheme: "emerald",
  },
  {
    id: "completed-games",
    title: "Completed Games",
    value: "116",
    rawValue: 116,
    change: "98.4%",
    isPositive: true,
    period: "completion rate",
    iconName: "check-circle",
    colorTheme: "blue",
  },
  {
    id: "total-players",
    title: "Total Players",
    value: "2,450",
    rawValue: 2450,
    change: "+180",
    isPositive: true,
    period: "new this week",
    iconName: "users",
    colorTheme: "purple",
  },
  {
    id: "todays-games",
    title: "Today's Games",
    value: "18",
    rawValue: 18,
    change: "6 Scheduled",
    isPositive: true,
    period: "next in 15m",
    iconName: "calendar",
    colorTheme: "amber",
  },
  {
    id: "todays-revenue",
    title: "Today's Revenue",
    value: "₹24,500",
    rawValue: 24500,
    change: "+8.4%",
    isPositive: true,
    period: "vs yesterday",
    iconName: "indian-rupee",
    colorTheme: "rose",
  },
];

// -------------------------------------------------------------
// RECENT GAMES
// -------------------------------------------------------------
export const RECENT_GAMES: GameItem[] = [
  {
    id: "g_1",
    gameCode: "GH-9042",
    name: "Mega Tambola Dhamaka",
    date: "Today, 08:30 PM",
    time: "20:30",
    playersCount: 94,
    maxPlayers: 100,
    ticketPrice: 100,
    prizePool: 50000,
    status: "Active",
    gameType: "Mega Jackpot",
    numbersCalled: 42,
  },
  {
    id: "g_2",
    gameCode: "GH-9041",
    name: "Super Sunday Jackpot",
    date: "Today, 07:00 PM",
    time: "19:00",
    playersCount: 150,
    maxPlayers: 150,
    ticketPrice: 200,
    prizePool: 75000,
    status: "Completed",
    gameType: "High Stakes",
    numbersCalled: 68,
    winnerName: "Rahul Sharma (Full House)",
  },
  {
    id: "g_3",
    gameCode: "GH-9040",
    name: "Quick Gold 50",
    date: "Today, 06:15 PM",
    time: "18:15",
    playersCount: 48,
    maxPlayers: 50,
    ticketPrice: 50,
    prizePool: 15000,
    status: "Completed",
    gameType: "Speed 30",
    numbersCalled: 35,
    winnerName: "Pooja Verma",
  },
  {
    id: "g_4",
    gameCode: "GH-9039",
    name: "Midnight Housie Blitz",
    date: "Today, 10:00 PM",
    time: "22:00",
    playersCount: 62,
    maxPlayers: 120,
    ticketPrice: 75,
    prizePool: 25000,
    status: "Upcoming",
    gameType: "Classic Housie",
  },
  {
    id: "g_5",
    gameCode: "GH-9038",
    name: "Weekend Royale 100",
    date: "Tomorrow, 04:00 PM",
    time: "16:00",
    playersCount: 18,
    maxPlayers: 100,
    ticketPrice: 150,
    prizePool: 40000,
    status: "Upcoming",
    gameType: "Classic Housie",
  },
  {
    id: "g_6",
    gameCode: "GH-9037",
    name: "Daily Express Housie",
    date: "Today, 04:30 PM",
    time: "16:30",
    playersCount: 80,
    maxPlayers: 80,
    ticketPrice: 30,
    prizePool: 12000,
    status: "Completed",
    gameType: "Speed 30",
    numbersCalled: 52,
    winnerName: "Vikram Patel",
  },
];

// -------------------------------------------------------------
// RECENT PLAYERS
// -------------------------------------------------------------
export const RECENT_PLAYERS: PlayerItem[] = [
  {
    id: "p_1",
    name: "Rahul Sharma",
    avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop&q=80",
    email: "rahul.sharma@example.com",
    phone: "+91 98765 43210",
    gamesPlayed: 42,
    totalWinnings: 34500,
    walletBalance: 8200,
    status: "KYC Verified",
    joinedDate: "12 Jan 2026",
    lastActive: "10 mins ago",
  },
  {
    id: "p_2",
    name: "Pooja Verma",
    avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80",
    email: "pooja.v@example.com",
    phone: "+91 98234 56789",
    gamesPlayed: 35,
    totalWinnings: 19800,
    walletBalance: 4150,
    status: "KYC Verified",
    joinedDate: "28 Jan 2026",
    lastActive: "25 mins ago",
  },
  {
    id: "p_3",
    name: "Vikram Patel",
    avatar: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&auto=format&fit=crop&q=80",
    email: "v.patel@example.com",
    phone: "+91 97123 45678",
    gamesPlayed: 28,
    totalWinnings: 14200,
    walletBalance: 1900,
    status: "Active",
    joinedDate: "03 Feb 2026",
    lastActive: "1 hour ago",
  },
  {
    id: "p_4",
    name: "Ananya Deshmukh",
    avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80",
    email: "ananya.d@example.com",
    phone: "+91 99887 76655",
    gamesPlayed: 19,
    totalWinnings: 8750,
    walletBalance: 3200,
    status: "KYC Verified",
    joinedDate: "15 Feb 2026",
    lastActive: "3 hours ago",
  },
  {
    id: "p_5",
    name: "Amit Kumar",
    avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop&q=80",
    email: "amit.k99@example.com",
    phone: "+91 98450 12345",
    gamesPlayed: 54,
    totalWinnings: 41200,
    walletBalance: 12500,
    status: "KYC Verified",
    joinedDate: "05 Jan 2026",
    lastActive: "Just now",
  },
  {
    id: "p_6",
    name: "Neha Reddy",
    avatar: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&auto=format&fit=crop&q=80",
    email: "neha.reddy@example.com",
    phone: "+91 97654 32109",
    gamesPlayed: 12,
    totalWinnings: 4500,
    walletBalance: 850,
    status: "Pending KYC",
    joinedDate: "20 Feb 2026",
    lastActive: "Yesterday",
  },
];

// -------------------------------------------------------------
// REVENUE OVERVIEW DATA
// -------------------------------------------------------------
export const REVENUE_CHART_DATA: RevenueDataPoint[] = [
  { date: "Mon", ticketSales: 18500, prizePayouts: 12000, netRevenue: 6500, activePlayers: 320 },
  { date: "Tue", ticketSales: 22400, prizePayouts: 14500, netRevenue: 7900, activePlayers: 380 },
  { date: "Wed", ticketSales: 19800, prizePayouts: 13200, netRevenue: 6600, activePlayers: 340 },
  { date: "Thu", ticketSales: 26500, prizePayouts: 17000, netRevenue: 9500, activePlayers: 450 },
  { date: "Fri", ticketSales: 34200, prizePayouts: 22000, netRevenue: 12200, activePlayers: 610 },
  { date: "Sat", ticketSales: 48900, prizePayouts: 31000, netRevenue: 17900, activePlayers: 890 },
  { date: "Sun", ticketSales: 56400, prizePayouts: 36500, netRevenue: 19900, activePlayers: 1040 },
];

export const MONTHLY_REVENUE_DATA: RevenueDataPoint[] = [
  { date: "Jan", ticketSales: 420000, prizePayouts: 280000, netRevenue: 140000, activePlayers: 1650 },
  { date: "Feb", ticketSales: 510000, prizePayouts: 335000, netRevenue: 175000, activePlayers: 1980 },
  { date: "Mar", ticketSales: 580000, prizePayouts: 380000, netRevenue: 200000, activePlayers: 2240 },
  { date: "Apr", ticketSales: 640000, prizePayouts: 415000, netRevenue: 225000, activePlayers: 2450 },
];

// -------------------------------------------------------------
// RECENT WINNERS
// -------------------------------------------------------------
export const RECENT_WINNERS: WinnerItem[] = [
  {
    id: "w_1",
    gameCode: "GH-9041",
    gameName: "Super Sunday Jackpot",
    playerName: "Rahul Sharma",
    playerAvatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop&q=80",
    patternWon: "Full House",
    prizeAmount: 35000,
    claimedAt: "Today, 07:42 PM",
    isVerified: true,
  },
  {
    id: "w_2",
    gameCode: "GH-9041",
    gameName: "Super Sunday Jackpot",
    playerName: "Ananya Deshmukh",
    playerAvatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop&q=80",
    patternWon: "Top Line",
    prizeAmount: 10000,
    claimedAt: "Today, 07:22 PM",
    isVerified: true,
  },
  {
    id: "w_3",
    gameCode: "GH-9040",
    gameName: "Quick Gold 50",
    playerName: "Pooja Verma",
    playerAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&auto=format&fit=crop&q=80",
    patternWon: "Early 5",
    prizeAmount: 5000,
    claimedAt: "Today, 06:28 PM",
    isVerified: true,
  },
  {
    id: "w_4",
    gameCode: "GH-9037",
    gameName: "Daily Express Housie",
    playerName: "Vikram Patel",
    playerAvatar: "https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100&auto=format&fit=crop&q=80",
    patternWon: "Bottom Line",
    prizeAmount: 4000,
    claimedAt: "Today, 04:51 PM",
    isVerified: true,
  },
];

// -------------------------------------------------------------
// TRANSACTIONS DATA
// -------------------------------------------------------------
export const RECENT_TRANSACTIONS: TransactionItem[] = [
  {
    id: "tx_1",
    transactionRef: "TXN-8849201",
    playerName: "Rahul Sharma",
    type: "Prize Payout",
    amount: 35000,
    status: "Completed",
    date: "Today, 07:45 PM",
    paymentMethod: "UPI",
  },
  {
    id: "tx_2",
    transactionRef: "TXN-8849198",
    playerName: "Amit Kumar",
    type: "Deposit",
    amount: 5000,
    status: "Completed",
    date: "Today, 07:30 PM",
    paymentMethod: "UPI",
  },
  {
    id: "tx_3",
    transactionRef: "TXN-8849150",
    playerName: "Neha Reddy",
    type: "Ticket Purchase",
    amount: 200,
    status: "Completed",
    date: "Today, 07:15 PM",
    paymentMethod: "Wallet",
  },
  {
    id: "tx_4",
    transactionRef: "TXN-8848992",
    playerName: "Pooja Verma",
    type: "Withdrawal",
    amount: 10000,
    status: "Pending",
    date: "Today, 06:40 PM",
    paymentMethod: "NetBanking",
  },
  {
    id: "tx_5",
    transactionRef: "TXN-8848721",
    playerName: "Vikram Patel",
    type: "Deposit",
    amount: 2500,
    status: "Completed",
    date: "Today, 05:10 PM",
    paymentMethod: "Card",
  },
];

// -------------------------------------------------------------
// NOTIFICATIONS
// -------------------------------------------------------------
export const ADMIN_NOTIFICATIONS: NotificationItem[] = [
  {
    id: "notif_1",
    title: "Full House Claimed",
    message: "Rahul Sharma claimed Full House in Super Sunday Jackpot (₹35,000)",
    timestamp: "12m ago",
    type: "winner",
    read: false,
  },
  {
    id: "notif_2",
    title: "High Value Deposit",
    message: "Amit Kumar deposited ₹5,000 via UPI",
    timestamp: "35m ago",
    type: "payment",
    read: false,
  },
  {
    id: "notif_3",
    title: "Game Reached 90% Capacity",
    message: "Mega Tambola Dhamaka has 94/100 players registered",
    timestamp: "1h ago",
    type: "game",
    read: false,
  },
  {
    id: "notif_4",
    title: "KYC Verification Submitted",
    message: "Neha Reddy submitted documents for KYC verification",
    timestamp: "2h ago",
    type: "kyc",
    read: true,
  },
];
