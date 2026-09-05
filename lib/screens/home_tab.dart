// home_tab.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'draw_page.dart';
import 'my_tickets.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget
import 'ticket_selection_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PageController _ticketPageController = PageController(
    viewportFraction: 0.8,
  );
  final PageController _winnerPageController = PageController();
  int _currentTicketPage = 0;
  int _currentWinnerPage = 0;

  final List<Map<String, dynamic>> upcomingTickets = const [
    {
      'ticket': 'Ticket 1',
      'date': '20/08/2023',
      'time': '07:00 PM',
      'prizes': [
        {'name': 'Housefull', 'price': '₹50000'},
        {'name': '1st Line', 'price': '₹3000'},
        {'name': '2nd Line', 'price': '₹3000'},
        {'name': '3rd Line', 'price': '₹3000'},
        {'name': '4th Corner', 'price': '₹3000'},
        {'name': 'Quick Five', 'price': '₹3000'},
        {'name': '3 Ticket Quick', 'price': '₹10000'}
      ]
    },
    {
      'ticket': 'Ticket 2',
      'date': '21/08/2023',
      'time': '08:00 PM',
      'prizes': [
        {'name': 'Housefull', 'price': '₹60000'},
        {'name': '1st Line', 'price': '₹4000'},
        {'name': '2nd Line', 'price': '₹4000'},
        {'name': '3rd Line', 'price': '₹4000'},
        {'name': '4th Corner', 'price': '₹5000'},
        {'name': 'Quick Five', 'price': '₹5000'},
        {'name': '3 Ticket Quick 10', 'price': '₹15000'}
      ]
    }
  ];

  final List<Map<String, dynamic>> winners = const [
    {
      'ticket': 'Ticket 1',
      'date': '20/08/2023',
      'time': '07:00 PM',
      'prizes': [
        {'name': 'Housefull', 'price': '₹50000', 'winner': '101'},
        {'name': '1st Line', 'price': '₹3000', 'winner': '102'},
        {'name': '2nd Line', 'price': '₹3000', 'winner': '103'},
        {'name': '3rd Line', 'price': '₹3000', 'winner': '104'},
        {'name': '4th Corner', 'price': '₹3000', 'winner': '105'},
        {'name': 'Quick Five', 'price': '₹3000', 'winner': '106'},
        {'name': '3 Ticket Quick', 'price': '₹10000', 'winner': '305,306,307'},
      ]
    },
    {
      'ticket': 'Ticket 2',
      'date': '21/08/2023',
      'time': '08:00 PM',
      'prizes': [
        {'name': 'Housefull', 'price': '₹60000', 'winner': '201'},
        {'name': '1st Line', 'price': '₹4000', 'winner': '202'},
        {'name': '2nd Line', 'price': '₹4000', 'winner': '203'},
        {'name': '3rd Line', 'price': '₹4000', 'winner': '204'},
        {'name': '4th Corner', 'price': '₹5000', 'winner': '205'},
        {'name': 'Quick Five', 'price': '₹5000', 'winner': '206'},
        {'name': '3 Ticket Quick', 'price': '₹15000', 'winner': '305,306,307'},
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          // Balance Card - Using Reusable Widget
          const BalanceCard(
            balance: 1000.00,
            showRechargeButton: true,
          ),

          // Three Action Buttons - Rounded & Colorful
          _buildActionButtons(),

          // Upcoming Tickets - Slider with Arrows (Rectangular & Compact)
          _buildUpcomingTicketsSlider(),

          // Winners Section - Slider with Arrows (Rectangular & Compact)
          _buildWinnersSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingLarge),
      child: const Column(
        children: [
          Text(
            'GaGa',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          Text(
            'Housie Tambola',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // THREE ACTION BUTTONS - 2 PER ROW ON SMALL SCREENS
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingLarge, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          // Check if we have enough width for buttons
          final bool canFitInRow = screenWidth > 400;

          if (canFitInRow) {
            // Larger screens: Advertise takes full row, Tickets & Draw in second row
            return Column(
              children: [
                // Advertise button - full width with increased size
                SizedBox(
                  width: double.infinity,
                  height: 56, // Increased height for better visibility
                  child: _buildSolidActionButton(
                    icon: Icons.ads_click,
                    label: 'Advertise',
                    color: AppColors.primaryGreen,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 8),
                // My Tickets & Draw Start in a row
                Row(
                  children: [
                    Expanded(
                      child: _buildColorfulActionButton(
                        icon: Icons.confirmation_number,
                        label: 'My Tickets',
                        colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyTicketsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildColorfulActionButton(
                        icon: Icons.play_arrow,
                        label: 'Draw Start',
                        colors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DrawPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Smaller screens: Same layout but with smaller width
            return Column(
              children: [
                // Advertise button - full width with increased size
                SizedBox(
                  width: double.infinity,
                  height: 56, // Increased height for better visibility
                  child: _buildSolidActionButton(
                    icon: Icons.ads_click,
                    label: 'Advertise',
                    color: AppColors.primaryGreen,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 8),
                // My Tickets & Draw Start in a row
                Row(
                  children: [
                    Expanded(
                      child: _buildColorfulActionButton(
                        icon: Icons.confirmation_number,
                        label: 'My Tickets',
                        colors: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyTicketsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildColorfulActionButton(
                        icon: Icons.play_arrow,
                        label: 'Draw Start',
                        colors: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const DrawPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

// New method for solid color button (no gradient)
  Widget _buildSolidActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color, // Solid color, no gradient
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Keep your existing gradient button method for My Tickets and Draw Start
  Widget _buildColorfulActionButton({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildUpcomingTicketsSlider() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.all(AppDimens.paddingLarge),
        child: Text(
          'Upcoming Tickets',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_currentTicketPage > 0) {
                _ticketPageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_left,
                color: AppColors.white,
                size: 30,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _ticketPageController,
                itemCount: upcomingTickets.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentTicketPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final ticket = upcomingTickets[index];
                  // Extract price from ticket data or set default
                  String price = '₹10';
                  if (ticket['prizes'] != null && ticket['prizes'].isNotEmpty) {
                    // You can set a default price or calculate based on prizes
                    price = '₹10';
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryGreen.withOpacity(.22),
                            AppColors.secondaryGreen.withOpacity(.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(.4),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ticket Name
                          Text(
                            ticket['ticket'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.primaryGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Date & Time in same row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                ticket['date'],
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 9,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                ticket['time'],
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Divider(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            thickness: .5,
                            height: 4,
                          ),
                          // Prize List
                          ...List.generate(
                            ticket['prizes'].length,
                            (i) {
                              final prize = ticket['prizes'][i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 0.3,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prize['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      prize['price'],
                                      style: const TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4), // Gap above the BUY NOW button
                          // Buy Button
                          GestureDetector(
                            onTap: () {
                              final Map<String, String> ticketData = {
                                'ticket': ticket['ticket'] as String,
                                'date': ticket['date'] as String,
                                'time': ticket['time'] as String,
                                'price': '₹10',
                                'status': 'Active',
                                'id': 'TKT${index + 1}',
                              };
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketSelectionPage(
                                    ticket: ticketData,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 100,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00B894),
                                    Color(0xFF00A381),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: Text(
                                  "BUY NOW",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: .6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_currentTicketPage < upcomingTickets.length - 1) {
                _ticketPageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right,
                color: AppColors.primaryGreen,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          upcomingTickets.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentTicketPage == index ? 16 : 5,
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _currentTicketPage == index
                  ? AppColors.primaryGreen
                  : Colors.white30,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
    ],
  );
}


 // RECENT WINNERS - PERFECT RECTANGULAR SHAPE (NO EXTRA SPACE)
  Widget _buildWinnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(AppDimens.paddingLarge),
          child: Text(
            'Recent Winners',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_currentWinnerPage > 0) {
                  _winnerPageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(left: 12),
                child: const Icon(
                  Icons.chevron_left,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 155,
                child: PageView.builder(
                  controller: _winnerPageController,
                  itemCount: winners.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentWinnerPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final ticket = winners[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryGreen.withOpacity(.25),
                            AppColors.secondaryGreen.withOpacity(.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.glassBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ticket['ticket'] ?? '',
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.emoji_events,
                                color: AppColors.primaryGreen,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Text(
                                "📅 ${ticket['date'] ?? ''}",
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "⏰ ${ticket['time'] ?? ''}",
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            color: Colors.white30,
                            height: 4,
                            thickness: 0.5,
                          ),
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: ticket['prizes'].length,
                              itemBuilder: (context, i) {
                                final prize = ticket['prizes'][i];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0.5,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          prize['name'],
                                          style: const TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontSize: 8,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        prize['price'],
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "SL:${prize['winner']}",
                                          style: const TextStyle(
                                            color: AppColors.primaryGreen,
                                            fontSize: 7,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (_currentWinnerPage < winners.length - 1) {
                  _winnerPageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryGreen,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            winners.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentWinnerPage == index
                    ? AppColors.primaryGreen
                    : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
