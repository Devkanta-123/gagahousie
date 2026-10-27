import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/tambola_ticket_model.dart';
import '../services/supabase_service.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  Set<String> _ticketIdsWithTambola = {};
  List<Map<String, dynamic>> _recentWinners = [];
  bool _isLoading = false;
  String? _errorMessage;
  final List<RealtimeChannel> _activeChannels = [];
  Timer? _fallbackTimer;

  List<TicketModel> get tickets => _tickets;
  List<Map<String, dynamic>> get recentWinners => _recentWinners;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Flat list of individual recent winners for ResultsTab, showing the real user name
  List<Map<String, String>> get recentWinnersFlatList {
    final List<Map<String, String>> flat = [];
    for (final game in _recentWinners) {
      final gameTitle = game['ticket']?.toString() ?? 'GaGa Housie';
      final date = game['date']?.toString() ?? '';
      final prizes = game['prizes'];
      if (prizes is List) {
        for (final p in prizes) {
          if (p is Map) {
            final winnerName = p['winner_name']?.toString() ??
                p['winner']?.toString() ??
                'Player';
            final slNo = p['sl_no']?.toString() ?? '';
            final displayWinner =
                slNo.isNotEmpty ? '$winnerName (SL #$slNo)' : winnerName;
            flat.add({
              'game': '$gameTitle - ${p['name'] ?? 'Prize'}',
              'prize': p['price']?.toString() ?? '₹0',
              'date': date,
              'winner': displayWinner,
              'winner_name': winnerName,
              'sl_no': slNo,
            });
          }
        }
      }
    }
    return flat;
  }

  /// Check if a draw ticket has tambola numbers configured
  bool hasTambolaTickets(String ticketId) {
    if (_ticketIdsWithTambola.contains(ticketId)) return true;
    final clean = ticketId.replaceAll(RegExp(r'[\s\-_#]'), '').toLowerCase();
    if (_ticketIdsWithTambola.any((id) =>
        id.replaceAll(RegExp(r'[\s\-_#]'), '').toLowerCase() == clean)) {
      return true;
    }
    final cached = getCachedTambolaTickets(ticketId);
    return cached != null && cached.any((t) => t.filledNumbersCount > 0);
  }

  /// All tickets that have tambola tickets configured with numbers
  List<TicketModel> get ticketsWithTambola {
    return _tickets.where((t) => hasTambolaTickets(t.ticketId)).toList();
  }

  /// Set the configured tambola ticket IDs directly (useful for tests or demo)
  void setTicketIdsWithTambola(Set<String> ids) {
    _ticketIdsWithTambola = Set.from(ids);
    notifyListeners();
  }

  /// Returns maps compatible with HomeTab upcoming ticket carousel.
  /// Shows ONLY tickets that have tambola tickets configured.
  /// Shows 0 records (empty list) when DB is empty - NEVER falls back to dummy data!
  List<Map<String, dynamic>> get upcomingTicketsMap {
    return ticketsWithTambola.map((t) => t.toUpcomingMap()).toList();
  }

  /// Returns maps compatible with TicketsTab live tickets list.
  /// Shows ONLY tickets that have tambola tickets configured.
  /// Shows 0 records (empty list) when DB is empty - NEVER falls back to dummy data!
  List<Map<String, String>> get liveTicketsMap {
    return ticketsWithTambola.map((t) => t.toLiveTicketMap()).toList();
  }

  int get totalTicketsCount => _tickets.length;

  int get activeDrawsCount =>
      _tickets.where((t) => t.status.toLowerCase() == 'active').length;

  int get totalPrizePoolValue {
    int total = 0;
    for (final ticket in _tickets) {
      total += ticket.calculatedTotalPrize;
    }
    return total;
  }

  String get formattedTotalPrizePool {
    final val = totalPrizePoolValue;
    return '₹${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  String get nextTicketId => TicketService.instance.generateNextId(_tickets);

  /// Sets up instant real-time subscription for tickets and tambola tickets
  void initRealtimeSubscription() {
    final client = SupabaseService.instance.client;
    if (client == null || _activeChannels.isNotEmpty) return;

    try {
      // 1. ISOLATED CDC: tickets
      _subscribeTable(
        table: 'tickets',
        onPayload: (payload) {
          debugPrint('🔔 [REALTIME TICKETS CDC] ${payload.eventType} => new:${payload.newRecord} old:${payload.oldRecord}');
          if (payload.eventType == PostgresChangeEvent.delete) {
            final oldTicketId = payload.oldRecord['ticket_id']?.toString();
            if (oldTicketId != null) {
              _tickets.removeWhere((t) => t.ticketId == oldTicketId);
              _tambolaTicketsCache.remove(oldTicketId);
              _ticketIdsWithTambola.remove(oldTicketId);
              notifyListeners();
            } else {
              _tickets.clear();
              _tambolaTicketsCache.clear();
              _ticketIdsWithTambola.clear();
              notifyListeners();
            }
          }
          fetchTickets();
        },
      );

      // 2. ISOLATED CDC: tambola_tickets
      _subscribeTable(
        table: 'tambola_tickets',
        onPayload: (payload) {
          debugPrint('🔔 [REALTIME TAMBOLA CDC] ${payload.eventType}');
          if (payload.eventType == PostgresChangeEvent.delete) {
            final oldDrawId = payload.oldRecord['ticket_id']?.toString();
            if (oldDrawId != null) {
              _tambolaTicketsCache.remove(oldDrawId);
              _ticketIdsWithTambola.remove(oldDrawId);
              notifyListeners();
            } else {
              _tambolaTicketsCache.clear();
              _ticketIdsWithTambola.clear();
              notifyListeners();
            }
          }
          fetchTickets();
        },
      );
    } catch (e) {
      debugPrint('ℹ️ [TICKETS REALTIME NOTICE] $e');
    }
  }

  void _subscribeTable({
    required String table,
    required void Function(PostgresChangePayload payload) onPayload,
  }) {
    final client = SupabaseService.instance.client;
    if (client == null) return;

    try {
      final channel = client.channel('gaga_tickets_$table');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: onPayload,
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint('ℹ️ [REALTIME NOTICE] "$table" is not in supabase_realtime publication yet. Polling fallback active.');
          _startFallbackPolling();
        } else if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('✅ [REALTIME TICKETS CDC SUBSCRIBED] $table');
        }
      });

      _activeChannels.add(channel);
    } catch (e) {
      debugPrint('ℹ️ [TICKET CDC SUBSCRIBE NOTICE] $table: $e');
    }
  }

  void _startFallbackPolling() {
    if (_fallbackTimer != null && _fallbackTimer!.isActive) return;
    _fallbackTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      fetchTickets();
    });
  }

  @override
  void dispose() {
    for (final ch in _activeChannels) {
      try {
        ch.unsubscribe();
      } catch (_) {}
    }
    _activeChannels.clear();
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    super.dispose();
  }

  /// Fetch tickets from Supabase DB
  Future<void> fetchTickets() async {
    initRealtimeSubscription();
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await TicketService.instance.fetchTickets();
      _tickets = fetched;

      final ids = await TicketService.instance.fetchTicketIdsWithTambola();
      _ticketIdsWithTambola = ids;

      // Also merge any locally cached tambola tickets that have numbers
      for (final entry in _tambolaTicketsCache.entries) {
        if (entry.value.any((t) => t.filledNumbersCount > 0)) {
          _ticketIdsWithTambola.add(entry.key);
        }
      }

      // Fetch recent winners from real DB
      try {
        _recentWinners = await TicketService.instance.fetchRecentWinners();
      } catch (we) {
        debugPrint('⚠️ [WINNERS FETCH NOTICE] $we');
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// On-demand refresh of recent winners from real Supabase DB
  Future<void> fetchRecentWinners() async {
    try {
      final fetched = await TicketService.instance.fetchRecentWinners();
      _recentWinners = fetched;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [PROVIDER RECENT WINNERS ERROR] $e');
    }
  }

  /// Create and add new ticket to DB and local state
  Future<bool> createTicket(TicketModel ticket) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await TicketService.instance.createTicket(ticket);
      _tickets.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing ticket in DB and update local state instantly
  Future<bool> updateTicket(TicketModel ticket) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await TicketService.instance.updateTicket(ticket);
      final index = _tickets.indexWhere((t) => t.ticketId == ticket.ticketId);
      if (index != -1) {
        _tickets[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Remove ticket by ticketId
  Future<bool> deleteTicket(String ticketId) async {
    final success = await TicketService.instance.deleteTicket(ticketId);
    if (success) {
      _tickets.removeWhere((t) => t.ticketId == ticketId);
      _tambolaTicketsCache.remove(ticketId);
      _ticketIdsWithTambola.remove(ticketId);
      notifyListeners();
    }
    return success;
  }

  /// Set local tickets list directly (useful for testing or initial state)
  void setTickets(List<TicketModel> tickets) {
    _tickets = List.from(tickets);
    notifyListeners();
  }

  // Tambola tickets cache keyed by ticketId
  final Map<String, List<TambolaTicketModel>> _tambolaTicketsCache = {};

  List<TambolaTicketModel>? getCachedTambolaTickets(String ticketId) {
    if (_tambolaTicketsCache.containsKey(ticketId)) {
      return _tambolaTicketsCache[ticketId];
    }
    final clean = ticketId.replaceAll(RegExp(r'[\s\-_#]'), '').toLowerCase();
    for (final entry in _tambolaTicketsCache.entries) {
      final entryClean =
          entry.key.replaceAll(RegExp(r'[\s\-_#]'), '').toLowerCase();
      if (entryClean == clean) {
        return entry.value;
      }
    }
    return null;
  }

  /// Fetch tambola tickets for a draw ticket
  Future<List<TambolaTicketModel>> fetchTambolaTickets(String ticketId) async {
    final cleanId =
        ticketId.startsWith('#') ? ticketId.substring(1).trim() : ticketId.trim();
    final fetched = await TicketService.instance.fetchTambolaTickets(cleanId);
    if (fetched.isNotEmpty) {
      _tambolaTicketsCache[ticketId] = fetched;
      _tambolaTicketsCache[cleanId] = fetched;
      if (fetched.any((t) => t.filledNumbersCount > 0)) {
        _ticketIdsWithTambola.add(ticketId);
        _ticketIdsWithTambola.add(cleanId);
      }
      notifyListeners();
    }
    return fetched;
  }

  /// Save or update tambola tickets for a draw ticket
  Future<bool> saveTambolaTickets(
      String ticketId, List<TambolaTicketModel> tickets) async {
    _isLoading = true;
    notifyListeners();

    final success =
        await TicketService.instance.saveTambolaTickets(ticketId, tickets);
    if (success) {
      _tambolaTicketsCache[ticketId] = List.from(tickets);
      if (tickets.any((t) => t.filledNumbersCount > 0)) {
        _ticketIdsWithTambola.add(ticketId);
      } else {
        _ticketIdsWithTambola.remove(ticketId);
      }
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Store tambola tickets in cache directly (for testing or fast navigation)
  void setCachedTambolaTickets(
      String ticketId, List<TambolaTicketModel> tickets) {
    _tambolaTicketsCache[ticketId] = List.from(tickets);
    if (tickets.any((t) => t.filledNumbersCount > 0)) {
      _ticketIdsWithTambola.add(ticketId);
    } else {
      _ticketIdsWithTambola.remove(ticketId);
    }
    notifyListeners();
  }
}
