import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/wallet_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import 'home_tab.dart';
import 'tickets_tab.dart';
import 'results_tab.dart';
import 'profile_tab.dart';
import 'admin_home_tab.dart';
import 'admin_tickets_tab.dart';
import 'draw_page.dart';
import 'wallet_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  StreamSubscription<UserNotificationModel>? _alertSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initWallet();
    });
  }

  void _initWallet() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user != null) {
      wallet.initForUser(
        userId: user.id,
        userEmail: user.email,
        isAdmin: user.isAdmin,
      );
    }

    _alertSubscription?.cancel();
    _alertSubscription = wallet.alertStream.listen((notification) {
      if (!mounted) return;
      _showRealTimeNotificationDialog(context, notification);
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  void _showRealTimeNotificationDialog(
      BuildContext context, UserNotificationModel notification) {
    final isApproved = notification.isRechargeApproved;
    final isRejected = notification.isRechargeRejected;
    final isDrawStarted = notification.type == 'draw_started' ||
        notification.title.contains('Draw Started') ||
        notification.title.contains('Housie Draw Started');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDrawStarted
                    ? const Color(0xFFF7971E).withOpacity(0.15)
                    : (isApproved
                        ? const Color(0xFF00B894).withOpacity(0.15)
                        : (isRejected
                            ? Colors.red.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15))),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDrawStarted
                    ? Icons.play_circle_fill_rounded
                    : (isApproved
                        ? Icons.check_circle_rounded
                        : (isRejected
                            ? Icons.cancel_rounded
                            : Icons.notifications_active_rounded)),
                color: isDrawStarted
                    ? const Color(0xFFF7971E)
                    : (isApproved
                        ? const Color(0xFF00B894)
                        : (isRejected ? Colors.red : Colors.blue)),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (isRejected && notification.metadata['remarks'] != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Admin Remarks: ${notification.metadata['remarks']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (isDrawStarted) {
                final tid =
                    notification.metadata['ticket_id']?.toString() ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DrawPage(ticketId: tid.isNotEmpty ? tid : null),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletPage()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDrawStarted
                  ? const Color(0xFFF7971E)
                  : (isApproved
                      ? const Color(0xFF00B894)
                      : const Color(0xFF2C3E50)),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isDrawStarted ? 'View Live Draw' : 'View Wallet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.isAdmin;

    // Role-based landing tabs: Admin sees AdminHomeTab and AdminTicketsTab;
    // Regular users see standard HomeTab and TicketsTab.
    // Bottom navigation toggle bar remains identical.
    final List<Widget> tabs = [
      isAdmin ? const AdminHomeTab() : const HomeTab(),
      isAdmin ? const AdminTicketsTab() : const TicketsTab(),
      const ResultsTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tabs[_currentIndex],
      bottomNavigationBar: _buildWaterGridToggleBar(),
    );
  }

  /// Water Grid Effects & Fluid Animated Toggle Bottom Navigation Bar
  Widget _buildWaterGridToggleBar() {
    final navItems = [
      _WaterNavItem(icon: Icons.home_rounded, label: 'Home'),
      _WaterNavItem(icon: Icons.confirmation_number_rounded, label: 'Tickets'),
      _WaterNavItem(icon: Icons.emoji_events_rounded, label: 'Results'),
      _WaterNavItem(icon: Icons.account_circle_rounded, label: 'Account'),
    ];

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: 66,
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        decoration: BoxDecoration(
          // Deep oceanic emerald water glassmorphism
          gradient: const LinearGradient(
            colors: [
              Color(0xFF072318),
              Color(0xFF0B3324),
              Color(0xFF0E3D2B),
              Color(0xFF072318),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(33),
          border: Border.all(
            color: const Color(0xFF00E676).withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            // Deep ambient depth shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            // Aquatic water glow
            BoxShadow(
              color: const Color(0xFF00E676).withOpacity(0.18),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double itemWidth = totalWidth / navItems.length;
              final double pillWidth = (itemWidth * 0.88).clamp(56.0, 78.0);
              const double pillHeight = 48.0;
              final double pillTop = (constraints.maxHeight - pillHeight) / 2;
              final double pillLeft =
                  (_currentIndex * itemWidth) + (itemWidth - pillWidth) / 2;

              return Stack(
                children: [
                  // Water Grid and Ripple Effect Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _WaterGridEffectPainter(
                        activeIndex: _currentIndex,
                        totalItems: navItems.length,
                      ),
                    ),
                  ),

                  // Fluid Water Toggle Indicator Pill (glides smoothly under active tab)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    left: pillLeft,
                    top: pillTop,
                    width: pillWidth,
                    height: pillHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00E676),
                            Color(0xFF00B894),
                            Color(0xFF00966D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.45),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      // Inner highlight shimmer
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Interactive Tab Items
                  Row(
                    children: List.generate(navItems.length, (index) {
                      final item = navItems[index];
                      final isSelected = index == _currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_currentIndex != index) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _currentIndex = index;
                              });
                            }
                          },
                          child: Container(
                            height: double.infinity,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.15 : 0.95,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutBack,
                                  child: Icon(
                                    item.icon,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.65),
                                    size: 21,
                                    shadows: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 200),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.65),
                                    fontSize: isSelected ? 10.5 : 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}

class _WaterNavItem {
  final IconData icon;
  final String label;

  _WaterNavItem({required this.icon, required this.label});
}

/// Custom painter for luminous digital water grid mesh and aquatic ripples
class _WaterGridEffectPainter extends CustomPainter {
  final int activeIndex;
  final int totalItems;

  _WaterGridEffectPainter(
      {required this.activeIndex, required this.totalItems});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Water Grid Horizontal Lines
    final Paint gridPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.07)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const double stepY = 12.0;
    for (double y = stepY; y < size.height; y += stepY) {
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), gridPaint);
    }

    // 2. Water Grid Vertical Lines
    const double stepX = 22.0;
    for (double x = stepX; x < size.width; x += stepX) {
      canvas.drawLine(Offset(x, 6), Offset(x, size.height - 6), gridPaint);
    }

    // 3. Dynamic Water Ripples centered under active tab
    final double itemWidth = size.width / totalItems;
    final double activeCenterX = (activeIndex * itemWidth) + (itemWidth / 2);
    final double centerY = size.height / 2;

    // Inner water ripple ring
    final Paint ripplePaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(activeCenterX, centerY), 26, ripplePaint);

    // Outer faint water wave ring
    final Paint outerRipplePaint = Paint()
      ..color = const Color(0xFF00CEC9).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset(activeCenterX, centerY), 40, outerRipplePaint);

    // 4. Subtle Top Water Wave Caustics
    final Path wavePath = Path();
    wavePath.moveTo(0, 6);
    for (double x = 0; x <= size.width; x += 24) {
      wavePath.quadraticBezierTo(
        x + 12,
        x % 48 == 0 ? 3 : 9,
        x + 24,
        6,
      );
    }
    final Paint wavePaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(wavePath, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _WaterGridEffectPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.totalItems != totalItems;
  }
}
