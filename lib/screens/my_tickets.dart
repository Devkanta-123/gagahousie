import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_purchase_model.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/ticket_service.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'draw_page.dart';
import 'ticket_details.dart';

class MyTicketsPage extends StatefulWidget {
  const MyTicketsPage({super.key});

  @override
  State<MyTicketsPage> createState() => _MyTicketsPageState();
}

class _MyTicketsPageState extends State<MyTicketsPage> {
  List<TicketPurchaseModel> _purchasedTickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserPurchasedTickets();
  }

  Future<void> _fetchUserPurchasedTickets() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    if (user?.id == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final list =
          await TicketService.instance.fetchPurchasedTicketsForUser(user!.id);
      if (mounted) {
        setState(() {
          _purchasedTickets = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ℹ️ [MY TICKETS FETCH ERROR] $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = Provider.of<WalletProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentUser = auth.currentUser;

    final int totalCount = _purchasedTickets.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Full-width consistent branded header with real-time balance
          GaGaAppHeader(
            showBackButton: true,
            subtitle: 'My Purchased Tickets',
            showBalance: true,
            balance: wallet.balance,
            showRechargeButton: true,
          ),

          // Subheader with ticket count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Purchased Tickets',
                      style: TextStyle(
                        color: Color(0xFF0F3B2C),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (currentUser != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${currentUser.fullName})',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    '$totalCount Active',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Draw Quick Action Banner
          if (_purchasedTickets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3C72).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.live_tv_rounded,
                          color: Color(0xFFFFD200), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tambola Live Draw',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Draw #${_purchasedTickets.first.ticketId} • ${_purchasedTickets.length} ticket(s) owned',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B894),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DrawPage(
                                ticketId: _purchasedTickets.first.ticketId),
                          ),
                        );
                      },
                      child: const Text(
                        'Enter Draw',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Responsive tickets list strictly from public.ticket_purchases
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  )
                : totalCount == 0
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primaryGreen,
                        onRefresh: () async {
                          await _fetchUserPurchasedTickets();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          itemCount: _purchasedTickets.length,
                          itemBuilder: (context, index) {
                            final purchase = _purchasedTickets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildPurchasedTicketCard(purchase),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.primaryGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No Purchased Tickets Yet',
              style: TextStyle(
                color: Color(0xFF0F3B2C),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tickets purchased from active draws will appear here in real time with their SL numbers and Tambola numbers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// High quality purchased ticket card showing SL No, Tambola Numbers, Date/Time & Price
  Widget _buildPurchasedTicketCard(TicketPurchaseModel purchase) {
    final filledNums = purchase.filledNumbers;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailsPage(
              ticketNumber: purchase.ticketTitle,
              date: purchase.drawDate,
              time: purchase.drawTime,
              price: purchase.price.toStringAsFixed(0),
              ticketId: purchase.ticketId,
              purchase: purchase,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: SL Badge, Ticket Title / Draw ID & Status Badge
            Row(
              children: [
                // Prominent SL Number Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'SL #${purchase.slNo}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase.ticketTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        'Draw ID: #${purchase.ticketId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF81C784),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    purchase.status,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Row 2: Date, Time & Price
            Row(
              children: [
                if (purchase.drawDate.isNotEmpty) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    purchase.drawDate,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
                  ),
                  const SizedBox(width: 12),
                ],
                if (purchase.drawTime.isNotEmpty) ...[
                  Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    purchase.drawTime,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
                  ),
                ],
                const Spacer(),
                Text(
                  '₹${purchase.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            // Row 3: Tambola Numbers Preview (15 numbers)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4A33).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_3x3_rounded,
                          size: 12, color: Color(0xFF0F4A33)),
                      SizedBox(width: 3),
                      Text(
                        'Numbers:',
                        style: TextStyle(
                          color: Color(0xFF0F4A33),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: filledNums.isNotEmpty
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: filledNums.map((n) {
                              return Container(
                                margin: const EdgeInsets.only(right: 4),
                                width: 23,
                                height: 23,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color:
                                        AppColors.primaryGreen.withOpacity(0.3),
                                    width: 0.6,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    n.toString(),
                                    style: const TextStyle(
                                      color: Color(0xFF0F4A33),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : Text(
                          'Tap to view 3x9 grid',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                        ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7971E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 17),
                label: const Text(
                  'Play Live Draw (Interactive Dabbing)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DrawPage(ticketId: purchase.ticketId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
