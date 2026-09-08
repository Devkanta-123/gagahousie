import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import 'draw_page.dart';
import 'my_tickets.dart';
import '../widgets/balance_card.dart'; // Import the balance card widget
import '../widgets/gaga_app_header.dart';
import 'ticket_selection_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const int _loopMultiplier = 1000;
  late final int _initialTicketPage;
  late final PageController _ticketPageController;
  final PageController _winnerPageController = PageController();
  int _currentTicketPage = 0;
  int _currentWinnerPage = 0;

  @override
  void initState() {
    super.initState();
    _initialTicketPage = upcomingTickets.isNotEmpty
        ? upcomingTickets.length * (_loopMultiplier ~/ 2)
        : 0;
    _ticketPageController = PageController(
      viewportFraction: 0.70,
      initialPage: _initialTicketPage,
    );
  }

  @override
  void dispose() {
    _ticketPageController.dispose();
    _winnerPageController.dispose();
    super.dispose();
  }

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
    },
    {
      'ticket': 'Ticket 3',
      'date': '22/08/2023',
      'time': '07:30 PM',
      'prizes': [
        {'name': 'Housefull', 'price': '₹75000'},
        {'name': '1st Line', 'price': '₹5000'},
        {'name': '2nd Line', 'price': '₹5000'},
        {'name': '3rd Line', 'price': '₹5000'},
        {'name': '4th Corner', 'price': '₹5500'},
        {'name': 'Quick Five', 'price': '₹5500'},
        {'name': '3 Ticket Quick', 'price': '₹18000'}
      ]
    },
    {
      'ticket': 'Ticket 4',
      'date': '23/08/2023',
      'time': '09:00 PM',
      'prizes': [
        {'name': 'Housefull', 'price': '₹90000'},
        {'name': '1st Line', 'price': '₹6000'},
        {'name': '2nd Line', 'price': '₹6000'},
        {'name': '3rd Line', 'price': '₹6000'},
        {'name': '4th Corner', 'price': '₹7000'},
        {'name': 'Quick Five', 'price': '₹7000'},
        {'name': '3 Ticket Quick 10', 'price': '₹25000'}
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

  List<Map<String, dynamic>> _getActiveUpcomingTickets() {
    try {
      final provider = Provider.of<TicketProvider>(context);
      final list = provider.upcomingTicketsMap;
      if (list.isNotEmpty) {
        return list;
      }
    } catch (_) {
      // Fallback if TicketProvider is not in the widget tree
    }
    return upcomingTickets;
  }

  @override
  Widget build(BuildContext context) {
    final activeUpcoming = _getActiveUpcomingTickets();

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () async {
        try {
          await Provider.of<TicketProvider>(context, listen: false)
              .fetchTickets();
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Integrated GaGa Housie Header with Balance + Wallet + Recharge
            const GaGaAppHeader(
              compact: true,
              showBalance: true,
              balance: 1000.00,
              showRechargeButton: true,
            ),

            // Three Action Buttons - Rounded & Colorful
            _buildActionButtons(),

            // Upcoming Tickets - Slider with Arrows (Rectangular & Compact)
            _buildUpcomingTicketsSlider(activeUpcoming),

            // Winners Section - Slider with Arrows (Rectangular & Compact)
            _buildWinnersSection(),
          ],
        ),
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
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 22,
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
          ),
        ),
      ),
    );
  }

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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
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
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingTicketsSlider(List<Map<String, dynamic>> activeTickets) {
    final int totalTickets = activeTickets.length;
    final int totalVirtualPages = totalTickets * _loopMultiplier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Upcoming Tickets',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.18),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$totalTickets Available',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Responsive Slider: 1 full ticket card with reduced width and partial left/right peek for swipe indication
        LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double horizontalMargin =
                availableWidth > 640 ? (availableWidth - 620) / 2 : 8.0;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
              child: Row(
                children: [
                  // Left Navigation Chevron (Loops smoothly to previous/last ticket)
                  GestureDetector(
                    onTap: () {
                      _ticketPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                  ),

                  // Middle: PageView (1 full card with reduced width, showing last ticket on left and next on right)
                  Expanded(
                    child: SizedBox(
                      height: 185,
                      child: totalTickets == 0
                          ? const Center(
                              child: Text(
                                'No upcoming tickets',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : PageView.builder(
                              controller: _ticketPageController,
                              itemCount: totalVirtualPages,
                              padEnds: true,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentTicketPage = totalTickets > 0
                                      ? page % totalTickets
                                      : 0;
                                });
                              },
                              itemBuilder: (context, index) {
                                final int actualIndex =
                                    totalTickets > 0 ? index % totalTickets : 0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 3,
                                  ),
                                  child: _buildUpcomingTicketCard(
                                    ticket: activeTickets[actualIndex],
                                    index: actualIndex,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Right Navigation Chevron (Loops smoothly to next ticket)
                  GestureDetector(
                    onTap: () {
                      _ticketPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Indicator Dots for Slider
        if (totalTickets > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalTickets,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentTicketPage == index ? 20 : 6,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentTicketPage == index
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen.withOpacity(0.2),
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Individual Ticket Card (Compact, Reduced Width, Professional White & Green Palette)
  Widget _buildUpcomingTicketCard({
    required Map<String, dynamic> ticket,
    required int index,
  }) {
    final List prizes = ticket['prizes'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Ticket Name Tag on left, Date & Time on right (Compact single row)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket['ticket'] as String? ?? 'Ticket',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 9,
                          color: AppColors.primaryGreen.withOpacity(0.75),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ticket['date'] as String? ?? '',
                          style: TextStyle(
                            color: AppColors.primaryGreen.withOpacity(0.85),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.access_time_rounded,
                          size: 9,
                          color: AppColors.primaryGreen.withOpacity(0.75),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ticket['time'] as String? ?? '',
                          style: TextStyle(
                            color: AppColors.primaryGreen.withOpacity(0.85),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),

          Divider(
            color: AppColors.primaryGreen.withOpacity(0.12),
            thickness: 0.6,
            height: 4,
          ),

          // Prize List - Compact rows without extra whitespace
          ...prizes.map((prize) {
            final isTopPrize = prize == prizes.first;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 0.5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prize['name'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isTopPrize
                            ? AppColors.primaryGreen
                            : const Color(0xFF2D4A3E),
                        fontSize: 8.5,
                        fontWeight:
                            isTopPrize ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    prize['price'] as String? ?? '',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 5),

          // Buy Now Button - Tightly positioned right under price details
          GestureDetector(
            onTap: () {
              final Map<String, String> ticketData = {
                'ticket': ticket['ticket'] as String? ?? 'Ticket',
                'date': ticket['date'] as String? ?? '',
                'time': ticket['time'] as String? ?? '',
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
              width: double.infinity,
              height: 25,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF196144),
                    Color(0xFF00B894),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B894).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "BUY NOW",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RECENT WINNERS - Professional White & Green Theme
  Widget _buildWinnersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingLarge,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Recent Winners',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.18),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 12,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Live Winners',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentWinnerPage > 0
                        ? AppColors.primaryGreen.withOpacity(0.3)
                        : AppColors.primaryGreen.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _currentWinnerPage > 0
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen.withOpacity(0.25),
                  size: 22,
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
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
                                Icons.emoji_events_rounded,
                                color: Color(0xFFF59E0B),
                                size: 18,
                              ),
                            ],
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  "📅 ${ticket['date'] ?? ''}",
                                  style: TextStyle(
                                    color: AppColors.primaryGreen
                                        .withOpacity(0.85),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "⏰ ${ticket['time'] ?? ''}",
                                  style: TextStyle(
                                    color: AppColors.primaryGreen
                                        .withOpacity(0.85),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            height: 6,
                            thickness: 0.6,
                          ),
                          Expanded(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
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
                                            color: Color(0xFF2D4A3E),
                                            fontSize: 8.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        prize['price'],
                                        style: const TextStyle(
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 8.5,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          "SL:${prize['winner']}",
                                          style: TextStyle(
                                            color: AppColors.primaryGreen
                                                .withOpacity(0.85),
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w500,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _currentWinnerPage < winners.length - 1
                        ? AppColors.primaryGreen.withOpacity(0.3)
                        : AppColors.primaryGreen.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _currentWinnerPage < winners.length - 1
                      ? AppColors.primaryGreen
                      : AppColors.primaryGreen.withOpacity(0.25),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            winners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentWinnerPage == index ? 16 : 5,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _currentWinnerPage == index
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withOpacity(0.2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
