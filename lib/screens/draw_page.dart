import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'dart:math';

class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  final int currentNumber = 77;

  final List<int> drawnNumbers = [
    1, 20, 29, 57, 72, 77, 80, 93,
  ];

  // Generate random Tambola tickets for players
  List<Map<String, dynamic>> playerTickets = [];

  @override
  void initState() {
    super.initState();
    _generatePlayerTickets();
  }

  void _generatePlayerTickets() {
    final players = [
      'Rahul Sharma',
      'Priya Patel',
      'Amit Kumar',
      'Sneha Reddy',
      'Vikram Singh',
      'Ananya Iyer',
    ];

    playerTickets = players.asMap().entries.map((entry) {
      int index = entry.key;
      String player = entry.value;
      return {
        'playerName': player,
        'slNo': index + 1,
        'serialNumber': 'SN: TKT-${(index + 1).toString().padLeft(3, '0')}',
        'ticketData': _generateTambolaTicket(),
      };
    }).toList();
  }

  List<List<int?>> _generateTambolaTicket() {
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
    
    return ticket;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: Container(
          color: const Color(0xFFF5F0E8),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                      "Tambola Draw",
                      style: TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        /// TOP SECTION
                        _buildTopSection(),

                        const SizedBox(height: 20),

                        /// PLAYER TICKETS
                        ...playerTickets.map((player) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: _buildTicketCard(
                            player['playerName'],
                            player['slNo'],
                            player['serialNumber'],
                            player['ticketData'],
                          ),
                        )).toList(),

                        const SizedBox(height: 20),

                        /// PRIZE PANEL AT BOTTOM
                        _buildPrizePanel(),

                        const SizedBox(height: 20),
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

  Widget _buildTopSection() {
    return Column(
      children: [
        _buildCurrentNumber(),
        const SizedBox(height: 15),
        SizedBox(
          height: 320,
          child: _buildNumberBoard(),
        ),
      ],
    );
  }

  Widget _buildCurrentNumber() {
    return _glassCard(
      child: SizedBox(
        width: double.infinity,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Current Number",
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "$currentNumber",
              style: const TextStyle(
                color: Color(0xFF00B894),
                fontSize: 72,
                fontWeight: FontWeight.bold,
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
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00B894).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildNumberBoard() {
    return _glassCard(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 90,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (_, index) {
          final number = index + 1;
          final selected = drawnNumbers.contains(number);

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: selected
                  ? const Color(0xFF00B894)
                  : Colors.grey.withOpacity(0.08),
              border: Border.all(
                color: selected
                    ? const Color(0xFF00B894)
                    : Colors.grey.withOpacity(0.1),
                width: selected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                "$number",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : const Color(0xFF2C3E50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(
    String playerName,
    int slNo,
    String serialNumber,
    List<List<int?>> ticketData,
  ) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with SL No and Player Name
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // Tambola Ticket Grid (3 rows x 9 columns)
            ...List.generate(3, (rowIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: List.generate(9, (colIndex) {
                    final number = ticketData[rowIndex][colIndex];
                    final isFreeSlot = number == null;
                    final isDrawn = number != null && drawnNumbers.contains(number);
                    
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 36,
                        decoration: BoxDecoration(
                          color: isFreeSlot 
                              ? Colors.grey.withOpacity(0.05)
                              : (isDrawn
                                  ? const Color(0xFF00B894).withOpacity(0.2)
                                  : const Color(0xFF00B894).withOpacity(0.08)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isFreeSlot
                                ? Colors.grey.withOpacity(0.1)
                                : (isDrawn
                                    ? const Color(0xFF00B894)
                                    : const Color(0xFF00B894).withOpacity(0.3)),
                            width: isDrawn ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isFreeSlot ? "" : number.toString(),
                            style: TextStyle(
                              color: isFreeSlot 
                                  ? Colors.transparent
                                  : (isDrawn
                                      ? const Color(0xFF00B894)
                                      : const Color(0xFF2C3E50)),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
            const SizedBox(height: 6),
            Row(
              children: List.generate(9, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildPrizePanel() {
    final prizes = [
      "House Full",
      "1st Line",
      "2nd Line",
      "3rd Line",
      "4th Corner",
      "Quick 5",
      "3 Ticket Quick 10",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Prizes",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: prizes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) {
            return _glassCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    prizes[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}