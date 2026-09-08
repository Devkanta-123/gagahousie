import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../models/tambola_ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../screens/ticket_purchase_page.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

class TicketSelectionPage extends StatefulWidget {
  final Map<String, String> ticket;

  const TicketSelectionPage({
    super.key,
    required this.ticket,
  });

  @override
  State<TicketSelectionPage> createState() => _TicketSelectionPageState();
}

class _TicketSelectionPageState extends State<TicketSelectionPage> {
  final List<Map<String, dynamic>> tambolaTickets = [
    {
      'slNo': 1,
      'playerName': 'Rahul Sharma',
      'serialNumber': 'SN: TKT-001',
      'uniqueCode': 'CODE: RS-AMB-001',
      'selected': false,
      'ticketData': null,
    },
    {
      'slNo': 2,
      'playerName': 'Priya Patel',
      'serialNumber': 'SN: TKT-002',
      'uniqueCode': 'CODE: PP-AMB-002',
      'selected': false,
      'ticketData': null,
    },
    {
      'slNo': 3,
      'playerName': 'Amit Kumar',
      'serialNumber': 'SN: TKT-003',
      'uniqueCode': 'CODE: AK-AMB-003',
      'selected': false,
      'ticketData': null,
    },
    {
      'slNo': 4,
      'playerName': 'Sneha Reddy',
      'serialNumber': 'SN: TKT-004',
      'uniqueCode': 'CODE: SR-AMB-004',
      'selected': false,
      'ticketData': null,
    },
    {
      'slNo': 5,
      'playerName': 'Vikram Singh',
      'serialNumber': 'SN: TKT-005',
      'uniqueCode': 'CODE: VS-AMB-005',
      'selected': false,
      'ticketData': null,
    },
    {
      'slNo': 6,
      'playerName': 'Ananya Iyer',
      'serialNumber': 'SN: TKT-006',
      'uniqueCode': 'CODE: AI-AMB-006',
      'selected': false,
      'ticketData': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Generate fallback initial tickets
    for (var ticket in tambolaTickets) {
      ticket['ticketData'] = _generateTambolaTicket();
    }
    _loadConfiguredTickets();
  }

  void _loadConfiguredTickets() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ticketId = widget.ticket['id'];
      if (ticketId == null || ticketId.isEmpty) return;

      try {
        final provider = Provider.of<TicketProvider>(context, listen: false);
        List<TambolaTicketModel> configured =
            provider.getCachedTambolaTickets(ticketId) ?? [];

        if (configured.isEmpty) {
          configured = await provider.fetchTambolaTickets(ticketId);
        }

        if (configured.isNotEmpty && mounted) {
          setState(() {
            tambolaTickets.clear();
            for (final t in configured) {
              tambolaTickets.add(t.toSelectionMap());
            }
          });
        }
      } catch (e) {
        debugPrint('ℹ️ [SELECTION] Using generated fallback: $e');
      }
    });
  }

  Map<String, dynamic> _generateTambolaTicket() {
    Random random = Random();

    List<List<int?>> ticket = List.generate(3, (_) => List.filled(9, null));

    for (int row = 0; row < 3; row++) {
      List<int> positions = List.generate(9, (index) => index);
      positions.shuffle();
      positions = positions.take(5).toList();
      positions.sort();

      for (int col = 0; col < 9; col++) {
        if (positions.contains(col)) {
          int minNum = col == 0 ? 1 : (col * 10);
          int maxNum = col == 8 ? 90 : (col * 10) + 9;

          int number = minNum + random.nextInt(maxNum - minNum + 1);

          bool duplicate = true;
          int attempts = 0;
          while (duplicate && attempts < 10) {
            duplicate = false;
            for (int r = 0; r < row; r++) {
              if (ticket[r][col] == number) {
                duplicate = true;
                number = minNum + random.nextInt(maxNum - minNum + 1);
                break;
              }
            }
            attempts++;
          }

          ticket[row][col] = number;
        }
      }
    }

    return {'ticketData': ticket};
  }

  int get selectedCount {
    return tambolaTickets.where((item) => item['selected'] as bool).length;
  }

  double get totalPrice {
    double price = double.parse(
        widget.ticket['price']!.replaceAll('₹', '').replaceAll('\$', ''));
    return price * selectedCount;
  }

  bool isTicketSelectable(int slNo) {
    // Get all selected tickets sorted by SL number
    List<int> selectedSLs = tambolaTickets
        .where((item) => item['selected'] as bool)
        .map<int>((item) => item['slNo'] as int)
        .toList()
      ..sort();

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
      // Only allow selecting from set 1 (1-3)
      if (slNo >= 1 && slNo <= 3) {
        // Check if consecutive
        if (selectedSLs.contains(slNo)) return true; // Already selected
        // Check if this is the next in sequence
        int nextInSequence = selectedSLs.last + 1;
        return slNo == nextInSequence;
      }
      return false; // Can't select from set 2
    }

    // If selected tickets are in set 2 (4-6)
    if (inSet2) {
      // Only allow selecting from set 2 (4-6)
      if (slNo >= 4 && slNo <= 6) {
        // Check if consecutive
        if (selectedSLs.contains(slNo)) return true; // Already selected
        // Check if this is the next in sequence
        int nextInSequence = selectedSLs.last + 1;
        return slNo == nextInSequence;
      }
      return false; // Can't select from set 1
    }

    return false;
  }

  String getSelectionMessage() {
    List<int> selectedSLs = tambolaTickets
        .where((item) => item['selected'] as bool)
        .map<int>((item) => item['slNo'] as int)
        .toList()
      ..sort();

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
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF00B894),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getSelectionMessage(),
                      style: TextStyle(
                        color: const Color(0xFF2C3E50),
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
                      '${selectedCount}/3',
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

                          // Set 1: Tickets 1-3
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B894).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00B894).withOpacity(0.2),
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
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Tickets 1-3',
                                            style: TextStyle(
                                              color: Color(0xFF2C3E50),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (tambolaTickets
                                          .where((t) =>
                                              t['slNo'] as int >= 1 &&
                                              t['slNo'] as int <= 3)
                                          .every((t) => t['selected'] as bool))
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00B894)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFF00B894),
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
                                ...tambolaTickets
                                    .where((t) =>
                                        t['slNo'] as int >= 1 &&
                                        t['slNo'] as int <= 3)
                                    .map((ticket) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child:
                                              _buildTambolaTicketCard(ticket),
                                        )),
                              ],
                            ),
                          ),

                          // Set 2: Tickets 4-6
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B894).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00B894).withOpacity(0.2),
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
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Tickets 4-6',
                                            style: TextStyle(
                                              color: Color(0xFF2C3E50),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (tambolaTickets
                                          .where((t) =>
                                              t['slNo'] as int >= 4 &&
                                              t['slNo'] as int <= 6)
                                          .every((t) => t['selected'] as bool))
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B6B)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFF6B6B),
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
                                ...tambolaTickets
                                    .where((t) =>
                                        t['slNo'] as int >= 4 &&
                                        t['slNo'] as int <= 6)
                                    .map((ticket) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          child:
                                              _buildTambolaTicketCard(ticket),
                                        )),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
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
                  widget.ticket['price']!,
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
          _buildInfoRow('Ticket ID', widget.ticket['id']!),
          const SizedBox(height: 8),
          _buildInfoRow('Date', widget.ticket['date']!),
          const SizedBox(height: 8),
          _buildInfoRow('Status', widget.ticket['status']!),
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
    final isSelected = ticket['selected'] as bool;
    final slNo = ticket['slNo'] as int;
    final ticketData = ticket['ticketData']['ticketData'] as List<List<int?>>;

    // Check if this ticket can be selected
    bool canSelect = isTicketSelectable(slNo);
    bool isDisabled = !canSelect && !isSelected;

    return GestureDetector(
      onTap: () {
        if (canSelect || isSelected) {
          setState(() {
            ticket['selected'] = !isSelected;
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
                      ticket['playerName'],
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
                      ticket['serialNumber'],
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
                  ticket['uniqueCode'],
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
                              ticket: widget.ticket,
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
