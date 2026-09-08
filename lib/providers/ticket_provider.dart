import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns maps compatible with HomeTab upcoming ticket carousel
  List<Map<String, dynamic>> get upcomingTicketsMap {
    if (_tickets.isEmpty) {
      return TicketService.defaultInitialTickets()
          .map((t) => t.toUpcomingMap())
          .toList();
    }
    return _tickets.map((t) => t.toUpcomingMap()).toList();
  }

  /// Returns maps compatible with TicketsTab live tickets list
  List<Map<String, String>> get liveTicketsMap {
    if (_tickets.isEmpty) {
      return TicketService.defaultInitialTickets()
          .map((t) => t.toLiveTicketMap())
          .toList();
    }
    return _tickets.map((t) => t.toLiveTicketMap()).toList();
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

  /// Fetch tickets from Supabase DB
  Future<void> fetchTickets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetched = await TicketService.instance.fetchTickets();
      _tickets = fetched;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
      notifyListeners();
    }
    return success;
  }

  /// Set local tickets list directly (useful for testing or initial state)
  void setTickets(List<TicketModel> tickets) {
    _tickets = List.from(tickets);
    notifyListeners();
  }
}
