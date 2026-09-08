import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  static TicketService get instance => _instance;
  TicketService._internal();

  static const String ticketsTable = 'tickets';

  /// Seed initial demo tickets for fallback / offline use
  static List<TicketModel> defaultInitialTickets() {
    return [
      TicketModel(
        ticketId: TicketModel.generateTicketId(1),
        ticketTitle: 'Ticket 1',
        drawDate: '25/09/2026',
        drawTime: '07:00 PM',
        price: '₹20',
        totalPrize: '₹75000',
        status: 'Active',
        prizes: TicketModel.defaultPrizes(),
      ),
      TicketModel(
        ticketId: TicketModel.generateTicketId(2),
        ticketTitle: 'Ticket 2',
        drawDate: '26/09/2026',
        drawTime: '08:00 PM',
        price: '₹25',
        totalPrize: '₹95000',
        status: 'Active',
        prizes: [
          PrizeItem(name: 'Housefull', price: '₹60000'),
          PrizeItem(name: '1st Line', price: '₹4000'),
          PrizeItem(name: '2nd Line', price: '₹4000'),
          PrizeItem(name: '3rd Line', price: '₹4000'),
          PrizeItem(name: '4th Corner', price: '₹5000'),
          PrizeItem(name: 'Quick Five', price: '₹5000'),
          PrizeItem(name: '3 Ticket Quick 10', price: '₹15000'),
        ],
      ),
      TicketModel(
        ticketId: TicketModel.generateTicketId(3),
        ticketTitle: 'Ticket 3',
        drawDate: '27/09/2026',
        drawTime: '07:30 PM',
        price: '₹30',
        totalPrize: '₹110000',
        status: 'Active',
        prizes: [
          PrizeItem(name: 'Housefull', price: '₹75000'),
          PrizeItem(name: '1st Line', price: '₹5000'),
          PrizeItem(name: '2nd Line', price: '₹5000'),
          PrizeItem(name: '3rd Line', price: '₹5000'),
          PrizeItem(name: '4th Corner', price: '₹5500'),
          PrizeItem(name: 'Quick Five', price: '₹5500'),
          PrizeItem(name: '3 Ticket Quick', price: '₹18000'),
        ],
      ),
      TicketModel(
        ticketId: TicketModel.generateTicketId(4),
        ticketTitle: 'Ticket 4',
        drawDate: '28/09/2026',
        drawTime: '09:00 PM',
        price: '₹50',
        totalPrize: '₹150000',
        status: 'Active',
        prizes: [
          PrizeItem(name: 'Housefull', price: '₹90000'),
          PrizeItem(name: '1st Line', price: '₹6000'),
          PrizeItem(name: '2nd Line', price: '₹6000'),
          PrizeItem(name: '3rd Line', price: '₹6000'),
          PrizeItem(name: '4th Corner', price: '₹7000'),
          PrizeItem(name: 'Quick Five', price: '₹7000'),
          PrizeItem(name: '3 Ticket Quick 10', price: '₹25000'),
        ],
      ),
    ];
  }

  /// Fetch all upcoming and active tickets from Supabase DB
  Future<List<TicketModel>> fetchTickets() async {
    final client = SupabaseService.instance.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ [TICKETS] Supabase not connected. Returning empty list.');
      return [];
    }

    try {
      debugPrint(
          '📥 [TICKETS] Fetching upcoming tickets from DB table "$ticketsTable"...');
      final response = await client
          .from(ticketsTable)
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) {
        debugPrint('ℹ️ [TICKETS] No tickets in DB yet. Returning empty list.');
        return [];
      }

      final tickets = data
          .map((json) => TicketModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      debugPrint(
          '✅ [TICKETS] Successfully fetched ${tickets.length} tickets from Supabase DB.');
      return tickets;
    } on PostgrestException catch (pe) {
      debugPrint(
          '⚠️ [TICKETS QUERY WARNING] Code: ${pe.code}, Details: ${pe.message}');
      return [];
    } catch (e) {
      debugPrint('⚠️ [TICKETS ERROR] $e');
      return [];
    }
  }

  /// Update an existing ticket draw in Supabase DB
  Future<TicketModel> updateTicket(TicketModel ticket) async {
    final client = SupabaseService.instance.client;

    debugPrint('==================================================');
    debugPrint(
        '✏️ [ADMIN TICKET UPDATE] Updating ticket ${ticket.ticketId}...');
    debugPrint('📅 Draw Date : ${ticket.drawDate} at ${ticket.drawTime}');
    debugPrint('💰 Total Pool: ${ticket.totalPrize}');
    debugPrint('🏆 Prizes    : ${ticket.prizes.length} prize tiers');

    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint(
          'ℹ️ [ADMIN TICKET UPDATE] Supabase not connected. Ticket updated in local state.');
      debugPrint('==================================================');
      return ticket;
    }

    try {
      final updatePayload = ticket.toJson();
      final response = await client
          .from(ticketsTable)
          .update(updatePayload)
          .eq('ticket_id', ticket.ticketId)
          .select()
          .single();

      final updated = TicketModel.fromJson(response);
      debugPrint(
          '✅ [ADMIN TICKET UPDATED] Saved into Supabase DB table "$ticketsTable"!');
      debugPrint('==================================================');
      return updated;
    } on PostgrestException catch (pe) {
      debugPrint(
          '❌ [TICKET UPDATE ERROR] Code: ${pe.code}, Details: ${pe.message}');
      throw Exception('Failed to update ticket in database: ${pe.message}');
    } catch (e) {
      debugPrint('❌ [TICKET UPDATE EXCEPTION] $e');
      throw Exception('Failed to update ticket: $e');
    }
  }

  /// Create and insert a new ticket draw into Supabase DB
  Future<TicketModel> createTicket(TicketModel ticket) async {
    final client = SupabaseService.instance.client;

    debugPrint('==================================================');
    debugPrint('🎟️ [ADMIN TICKET CREATION] Initiating new ticket creation...');
    debugPrint('🆔 Ticket ID : ${ticket.ticketId}');
    debugPrint('📅 Draw Date : ${ticket.drawDate} at ${ticket.drawTime}');
    debugPrint('💰 Total Pool: ${ticket.totalPrize}');
    debugPrint('🏆 Prizes    : ${ticket.prizes.length} prize tiers');

    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint(
          'ℹ️ [ADMIN TICKET] Supabase not connected. Ticket stored in local state.');
      debugPrint('==================================================');
      return ticket;
    }

    try {
      final insertPayload = ticket.toJson();
      final response = await client
          .from(ticketsTable)
          .insert(insertPayload)
          .select()
          .single();

      final created = TicketModel.fromJson(response);
      debugPrint(
          '✅ [ADMIN TICKET CREATED] Saved into Supabase DB table "$ticketsTable"!');
      debugPrint('==================================================');
      return created;
    } on PostgrestException catch (pe) {
      debugPrint(
          '❌ [TICKET INSERT ERROR] Code: ${pe.code}, Details: ${pe.message}');
      throw Exception('Failed to save ticket in database: ${pe.message}');
    } catch (e) {
      debugPrint('❌ [TICKET CREATE EXCEPTION] $e');
      throw Exception('Failed to create ticket: $e');
    }
  }

  /// Delete a ticket from Supabase DB
  Future<bool> deleteTicket(String ticketId) async {
    final client = SupabaseService.instance.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      return true;
    }

    try {
      await client.from(ticketsTable).delete().eq('ticket_id', ticketId);
      debugPrint('🗑️ [TICKETS] Deleted ticket $ticketId from DB.');
      return true;
    } catch (e) {
      debugPrint('❌ [TICKETS DELETE ERROR] $e');
      return false;
    }
  }

  /// Autogenerate next sequential ticket ID (e.g. GAGA26000005)
  String generateNextId(List<TicketModel> existingTickets) {
    int maxSeq = existingTickets.length;
    for (final t in existingTickets) {
      final id = t.ticketId;
      if (id.length >= 12 && id.startsWith('GAGA')) {
        final seqPart = id.substring(6);
        final val = int.tryParse(seqPart) ?? 0;
        if (val > maxSeq) maxSeq = val;
      }
    }
    return TicketModel.generateTicketId(maxSeq + 1);
  }
}
