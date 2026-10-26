// screens/ticket_purchase_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/ticket_service.dart';
import '../services/wallet_service.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'my_tickets.dart';
import 'wallet_page.dart';

class TicketPurchasePage extends StatefulWidget {
  final Map<String, String>? ticket;
  final bool showBackButton;
  final int selectedCount;
  final List<int>? selectedSlNos;
  final double? unitPrice;
  final double? totalAmount;
  final List<Map<String, dynamic>>? selectedTambolaTickets;

  const TicketPurchasePage({
    super.key,
    this.ticket,
    this.showBackButton = true,
    this.selectedCount = 1,
    this.selectedSlNos,
    this.unitPrice,
    this.totalAmount,
    this.selectedTambolaTickets,
  });

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  bool _isPurchasing = false;

  double get walletBalance =>
      Provider.of<WalletProvider>(context, listen: true).balance;

  /// Resolves the live TicketModel from TicketProvider if available in DB
  TicketModel? get _dbTicket {
    final tid = (widget.ticket?['id'] ??
            widget.ticket?['ticketId'] ??
            widget.ticket?['ticket_id'] ??
            '')
        .toString()
        .trim();
    if (tid.isEmpty) return null;
    try {
      final ticketProv = Provider.of<TicketProvider>(context, listen: false);
      final clean = tid.replaceAll(RegExp(r'[\s\-_#]'), '').toLowerCase();
      return ticketProv.tickets.firstWhere(
        (t) =>
            t.ticketId == tid ||
            t.ticketId.replaceAll(RegExp(r'[\s\-_#]'), '').toLowerCase() == clean,
      );
    } catch (_) {
      return null;
    }
  }

  String get ticketId {
    final fromDb = _dbTicket?.ticketId;
    if (fromDb != null && fromDb.isNotEmpty) {
      return fromDb.startsWith('#') ? fromDb.substring(1).trim() : fromDb.trim();
    }
    final raw = (widget.ticket?['id'] ??
            widget.ticket?['ticketId'] ??
            widget.ticket?['ticket_id'] ??
            '')
        .toString()
        .trim();
    return raw.startsWith('#') ? raw.substring(1).trim() : raw;
  }

  String get ticketName {
    final db = _dbTicket;
    if (db != null && db.ticketTitle.isNotEmpty) return db.ticketTitle;
    final fromWidget = widget.ticket?['ticket'] ??
        widget.ticket?['ticket_title'] ??
        widget.ticket?['ticketTitle'];
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return 'GaGa Housie Draw';
  }

  String get drawDate {
    final db = _dbTicket;
    if (db != null && db.drawDate.isNotEmpty) return db.drawDate;
    final fromWidget = widget.ticket?['date'] ??
        widget.ticket?['draw_date'] ??
        widget.ticket?['drawDate'];
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return '';
  }

  String get drawTime {
    final db = _dbTicket;
    if (db != null && db.drawTime.isNotEmpty) return db.drawTime;
    final fromWidget = widget.ticket?['time'] ??
        widget.ticket?['draw_time'] ??
        widget.ticket?['drawTime'];
    if (fromWidget != null && fromWidget.isNotEmpty) return fromWidget;
    return '';
  }

  double get unitTicketPrice {
    if (widget.unitPrice != null && widget.unitPrice! > 0) {
      return widget.unitPrice!;
    }
    final db = _dbTicket;
    if (db != null) {
      final clean = db.price
          .replaceAll('₹', '')
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .trim();
      final p = double.tryParse(clean);
      if (p != null && p > 0) return p;
    }
    final raw = (widget.ticket?['price'] ?? widget.ticket?['ticket_price'] ?? '')
        .toString()
        .replaceAll('₹', '')
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(raw) ?? 20.0;
  }

  int get selectedQuantity {
    if (widget.selectedSlNos != null && widget.selectedSlNos!.isNotEmpty) {
      return widget.selectedSlNos!.length;
    }
    if (widget.selectedCount > 0) {
      return widget.selectedCount;
    }
    final rawCount = int.tryParse(widget.ticket?['selectedCount'] ?? '');
    if (rawCount != null && rawCount > 0) {
      return rawCount;
    }
    return 1;
  }

  double get totalPayableAmount {
    if (widget.totalAmount != null && widget.totalAmount! > 0) {
      return widget.totalAmount!;
    }
    final rawTotal = double.tryParse(widget.ticket?['totalPrice'] ?? '');
    if (rawTotal != null && rawTotal > 0) {
      return rawTotal;
    }
    return unitTicketPrice * selectedQuantity;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      if (user != null) {
        final walletProv = Provider.of<WalletProvider>(context, listen: false);
        walletProv.fetchOrCreateWallet(
          userId: user.id.toString(),
          userEmail: user.email,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);
    final double walletBalance = walletProv.balance;
    final double total = totalPayableAmount;
    final bool hasSufficientBalance = walletBalance >= total;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // GaGa App Header with integrated borderless Balance Card
          GaGaAppHeader(
            showBackButton: widget.showBackButton,
            subtitle: 'Purchase Ticket • Confirm Order',
            showBalance: true,
            balance: walletBalance,
            showRechargeButton: true,
            onRechargeTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WalletPage()),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ticket & Draw Hero Card
                  _buildTicketHeroCard(),

                  const SizedBox(height: 14),

                  // 2. FinTech Order & Payment Breakdown
                  _buildOrderSummaryCard(total),

                  const SizedBox(height: 14),

                  // 3. Payment Method & Wallet Status
                  _buildPaymentMethodCard(total, hasSufficientBalance),

                  const SizedBox(height: 20),

                  // 4. Branded Primary Confirm / Recharge Action Button
                  _buildConfirmButton(total, hasSufficientBalance),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Ticket & Draw Hero Information Card
  Widget _buildTicketHeroCard() {
    final String name = ticketName;
    final String date = drawDate;
    final String time = drawTime;
    final int qty = selectedQuantity;
    final double uPrice = unitTicketPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row with Emblem, Title & Active Badge
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.16),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF0F3B2C),
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      qty > 1
                          ? '$qty Tambola Tickets Selected'
                          : 'Live Tambola Housie Draw',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: AppColors.primaryGreen,
                      size: 11,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          const SizedBox(height: 12),

          // 3-Column Info Chips: Date, Time, Price
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: 'Draw Date',
                  value: date.isNotEmpty ? date : 'Live Today',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  label: 'Draw Time',
                  value: time.isNotEmpty ? time : 'Upcoming',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.sell_outlined,
                  label: qty > 1 ? 'Price/Ticket' : 'Ticket Price',
                  value: '₹${uPrice.toStringAsFixed(0)}',
                  isPrice: true,
                ),
              ),
            ],
          ),
          if (widget.selectedSlNos != null && widget.selectedSlNos!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00B894).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: Color(0xFF00B894),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Selected SL: ${widget.selectedSlNos!.join(', ')} ($qty tickets)',
                    style: const TextStyle(
                      color: Color(0xFF0F3B2C),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    bool isPrice = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.primaryGreen),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isPrice ? AppColors.primaryGreen : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// FinTech-Grade Order Breakdown Card
  Widget _buildOrderSummaryCard(double total) {
    final int qty = selectedQuantity;
    final double uPrice = unitTicketPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primaryGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Breakdown',
                style: TextStyle(
                  color: Color(0xFF0F3B2C),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.black.withOpacity(0.06), height: 1),
          const SizedBox(height: 10),

          if (qty > 1) ...[
            _buildBreakdownRow(
              'Price per Ticket',
              '₹${uPrice.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 6),
            _buildBreakdownRow(
              'Selected Quantity',
              '$qty tickets${widget.selectedSlNos != null && widget.selectedSlNos!.isNotEmpty ? " (SL: ${widget.selectedSlNos!.join(', ')})" : ""}',
            ),
            const SizedBox(height: 6),
            _buildBreakdownRow(
              'Subtotal ($qty × ₹${uPrice.toStringAsFixed(0)})',
              '₹${(uPrice * qty).toStringAsFixed(2)}',
            ),
          ] else ...[
            _buildBreakdownRow(
              'Ticket Price',
              '₹${uPrice.toStringAsFixed(2)}',
            ),
          ],
          const SizedBox(height: 6),
          _buildBreakdownRow(
            'Convenience Fee',
            'FREE',
            isGreen: true,
          ),
          const SizedBox(height: 6),
          _buildBreakdownRow(
            'Current Wallet Balance',
            '₹${walletBalance.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6),
          _buildBreakdownRow(
            'Balance After Purchase',
            walletBalance >= total
                ? '₹${(walletBalance - total).toStringAsFixed(2)}'
                : 'Insufficient Funds',
            isGreen: walletBalance >= total,
            isAlert: walletBalance < total,
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.black.withOpacity(0.08), height: 1),
          const SizedBox(height: 10),

          // Total Payable Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable',
                style: TextStyle(
                  color: Color(0xFF0F3B2C),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value,
      {bool isGreen = false, bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isAlert
                ? const Color(0xFFDC2626)
                : isGreen
                    ? AppColors.primaryGreen
                    : const Color(0xFF1E293B),
            fontSize: 13,
            fontWeight:
                (isGreen || isAlert) ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Payment Method & Status Card
  Widget _buildPaymentMethodCard(double total, bool hasSufficientBalance) {
    if (hasSufficientBalance) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primaryGreen.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primaryGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GaGa Wallet (₹${walletBalance.toStringAsFixed(2)})',
                    style: const TextStyle(
                      color: Color(0xFF0F3B2C),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Instant 1-Click Deduction • Secure',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ],
        ),
      );
    } else {
      final double shortfall = total - walletBalance;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFCA5A5),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insufficient Wallet Balance',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Need ₹${shortfall.toStringAsFixed(2)} more to confirm order',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Recharge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildConfirmButton(double total, bool hasSufficientBalance) {
    if (hasSufficientBalance) {
      return Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF092E20),
              Color(0xFF13523A),
              Color(0xFF00B894),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isPurchasing ? null : () => _confirmPurchase(total),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isPurchasing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Deducting from Wallet...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Confirm Purchase (₹${total.toStringAsFixed(2)})',
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
    } else {
      final double shortfall = total - walletBalance;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Recharge Wallet (Add ₹${shortfall.toStringAsFixed(2)})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  Future<void> _confirmPurchase(double total) async {
    final walletProv = Provider.of<WalletProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (walletProv.balance < total) {
      _showInsufficientBalanceDialog(total - walletProv.balance);
      return;
    }

    setState(() => _isPurchasing = true);

    final String receiptId =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final String tTitle = ticketName;
    final String tDate = drawDate.isNotEmpty ? drawDate : 'Live Today';
    final int qty = selectedQuantity;
    final slNosStr = widget.selectedSlNos != null && widget.selectedSlNos!.isNotEmpty
        ? ' (SL: ${widget.selectedSlNos!.join(', ')})'
        : (qty > 1 ? ' ($qty tickets)' : '');

    try {
      final success = await walletProv.deductForPurchase(
        userId: user?.id?.toString() ?? '1',
        userEmail: user?.email ?? 'user@gagahousie.com',
        amount: total,
        description: 'Purchased $tTitle$slNosStr',
        referenceId: 'RCP-$receiptId',
      );

      if (success) {
        // Record ticket purchase in public.ticket_purchases and mark tambola_tickets as Sold Out
        try {
          final sls = widget.selectedSlNos ?? [1];
          final Map<int, List<List<int?>>> gridMap = {};
          final Map<int, String> snMap = {};
          final Map<int, String> codeMap = {};

          if (widget.selectedTambolaTickets != null) {
            for (final tkt in widget.selectedTambolaTickets!) {
              final sl = tkt['slNo'] is int
                  ? tkt['slNo'] as int
                  : int.tryParse(tkt['slNo']?.toString() ?? '1') ?? 1;
              if (tkt['ticketData'] != null) {
                final raw = tkt['ticketData'];
                if (raw is Map && raw['ticketData'] is List) {
                  gridMap[sl] = (raw['ticketData'] as List)
                      .map<List<int?>>((r) => (r as List)
                          .map<int?>((c) =>
                              c == null ? null : int.tryParse(c.toString()))
                          .toList())
                      .toList();
                } else if (raw is List) {
                  gridMap[sl] = raw
                      .map<List<int?>>((r) => (r as List)
                          .map<int?>((c) =>
                              c == null ? null : int.tryParse(c.toString()))
                          .toList())
                      .toList();
                }
              }
              if (tkt['serialNumber'] != null) {
                snMap[sl] = tkt['serialNumber'].toString();
              }
              if (tkt['uniqueCode'] != null) {
                codeMap[sl] = tkt['uniqueCode'].toString();
              }
            }
          }

          final tid = ticketId;
          await TicketService.instance.recordTicketPurchase(
            userId: user?.id ?? 1,
            userEmail: user?.email ?? 'user@gagahousie.com',
            userName: user?.fullName ?? 'Player',
            ticketId: tid,
            ticketTitle: tTitle,
            drawDate: tDate,
            drawTime: drawTime,
            slNos: sls,
            pricePerTicket: widget.unitPrice ?? (total / sls.length),
            ticketDataBySl: gridMap.isNotEmpty ? gridMap : null,
            serialNumberBySl: snMap.isNotEmpty ? snMap : null,
            uniqueCodeBySl: codeMap.isNotEmpty ? codeMap : null,
          );

          if (mounted) {
            // Refresh tambola tickets in TicketProvider cache so status becomes Sold Out
            final ticketProv =
                Provider.of<TicketProvider>(context, listen: false);
            await ticketProv.fetchTambolaTickets(tid);
          }
        } catch (e) {
          debugPrint('⚠️ [RECORD PURCHASE NOTICE] $e');
        }
      }

      setState(() => _isPurchasing = false);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(walletProv.errorMessage ??
                  'Payment deduction failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        _showSuccessDialog(total, receiptId, tTitle, tDate);
      }
    } on InsufficientBalanceException catch (e) {
      setState(() => _isPurchasing = false);
      if (mounted) {
        _showInsufficientBalanceDialog(e.required - e.available);
      }
    } catch (e) {
      setState(() => _isPurchasing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showInsufficientBalanceDialog(double shortfall) {
    showDialog(
      context: context,
      builder: (ctx) {
        final walletProv = Provider.of<WalletProvider>(context, listen: false);
        return AlertDialog(
          backgroundColor: const Color(0xFF0D281E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), size: 26),
              SizedBox(width: 8),
              Text(
                'Insufficient Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance: ₹${walletProv.balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You need ₹${shortfall.toStringAsFixed(2)} more in your GaGa wallet to purchase this ticket.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please top up your wallet with UPI or Bank screenshot to proceed.',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Recharge Wallet Now'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(
      double total, String receiptId, String ticketTitle, String ticketDate) {
    final walletProv = Provider.of<WalletProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Celebratory Emerald Checkmark
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGreen.withOpacity(0.12),
                    ),
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF092E20),
                              Color(0xFF13523A),
                              Color(0xFF00B894),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B894).withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Title and Subtitle
                const Text(
                  'Purchase Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0F3B2C),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your Tambola ticket is officially booked and registered for the live draw.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 16),

                // Digital Receipt Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.2),
                      width: 1.1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Receipt Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.primaryGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'RECEIPT #GH-$receiptId',
                                style: const TextStyle(
                                  color: Color(0xFF0F3B2C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    color: AppColors.primaryGreen, size: 11),
                                SizedBox(width: 3),
                                Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Colors.black.withOpacity(0.06), height: 1),
                      const SizedBox(height: 10),

                      _buildDialogRow('Ticket:', ticketTitle),
                      const SizedBox(height: 6),
                      _buildDialogRow('Draw Date:', ticketDate),
                      const SizedBox(height: 6),
                      if (selectedQuantity > 1) ...[
                        _buildDialogRow('Selected Quantity:', '$selectedQuantity tickets'),
                        const SizedBox(height: 6),
                        _buildDialogRow('Price per ticket:',
                            '₹${unitTicketPrice.toStringAsFixed(2)}'),
                      ] else ...[
                        _buildDialogRow('Ticket Price:',
                            '₹${unitTicketPrice.toStringAsFixed(2)}'),
                      ],
                      const SizedBox(height: 10),
                      Divider(color: Colors.black.withOpacity(0.06), height: 1),
                      const SizedBox(height: 10),
                      _buildDialogRow(
                          'Total Paid:', '₹${total.toStringAsFixed(2)}',
                          isHighlight: true),
                      const SizedBox(height: 6),
                      _buildDialogRow(
                        'Remaining Balance:',
                        '₹${walletProv.balance.toStringAsFixed(2)}',
                        isSuccess: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Action 1: View My Tickets (Primary branded gradient button)
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF092E20),
                        Color(0xFF13523A),
                        Color(0xFF00B894),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Dismiss dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyTicketsPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'View My Tickets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Action 2: Done • Back to Draws (Secondary button)
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Dismiss dialog
                      Navigator.pop(context); // Return to previous screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '₹${total.toStringAsFixed(2)} paid successfully! Ticket confirmed.'),
                          backgroundColor: AppColors.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: const Text(
                      'Done • Back to Draws',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogRow(String label, String value,
      {bool isHighlight = false, bool isSuccess = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                isHighlight ? const Color(0xFF0F3B2C) : const Color(0xFF64748B),
            fontSize: isHighlight ? 14 : 13,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: isSuccess
                ? AppColors.primaryGreen
                : isHighlight
                    ? const Color(0xFF0F3B2C)
                    : const Color(0xFF1E293B),
            fontSize: isHighlight ? 15 : 13,
            fontWeight:
                (isHighlight || isSuccess) ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
