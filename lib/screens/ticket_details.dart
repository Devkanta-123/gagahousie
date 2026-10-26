import 'package:flutter/material.dart';
import '../models/ticket_purchase_model.dart';
import '../services/ticket_service.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';
import 'draw_page.dart';

class TicketDetailsPage extends StatefulWidget {
  final String ticketNumber;
  final String date;
  final String time;
  final String price;
  final String ticketId;
  final TicketPurchaseModel? purchase;
  final int? slNo;
  final List<List<int?>>? ticketData;
  final String? serialNumber;
  final String? uniqueCode;

  const TicketDetailsPage({
    super.key,
    required this.ticketNumber,
    required this.date,
    required this.time,
    required this.price,
    required this.ticketId,
    this.purchase,
    this.slNo,
    this.ticketData,
    this.serialNumber,
    this.uniqueCode,
  });

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  late List<List<int?>> _grid;
  late int _slNo;
  late String _serialNumber;
  late String _uniqueCode;
  late String _playerName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    if (widget.purchase != null) {
      _grid = widget.purchase!.ticketData;
      _slNo = widget.purchase!.slNo;
      _serialNumber = widget.purchase!.serialNumber;
      _uniqueCode = widget.purchase!.uniqueCode;
      _playerName = widget.purchase!.userName;
    } else {
      _slNo = widget.slNo ?? 1;
      _grid = widget.ticketData ??
          List.generate(3, (_) => List<int?>.filled(9, null));
      _serialNumber = widget.serialNumber ??
          'SN: TKT-${_slNo.toString().padLeft(3, '0')}';
      _uniqueCode =
          widget.uniqueCode ?? 'CODE: GH-${widget.ticketId}-SL$_slNo';
      _playerName = 'Player';

      final hasNumbers =
          _grid.any((row) => row.any((c) => c != null && c > 0));
      if (!hasNumbers) {
        _fetchTicketGrid();
      }
    }
  }

  Future<void> _fetchTicketGrid() async {
    setState(() => _isLoading = true);
    try {
      final tambolas =
          await TicketService.instance.fetchTambolaTickets(widget.ticketId);
      final match = tambolas.firstWhere(
        (t) => t.slNo == _slNo,
        orElse: () => tambolas.isNotEmpty ? tambolas.first : tambolas.first,
      );
      if (mounted) {
        setState(() {
          _grid = match.ticketData;
          _serialNumber = match.serialNumber;
          _uniqueCode = match.uniqueCode;
          _playerName =
              match.playerName.isNotEmpty && match.playerName != 'Available'
                  ? match.playerName
                  : 'Player';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.purchase?.ticketTitle ?? widget.ticketNumber;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          /// GA GA APP HEADER - Full width consistent branded header
          GaGaAppHeader(
            showBackButton: true,
            subtitle: '$title • Ticket Details',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingLarge),
              child: Column(
                children: [
                  /// MAIN TICKET CARD
                  _buildMainTicketCard(),
                  const SizedBox(height: 16),

                  /// ACTIVE TICKETS SECTION
                  _buildActiveTicketsSection(),
                  const SizedBox(height: 16),

                  /// ENTER LIVE DRAW BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF7971E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.play_circle_fill_rounded,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Play in Live Draw',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DrawPage(ticketId: widget.ticketId),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTicketCard() {
    final displayDate = widget.purchase?.drawDate.isNotEmpty == true
        ? widget.purchase!.drawDate
        : widget.date;
    final displayTime = widget.purchase?.drawTime.isNotEmpty == true
        ? widget.purchase!.drawTime
        : widget.time;
    final displayPrice = widget.purchase != null
        ? widget.purchase!.price.toStringAsFixed(0)
        : widget.price;

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
                    "₹$displayPrice",
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
            _infoRow("Ticket ID", widget.ticketId),
            const SizedBox(height: 8),
            _infoRow("SL Number", "SL #$_slNo"),
            const SizedBox(height: 8),
            _infoRow("Serial No.", _serialNumber),
            const SizedBox(height: 8),
            _infoRow("Date", displayDate),
            const SizedBox(height: 8),
            _infoRow("Time", displayTime),
            const SizedBox(height: 8),
            _infoRow("Status", "Booked & Active"),
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
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Your Tambola Ticket",
                style: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "SL #$_slNo",
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
        _buildTicketCard(
          playerName: _playerName,
          serialNumber: _serialNumber,
          uniqueCode: _uniqueCode,
          ticketData: _grid,
          slNo: _slNo,
        ),
      ],
    );
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
