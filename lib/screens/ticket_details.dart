import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dart:math';

class TicketDetailsPage extends StatelessWidget {
  final String ticketNumber;
  final String date;
  final String time;
  final String price;
  final String ticketId;

  const TicketDetailsPage({
    super.key,
    required this.ticketNumber,
    required this.date,
    required this.time,
    required this.price,
    required this.ticketId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFF5F0E8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                /// HEADER
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF00B894),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Ticket Details",
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /// MAIN TICKET CARD
                        _buildMainTicketCard(),
                        const SizedBox(height: 16),
                        
                        /// ACTIVE TICKETS SECTION
                        _buildActiveTicketsSection(),
                        const SizedBox(height: 16),
                        
                        /// ADDITIONAL INFO
                        // _buildAdditionalInfo(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTicketCard() {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B894).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00B894).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.confirmation_number,
                          color: Color(0xFF00B894),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Your Ticket",
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00B894),
                        Color(0xFF00A381),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "₹$price",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("Ticket ID", ticketId),
            const SizedBox(height: 8),
            _infoRow("Date", date),
            const SizedBox(height: 8),
            _infoRow("Time", time),
            const SizedBox(height: 8),
            _infoRow("Ticket Sl. No.", ticketNumber),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          ":",
          style: TextStyle(
            color: Colors.grey.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTicketsSection() {
    // Generate 5 different tickets with random numbers
    final tickets = [
      _generateTambolaTicket("", "SN: TKT-001", "CODE: RS-AMB-001"),
      _generateTambolaTicket("", "SN: TKT-002", "CODE: PP-AMB-002"),
      _generateTambolaTicket("", "SN: TKT-003", "CODE: AK-AMB-003"),
      _generateTambolaTicket("", "SN: TKT-004", "CODE: SR-AMB-004"),
      _generateTambolaTicket("", "SN: TKT-005", "CODE: VS-AMB-005"),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "Your Tickets",
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...tickets.map((ticket) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildTicketCard(
            playerName: ticket['playerName']!,
            serialNumber: ticket['serialNumber']!,
            uniqueCode: ticket['uniqueCode']!,
            ticketData: ticket['ticketData'] as List<List<int?>>,
            slNo: ticket['slNo'] as int,
          ),
        )).toList(),
      ],
    );
  }

  Map<String, dynamic> _generateTambolaTicket(String playerName, String serialNumber, String uniqueCode) {
    Random random = Random();
    
    // Create 3x9 grid initially filled with null (empty slots)
    List<List<int?>> ticket = List.generate(3, (_) => List.filled(9, null));
    
    // Each row must have exactly 5 numbers (standard tambola)
    for (int row = 0; row < 3; row++) {
      // Generate random positions for this row (5 positions out of 9)
      List<int> positions = List.generate(9, (index) => index);
      positions.shuffle();
      positions = positions.take(5).toList();
      positions.sort();
      
      // For each column, generate number in the correct range
      for (int col = 0; col < 9; col++) {
        if (positions.contains(col)) {
          // Numbers for each column range:
          // Col 0: 1-9, Col 1: 10-19, Col 2: 20-29, Col 3: 30-39
          // Col 4: 40-49, Col 5: 50-59, Col 6: 60-69, Col 7: 70-79, Col 8: 80-90
          int minNum = col == 0 ? 1 : (col * 10);
          int maxNum = col == 8 ? 90 : (col * 10) + 9;
          
          int number = minNum + random.nextInt(maxNum - minNum + 1);
          
          // Ensure no duplicate numbers in the same column across rows
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
    
    // Generate random SL number (1-7)
    int slNo = random.nextInt(7) + 1;
    
    return {
      'playerName': playerName,
      'serialNumber': serialNumber,
      'uniqueCode': uniqueCode,
      'ticketData': ticket,
      'slNo': slNo,
    };
  }

  Widget _buildTicketCard({
    required String playerName,
    required String serialNumber,
    required String uniqueCode,
    required List<List<int?>> ticketData,
    required int slNo,
  }) {
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SL Number, Player Name and Serial Number Row
            Row(
              children: [
                // SL Number Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00B894).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      slNo.toString(),
                      style: const TextStyle(
                        color: Color(0xFF00B894),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
                    style: const TextStyle(
                      color: Color(0xFF00B894),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            /// Unique Code
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                uniqueCode,
                style: const TextStyle(
                  color: Color(0xFF00B894),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 10),
            
            /// Tambola Ticket Grid (3 rows x 9 columns)
            ...List.generate(3, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: List.generate(9, (colIndex) {
                    final number = ticketData[rowIndex][colIndex];
                    final isFreeSlot = number == null;
                    
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 32,
                        decoration: BoxDecoration(
                          color: isFreeSlot 
                              ? Colors.grey.withOpacity(0.05)
                              : const Color(0xFF00B894).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isFreeSlot
                                ? Colors.grey.withOpacity(0.1)
                                : const Color(0xFF00B894).withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isFreeSlot ? "" : number.toString(),
                            style: TextStyle(
                              color: isFreeSlot 
                                  ? Colors.transparent
                                  : const Color(0xFF2C3E50),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
            
            /// Column Headers (1-9)
            const SizedBox(height: 4),
            Row(
              children: List.generate(9, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 8),
            
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00B894).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF00B894),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF00B894),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
  }) {
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
      child: child,
    );
  }
}