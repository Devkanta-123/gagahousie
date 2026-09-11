import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tambola_ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../screens/ticket_purchase_page.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

class TicketSelectionPage extends StatefulWidget {
  final Map<dynamic, dynamic> ticket;

  const TicketSelectionPage({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketSelectionPage> createState() => _TicketSelectionPageState();
}

class _TicketSelectionPageState extends State<TicketSelectionPage> {
  final Set<int> _selectedSlNos = <int>{};
  bool _isLoading = true;
  List<Map<String, dynamic>> _fallbackTickets = [];

  String get _ticketId {
    final raw = (widget.ticket['id'] ??
            widget.ticket['ticketId'] ??
            widget.ticket['ticket_id'] ??
            '')
        .toString()
        .trim();
    return raw.startsWith('#') ? raw.substring(1).trim() : raw;
  }

  @override
  void initState() {
    super.initState();
    _loadConfiguredTickets();
  }

  Future<void> _loadConfiguredTickets() async {
    final tid = _ticketId;
    if (tid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final provider = Provider.of<TicketProvider>(context, listen: false);
      // Check cache first
      final cached = provider.getCachedTambolaTickets(tid);
      if (cached != null && cached.isNotEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Fetch from Supabase
      final fetched = await provider.fetchTambolaTickets(tid);
      if (fetched.isEmpty && mounted) {
        // If not found in DB either, initialize empty tickets for this draw
        setState(() {
          _fallbackTickets = List.generate(
            6,
            (index) => TambolaTicketModel.empty(tid, index + 1).toSelectionMap(),
          );
        });
      }
    } catch (e) {
      debugPrint('ℹ️ [SELECTION] Error loading tickets: $e');
      if (mounted) {
        setState(() {
          _fallbackTickets = List.generate(
            6,
            (index) => TambolaTicketModel.empty(tid, index + 1).toSelectionMap(),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get selectedCount => _selectedSlNos.length;

  double get totalPrice {
    final priceStr = (widget.ticket['price'] ?? '₹20')
        .toString()
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .trim();
    final price = double.tryParse(priceStr) ?? 20.0;
    return price * selectedCount;
  }

  bool isTicketSelectable(int slNo) {
    // Get all selected tickets sorted by SL number
    List<int> selectedSLs = _selectedSlNos.toList()..sort();

    // If no tickets selected, all tickets are selectable
    if (selectedSLs.isEmpty) {
      return true;
    }

    // If already 3 tickets selected, disable all
    if (selectedSLs.length >= 3) {
      return false;
    }

    // Check if selected tickets are in the same set (1-3 or 4-6)
    bool inSet1 = selectedSLs.every((sl) => sl >= 1 && sl <= 3);
    bool inSet2 = selectedSLs.every((sl) => sl >= 4 && sl <= 6);

    // If selected tickets are in set 1 (1-3)
    if (inSet1) {
      if (slNo >= 1 && slNo <= 3) {
        if (selectedSLs.contains(slNo)) return true; // Already selected
        int nextInSequence = selectedSLs.last + 1;
        return slNo == nextInSequence;
      }
      return false; // Can't select from set 2
    }

    // If selected tickets are in set 2 (4-6)
    if (inSet2) {
      if (slNo >= 4 && slNo <= 6) {
        if (selectedSLs.contains(slNo)) return true; // Already selected
        int nextInSequence = selectedSLs.last + 1;
        return slNo == nextInSequence;
      }
      return false; // Can't select from set 1
    }

    return false;
  }

  String getSelectionMessage() {
    List<int> selectedSLs = _selectedSlNos.toList()..sort();

    if (selectedSLs.isEmpty) {
      return 'Select tickets (max 3) from (1-3) or (4-6)';
    }

    if (selectedSLs.length >= 3) {
      return 'Maximum 3 tickets selected';
    }

    // Check which set is being selected
    bool inSet1 = selectedSLs.every((sl) => sl >= 1 && sl <= 3);
    bool inSet2 = selectedSLs.every((sl) => sl >= 4 && sl <= 6);

    if (inSet1) {
      int nextInSequence = selectedSLs.last + 1;
      if (nextInSequence <= 3) {
        return 'Select SL $nextInSequence next (Set 1: 1-3)';
      }
      return 'Set 1 complete! Select Set 2 (4-6) after clearing';
    }

    if (inSet2) {
      int nextInSequence = selectedSLs.last + 1;
      if (nextInSequence <= 6) {
        return 'Select SL $nextInSequence next (Set 2: 4-6)';
      }
      return 'Set 2 complete!';
    }

    return 'Select from Set 1 (1-3) or Set 2 (4-6)';
  }

  @override
  Widget build(BuildContext context) {
    // Listen reactively to TicketProvider
    final provider = Provider.of<TicketProvider>(context);
    final cached = _ticketId.isNotEmpty
        ? provider.getCachedTambolaTickets(_ticketId)
        : null;

    final List<Map<String, dynamic>> tambolaTickets = [];
    if (cached != null && cached.isNotEmpty) {
      for (final t in cached) {
        final map = t.toSelectionMap();
        map['selected'] = _selectedSlNos.contains(t.slNo);
        tambolaTickets.add(map);
      }
    } else if (_fallbackTickets.isNotEmpty) {
      for (final t in _fallbackTickets) {
        final map = Map<String, dynamic>.from(t);
        map['selected'] = _selectedSlNos.contains(map['slNo']);
        tambolaTickets.add(map);
      }
    }

    final set1Tickets = tambolaTickets
        .where((t) =>
            (t['slNo'] as int? ?? 0) >= 1 && (t['slNo'] as int? ?? 0) <= 3)
        .toList();
    final set2Tickets = tambolaTickets
        .where((t) =>
            (t['slNo'] as int? ?? 0) >= 4 && (t['slNo'] as int? ?? 0) <= 6)
        .toList();
    final otherTickets = tambolaTickets
        .where((t) => (t['slNo'] as int? ?? 0) > 6)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            GaGaAppHeader(
              showBackButton: true,
              compact: true,
              subtitle:
                  '${widget.ticket['ticket'] ?? 'Ticket'} • Select Numbers',
              showBalance: true,
              balance: 1000.0,
              showRechargeButton: true,
            ),
            // Selection Info Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00B894).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF00B894),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getSelectionMessage(),
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$selectedCount/3',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Ticket Info Card
                    _buildTicketInfoCard(),
                    const SizedBox(height: 16),

                    // Main Ticket Container - All tickets under one card with margins
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFF00B894).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header for main ticket
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00B894).withOpacity(0.15),
                                  const Color(0xFF00B894).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '🎫 Tambola Tickets',
                                  style: TextStyle(
                                    color: Color(0xFF2C3E50),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00B894),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${tambolaTickets.length} Tickets',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_isLoading && tambolaTickets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      color: Color(0xFF00B894),
                                      strokeWidth: 2.5,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Loading tickets for $_ticketId...',
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (tambolaTickets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_outlined,
                                      size: 44,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'No Tambola tickets configured yet.',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            // Set 1: Tickets 1-3
                            if (set1Tickets.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00B894).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00B894)
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              SizedBox(width: 8),
                                              Text(
                                                'Tickets 1-3',
                                                style: TextStyle(
                                                  color: Color(0xFF2C3E50),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (set1Tickets.isNotEmpty &&
                                              set1Tickets.every((t) =>
                                                  t['selected'] == true))
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00B894)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFF00B894),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Text(
                                                '✓ COMPLETE',
                                                style: TextStyle(
                                                  color: Color(0xFF00B894),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Tickets in Set 1
                                    ...set1Tickets.map((ticket) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child:
                                              _buildTambolaTicketCard(ticket),
                                        )),
                                  ],
                                ),
                              ),

                            // Set 2: Tickets 4-6
                            if (set2Tickets.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF00B894).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF00B894)
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              SizedBox(width: 8),
                                              Text(
                                                'Tickets 4-6',
                                                style: TextStyle(
                                                  color: Color(0xFF2C3E50),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (set2Tickets.isNotEmpty &&
                                              set2Tickets.every((t) =>
                                                  t['selected'] == true))
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFF6B6B)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFFF6B6B),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Text(
                                                '✓ COMPLETE',
                                                style: TextStyle(
                                                  color: Color(0xFFFF6B6B),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Tickets in Set 2
                                    ...set2Tickets.map((ticket) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child:
                                              _buildTambolaTicketCard(ticket),
                                        )),
                                  ],
                                ),
                              ),

                            // Any Other Tickets
                            if (otherTickets.isNotEmpty)
                              ...otherTickets.map((ticket) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    child: _buildTambolaTicketCard(ticket),
                                  )),

                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Button - Navigates to Purchase Page
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfoCard() {
    final price = widget.ticket['price']?.toString() ?? '₹20';
    final id = _ticketId.isNotEmpty ? _ticketId : 'N/A';
    final date = widget.ticket['date']?.toString() ?? 'N/A';
    final status = widget.ticket['status']?.toString() ?? 'Active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00B894).withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ticket Details',
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00B894), width: 1),
                ),
                child: Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF00B894),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Ticket ID', id),
          const SizedBox(height: 8),
          _buildInfoRow('Date', date),
          const SizedBox(height: 8),
          _buildInfoRow('Status', status),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 13,
            ),
          ),
        ),
        const Text(
          ':',
          style: TextStyle(color: Color(0xFF2C3E50), fontSize: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTambolaTicketCard(Map<String, dynamic> ticket) {
    final slNo = ticket['slNo'] is int
        ? ticket['slNo'] as int
        : int.tryParse(ticket['slNo']?.toString() ?? '1') ?? 1;
    final isSelected = _selectedSlNos.contains(slNo);

    List<List<int?>> ticketData =
        List.generate(3, (_) => List<int?>.filled(9, null));
    if (ticket['ticketData'] != null) {
      if (ticket['ticketData'] is Map &&
          ticket['ticketData']['ticketData'] is List) {
        final list = ticket['ticketData']['ticketData'] as List;
        ticketData = list
            .map((r) => (r as List).map((c) => c as int?).toList())
            .toList();
      } else if (ticket['ticketData'] is List) {
        final list = ticket['ticketData'] as List;
        ticketData = list
            .map((r) => (r as List).map((c) => c as int?).toList())
            .toList();
      }
    }

    final playerName = ticket['playerName']?.toString() ?? 'Ticket #$slNo';
    final serialNumber = ticket['serialNumber']?.toString() ??
        'SN: TKT-${slNo.toString().padLeft(3, '0')}';
    final uniqueCode = ticket['uniqueCode']?.toString() ??
        'CODE: TC-$_ticketId-${slNo.toString().padLeft(3, '0')}';

    // Check if this ticket can be selected
    bool canSelect = isTicketSelectable(slNo);
    bool isDisabled = !canSelect && !isSelected;

    return GestureDetector(
      onTap: () {
        if (canSelect || isSelected) {
          setState(() {
            if (_selectedSlNos.contains(slNo)) {
              _selectedSlNos.remove(slNo);
            } else {
              _selectedSlNos.add(slNo);
            }
          });
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withOpacity(0.08)
              : (isSelected
                  ? const Color(0xFF00B894).withOpacity(0.08)
                  : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00B894)
                : (isDisabled
                    ? Colors.grey.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.2)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00B894).withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with SL No, Checkbox, Player Name, Serial Number
              Row(
                children: [
                  // SL Number Badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00B894)
                          : (isDisabled
                              ? Colors.grey.withOpacity(0.2)
                              : const Color(0xFF00B894).withOpacity(0.15)),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00B894)
                            : (isDisabled
                                ? Colors.grey.withOpacity(0.15)
                                : const Color(0xFF00B894).withOpacity(0.3)),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        slNo.toString(),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDisabled
                                  ? Colors.grey
                                  : const Color(0xFF00B894)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Selection checkbox
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF00B894)
                          : (isDisabled
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.transparent),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00B894)
                            : (isDisabled
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.5)),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // Player Name
                  Expanded(
                    child: Text(
                      playerName,
                      style: TextStyle(
                        color:
                            isDisabled ? Colors.grey : const Color(0xFF2C3E50),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Serial Number
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00B894).withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      serialNumber,
                      style: TextStyle(
                        color:
                            isDisabled ? Colors.grey : const Color(0xFF00B894),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Unique Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  uniqueCode,
                  style: TextStyle(
                    color: isDisabled ? Colors.grey : const Color(0xFF00B894),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Tambola Ticket Grid (3 rows x 9 columns)
              ...List.generate(3, (rowIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: List.generate(9, (colIndex) {
                      final number = ticketData[rowIndex][colIndex];
                      final isFreeSlot = number == null;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          height: 28,
                          decoration: BoxDecoration(
                            color: isFreeSlot
                                ? Colors.grey.withOpacity(0.05)
                                : (isSelected
                                    ? const Color(0xFF00B894).withOpacity(0.15)
                                    : (isDisabled
                                        ? Colors.grey.withOpacity(0.05)
                                        : Colors.grey.withOpacity(0.08))),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isFreeSlot
                                  ? Colors.grey.withOpacity(0.1)
                                  : (isSelected
                                      ? const Color(0xFF00B894)
                                      : (isDisabled
                                          ? Colors.grey.withOpacity(0.2)
                                          : const Color(0xFF00B894)
                                              .withOpacity(0.3))),
                              width: isSelected ? 1.5 : 0.8,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isFreeSlot ? "" : number.toString(),
                              style: TextStyle(
                                color: isFreeSlot
                                    ? Colors.transparent
                                    : (isSelected
                                        ? const Color(0xFF00B894)
                                        : (isDisabled
                                            ? Colors.grey
                                            : const Color(0xFF2C3E50))),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),

              // Column Headers (1-9)
              Row(
                children: List.generate(9, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Center(
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.4),
                            fontSize: 7,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00B894).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '₹${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF00B894),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: selectedCount > 0
                    ? () {
                        // Navigate to TicketPurchasePage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketPurchasePage(
                              ticket: Map<String, String>.from(
                                widget.ticket.map((k, v) =>
                                    MapEntry(k.toString(), v.toString())),
                              ),
                              showBackButton: true,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      selectedCount > 0 ? const Color(0xFF00B894) : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  selectedCount > 0
                      ? 'Buy Now ($selectedCount selected)'
                      : 'Select tickets to continue',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
