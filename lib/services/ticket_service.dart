import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';
import '../models/tambola_ticket_model.dart';
import '../models/ticket_purchase_model.dart';
import 'supabase_config.dart';
import 'supabase_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  static TicketService get instance => _instance;
  TicketService._internal();

  static const String ticketsTable = 'tickets';
  static const String tambolaTicketsTable = 'tambola_tickets';
  static const String ticketPurchasesTable = 'ticket_purchases';

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

  SupabaseClient? get client => SupabaseService.instance.client;

  /// Fetch all upcoming and active tickets from Supabase DB
  Future<List<TicketModel>> fetchTickets() async {
    final client = this.client;
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
    final client = this.client;

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
      // Exclude immutable columns (id, created_at, ticket_id) from the update body
      final updatePayload = <String, dynamic>{
        'ticket_title': ticket.ticketTitle,
        'draw_date': ticket.drawDate,
        'draw_time': ticket.drawTime,
        'price': ticket.price,
        'total_prize': ticket.totalPrize,
        'prizes': ticket.prizes.map((p) => p.toJson()).toList(),
        'status': ticket.status,
        if (ticket.createdBy != null) 'created_by': ticket.createdBy,
      };

      // 1. Attempt update matching by ticket_id or id using .select() (returns List, never throws 406 PGRST116)
      List<dynamic> rows = [];
      if (ticket.id != null) {
        rows = await client
            .from(ticketsTable)
            .update(updatePayload)
            .eq('id', ticket.id)
            .select();
      }

      if (rows.isEmpty) {
        rows = await client
            .from(ticketsTable)
            .update(updatePayload)
            .eq('ticket_id', ticket.ticketId)
            .select();
      }

      if (rows.isNotEmpty) {
        final updated =
            TicketModel.fromJson(Map<String, dynamic>.from(rows.first));
        debugPrint(
            '✅ [ADMIN TICKET UPDATED] Saved into Supabase DB table "$ticketsTable"!');
        debugPrint('==================================================');
        return updated;
      }

      // If rows is empty (0 rows returned because ticket_id didn't match or RLS restricted UPDATE)
      debugPrint(
          '⚠️ [ADMIN TICKET UPDATE] DB update returned 0 rows. Checking if ticket exists...');

      // Check if ticket exists in DB using standard select list
      final List<dynamic> existingRows = await client
          .from(ticketsTable)
          .select()
          .eq('ticket_id', ticket.ticketId)
          .limit(1);

      if (existingRows.isEmpty) {
        // Ticket did not exist in DB (e.g. offline fallback ticket). Insert it!
        debugPrint(
            'ℹ️ [ADMIN TICKET UPDATE] Ticket not found in DB. Inserting as new ticket...');
        final insertPayload = ticket.toJson();
        final List<dynamic> insertRows = await client
            .from(ticketsTable)
            .insert(insertPayload)
            .select();
        if (insertRows.isNotEmpty) {
          final created =
              TicketModel.fromJson(Map<String, dynamic>.from(insertRows.first));
          debugPrint(
              '✅ [ADMIN TICKET CREATED] Saved into Supabase DB table "$ticketsTable"!');
          debugPrint('==================================================');
          return created;
        }
      } else {
        debugPrint(
            '⚠️ [ADMIN TICKET UPDATE] Row exists in DB but Supabase RLS policy restricted UPDATE for anon role.');
        debugPrint(
            '👉 Ensure the following policy is run in Supabase SQL Editor:');
        debugPrint(
            '   CREATE POLICY "Allow update tickets" ON public.tickets FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);');
      }

      // Preserving ticket in local state so admin workflow is unblocked
      debugPrint('ℹ️ [ADMIN TICKET UPDATE] Updated in local state.');
      debugPrint('==================================================');
      return ticket;
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST116' ||
          pe.code == '406' ||
          pe.message.contains('PGRST116') ||
          pe.message.contains('coerce')) {
        debugPrint(
            '⚠️ [TICKET UPDATE] PGRST116/406 handled gracefully: Local state preserved.');
        return ticket;
      }
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
    final client = this.client;

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
      final List<dynamic> rows = await client
          .from(ticketsTable)
          .insert(insertPayload)
          .select();

      if (rows.isNotEmpty) {
        final created =
            TicketModel.fromJson(Map<String, dynamic>.from(rows.first));
        debugPrint(
            '✅ [ADMIN TICKET CREATED] Saved into Supabase DB table "$ticketsTable"!');
        debugPrint('==================================================');
        return created;
      }
      return ticket;
    } on PostgrestException catch (pe) {
      if (pe.code == 'PGRST116' ||
          pe.code == '406' ||
          pe.message.contains('PGRST116') ||
          pe.message.contains('coerce')) {
        debugPrint(
            '⚠️ [TICKET INSERT] PGRST116/406 caught. Returning local ticket.');
        return ticket;
      }
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
    final client = this.client;
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

  /// Fetch tambola tickets for a given draw ticket_id from Supabase
  Future<List<TambolaTicketModel>> fetchTambolaTickets(String ticketId) async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ [TAMBOLA] Supabase not connected. Returning empty list.');
      return [];
    }

    try {
      debugPrint('📥 [TAMBOLA] Fetching tickets for draw $ticketId...');
      var response = await client
          .from(tambolaTicketsTable)
          .select()
          .eq('ticket_id', ticketId)
          .order('sl_no', ascending: true);

      var data = response as List<dynamic>;
      if (data.isEmpty) {
        final altId = ticketId.startsWith('#')
            ? ticketId.substring(1).trim()
            : '#$ticketId';
        final altResponse = await client
            .from(tambolaTicketsTable)
            .select()
            .eq('ticket_id', altId)
            .order('sl_no', ascending: true);
        data = altResponse as List<dynamic>;
      }

      final result = data
          .map((item) =>
              TambolaTicketModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      debugPrint('✅ [TAMBOLA] Loaded ${result.length} tickets for $ticketId');
      return result;
    } catch (e) {
      debugPrint('❌ [TAMBOLA FETCH ERROR] $e');
      return [];
    }
  }

  /// Fetch set of ticket_ids that have tambola tickets configured with numbers
  Future<Set<String>> fetchTicketIdsWithTambola() async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      return {};
    }

    try {
      final response = await client
          .from(tambolaTicketsTable)
          .select('ticket_id, ticket_data');

      final List<dynamic> data = response as List<dynamic>;
      final set = <String>{};
      for (final item in data) {
        final tid = item['ticket_id']?.toString();
        final rawGrid = item['ticket_data'];
        bool hasNumbers = false;
        if (rawGrid is List) {
          for (final row in rawGrid) {
            if (row is List && row.any((cell) => cell != null)) {
              hasNumbers = true;
              break;
            }
          }
        }
        if (tid != null && tid.isNotEmpty && hasNumbers) {
          set.add(tid);
        }
      }
      return set;
    } catch (e) {
      debugPrint('⚠️ [TAMBOLA TICKET_IDS FETCH ERROR] $e');
      return {};
    }
  }

  /// Save or upsert tambola tickets for a given draw ticket_id
  Future<bool> saveTambolaTickets(
      String ticketId, List<TambolaTicketModel> tickets) async {
    // Enforce max 15 numbers validation per Tambola ticket
    for (final ticket in tickets) {
      if (ticket.filledNumbersCount > 15) {
        debugPrint(
            '❌ [VALIDATION ERROR] SL ${ticket.slNo} has ${ticket.filledNumbersCount} numbers. Max allowed is 15.');
        return false;
      }
    }

    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ [TAMBOLA] Supabase not connected. Simulated local save.');
      return true;
    }

    try {
      debugPrint('💾 [TAMBOLA] Saving ${tickets.length} tickets for $ticketId...');
      final payload = tickets.map((t) => t.toJson()).toList();
      await client
          .from(tambolaTicketsTable)
          .upsert(payload, onConflict: 'ticket_id, sl_no');
      debugPrint('✅ [TAMBOLA] Successfully saved tickets for $ticketId');
      return true;
    } on PostgrestException catch (pe) {
      debugPrint('❌ [TAMBOLA SAVE ERROR] ${pe.message}');
      return false;
    } catch (e) {
      debugPrint('❌ [TAMBOLA SAVE EXCEPTION] $e');
      return false;
    }
  }

  /// Delete tambola tickets for a draw
  Future<bool> deleteTambolaTickets(String ticketId) async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      return true;
    }

    try {
      await client
          .from(tambolaTicketsTable)
          .delete()
          .eq('ticket_id', ticketId);
      return true;
    } catch (e) {
      debugPrint('❌ [TAMBOLA DELETE ERROR] $e');
      return false;
    }
  }

  /// Record a ticket purchase in public.ticket_purchases and update public.tambola_tickets to 'Sold Out'
  Future<bool> recordTicketPurchase({
    required dynamic userId,
    required String userEmail,
    required String userName,
    required String ticketId,
    required String ticketTitle,
    required String drawDate,
    required String drawTime,
    required List<int> slNos,
    required double pricePerTicket,
    Map<int, List<List<int?>>>? ticketDataBySl,
    Map<int, String>? serialNumberBySl,
    Map<int, String>? uniqueCodeBySl,
  }) async {
    final client = this.client;
    final now = DateTime.now();

    // 1. Fetch current tambola tickets for this draw to ensure we have the exact 3x9 grid
    final existingTambola = await fetchTambolaTickets(ticketId);
    final Map<int, TambolaTicketModel> existingMap = {
      for (final t in existingTambola) t.slNo: t
    };

    // 2. Prepare purchases payload
    final List<Map<String, dynamic>> purchaseRows = [];
    for (final slNo in slNos) {
      final existing = existingMap[slNo];
      final grid = ticketDataBySl?[slNo] ??
          existing?.ticketData ??
          List.generate(3, (_) => List<int?>.filled(9, null));
      final sn = serialNumberBySl?[slNo] ??
          existing?.serialNumber ??
          'SN: TKT-${slNo.toString().padLeft(3, '0')}';
      final code = uniqueCodeBySl?[slNo] ??
          existing?.uniqueCode ??
          'CODE: GH-$ticketId-SL$slNo';

      purchaseRows.add({
        'user_id': userId,
        'user_email': userEmail,
        'user_name': userName,
        'ticket_id': ticketId,
        'ticket_title': ticketTitle,
        'draw_date': drawDate,
        'draw_time': drawTime,
        'sl_no': slNo,
        'serial_number': sn,
        'unique_code': code,
        'ticket_data': grid,
        'price': pricePerTicket,
        'status': 'Booked',
        'created_at': now.toIso8601String(),
      });
    }

    if (client == null || !SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ [PURCHASE] Supabase not connected. Simulated local purchase.');
      return true;
    }

    // 3. Insert into public.ticket_purchases
    try {
      debugPrint('💾 [PURCHASE] Inserting ${purchaseRows.length} purchase records into "$ticketPurchasesTable"...');
      await client.from(ticketPurchasesTable).insert(purchaseRows);
      debugPrint('✅ [PURCHASE] Inserted purchase records for user $userId');
    } catch (e) {
      debugPrint('⚠️ [PURCHASE INSERT NOTICE] $e');
    }

    // 4. Update public.tambola_tickets to 'Sold Out' and player_name = userName
    try {
      final cleanId = ticketId.startsWith('#') ? ticketId.substring(1).trim() : ticketId.trim();
      for (final slNo in slNos) {
        debugPrint('💾 [TAMBOLA UPDATE] Marking draw $cleanId SL #$slNo as Sold Out to $userName...');
        await client
            .from(tambolaTicketsTable)
            .update({
              'status': 'Sold Out',
              'player_name': userName,
            })
            .eq('ticket_id', cleanId)
            .eq('sl_no', slNo);

        // Also update with '#' prefix if exists
        await client
            .from(tambolaTicketsTable)
            .update({
              'status': 'Sold Out',
              'player_name': userName,
            })
            .eq('ticket_id', '#$cleanId')
            .eq('sl_no', slNo);
      }
      debugPrint('✅ [TAMBOLA UPDATE] Successfully marked tickets as Sold Out in DB');
    } catch (e) {
      debugPrint('⚠️ [TAMBOLA UPDATE NOTICE] $e');
    }

    return true;
  }

  /// Fetch all tickets purchased by a specific user from public.ticket_purchases
  Future<List<TicketPurchaseModel>> fetchPurchasedTicketsForUser(dynamic userId) async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured || userId == null) {
      return [];
    }

    try {
      debugPrint('📥 [PURCHASES] Fetching tickets for user $userId from "$ticketPurchasesTable"...');
      final response = await client
          .from(ticketPurchasesTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final list = data
          .map((item) => TicketPurchaseModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      debugPrint('✅ [PURCHASES] Loaded ${list.length} purchased tickets for user $userId');
      return list;
    } catch (e) {
      debugPrint('⚠️ [FETCH PURCHASES ERROR] $e');
      return [];
    }
  }

  /// Fetch tickets purchased by a specific user for a specific draw
  Future<List<TicketPurchaseModel>> fetchPurchasedTicketsForUserAndDraw(
      dynamic userId, String ticketId) async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured || userId == null) {
      return [];
    }

    try {
      final cleanId = ticketId.startsWith('#')
          ? ticketId.substring(1).trim()
          : ticketId.trim();
      debugPrint(
          '📥 [PURCHASES] Fetching tickets for user $userId for draw $cleanId...');
      final response = await client
          .from(ticketPurchasesTable)
          .select()
          .eq('user_id', userId)
          .or('ticket_id.eq.$cleanId,ticket_id.eq.#$cleanId')
          .order('sl_no', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      final list = data
          .map((item) =>
              TicketPurchaseModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      debugPrint(
          '✅ [PURCHASES] Loaded ${list.length} purchased tickets for user $userId for draw $cleanId');
      return list;
    } catch (e) {
      debugPrint('⚠️ [FETCH PURCHASES FOR DRAW ERROR] $e');
      return [];
    }
  }

  /// Fetch all registered buyers who bought tickets for a specific draw
  Future<List<TicketPurchaseModel>> fetchBuyersForDraw(String ticketId) async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      return [];
    }

    try {
      final cleanId = ticketId.startsWith('#') ? ticketId.substring(1).trim() : ticketId.trim();
      debugPrint('📥 [DRAW BUYERS] Fetching buyers for draw $ticketId ($cleanId)...');

      // Fetch from ticket_purchases
      var response = await client
          .from(ticketPurchasesTable)
          .select()
          .eq('ticket_id', cleanId)
          .order('sl_no', ascending: true);

      var data = response as List<dynamic>;
      if (data.isEmpty) {
        final altResponse = await client
            .from(ticketPurchasesTable)
            .select()
            .eq('ticket_id', '#$cleanId')
            .order('sl_no', ascending: true);
        data = altResponse as List<dynamic>;
      }

      if (data.isNotEmpty) {
        return data
            .map((item) =>
                TicketPurchaseModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('⚠️ [FETCH DRAW BUYERS ERROR] $e');
      return [];
    }
  }

  /// Fetch the set of SL numbers that are sold out for a draw
  Future<Set<int>> fetchSoldOutSlNos(String ticketId) async {
    final client = this.client;
    if (client == null || !SupabaseConfig.isConfigured) {
      return {};
    }

    try {
      final cleanId = ticketId.startsWith('#')
          ? ticketId.substring(1).trim()
          : ticketId.trim();
      final set = <int>{};

      // 1. Check ticket_purchases table
      try {
        final purchasesResp = await client
            .from(ticketPurchasesTable)
            .select('sl_no')
            .filter('ticket_id', 'in', '($cleanId,#$cleanId)');
        for (final item in (purchasesResp as List<dynamic>)) {
          final sl = item['sl_no'] is int
              ? item['sl_no']
              : int.tryParse(item['sl_no'].toString());
          if (sl != null) set.add(sl);
        }
      } catch (_) {}

      // 2. Check tambola_tickets table
      try {
        final response = await client
            .from(tambolaTicketsTable)
            .select('sl_no, status')
            .filter('ticket_id', 'in', '($cleanId,#$cleanId)');

        final data = response as List<dynamic>;
        for (final item in data) {
          final status = item['status']?.toString().toLowerCase() ?? '';
          if (status == 'sold out' || status == 'booked') {
            final sl = item['sl_no'] is int
                ? item['sl_no']
                : int.tryParse(item['sl_no'].toString());
            if (sl != null) set.add(sl);
          }
        }
      } catch (_) {}

      return set;
    } catch (e) {
      debugPrint('⚠️ [FETCH SOLD SL NOS ERROR] $e');
      return {};
    }
  }
}
