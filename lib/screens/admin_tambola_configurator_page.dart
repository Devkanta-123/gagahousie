import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/tambola_ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../utils/constants.dart';
import '../widgets/gaga_app_header.dart';

class AdminTambolaConfiguratorPage extends StatefulWidget {
  final TicketModel ticket;

  const AdminTambolaConfiguratorPage({
    super.key,
    required this.ticket,
  });

  @override
  State<AdminTambolaConfiguratorPage> createState() =>
      _AdminTambolaConfiguratorPageState();
}

class _AdminTambolaConfiguratorPageState
    extends State<AdminTambolaConfiguratorPage> {
  // 6 Tambola tickets corresponding to SL 1..6
  late List<TambolaTicketModel> _tickets;
  int _activeSlIndex = 0; // 0 to 5 for SL 1..6
  int _selectedColTab = 0; // 0 for All, or 1..9 for column decade
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initTickets();
    _loadFromDatabase();
  }

  /// Initialize 6 empty tickets as requested ("first the empty tambola will appear")
  void _initTickets() {
    _tickets = List.generate(
      6,
      (index) => TambolaTicketModel.empty(widget.ticket.ticketId, index + 1),
    );
  }

  /// Check if tickets already exist in DB / Provider cache
  Future<void> _loadFromDatabase() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);

    // Check cached first
    final cached = provider.getCachedTambolaTickets(widget.ticket.ticketId);
    if (cached != null && cached.isNotEmpty) {
      _applyLoadedTickets(cached);
      setState(() => _isLoading = false);
      return;
    }

    // Fetch from Supabase
    final fetched = await provider.fetchTambolaTickets(widget.ticket.ticketId);
    if (fetched.isNotEmpty && mounted) {
      _applyLoadedTickets(fetched);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _applyLoadedTickets(List<TambolaTicketModel> loaded) {
    for (final loadedTicket in loaded) {
      final index = loadedTicket.slNo - 1;
      if (index >= 0 && index < _tickets.length) {
        _tickets[index] = loadedTicket;
      }
    }
  }

  TambolaTicketModel get _activeTicket => _tickets[_activeSlIndex];

  /// Get decade min/max for a column (0 to 8)
  static int getColMin(int col) => col == 0 ? 1 : col * 10;
  static int getColMax(int col) => col == 8 ? 90 : (col * 10) + 9;

  /// Validate if a number belongs to a given column
  static bool isValidForColumn(int number, int col) {
    return number >= getColMin(col) && number <= getColMax(col);
  }

  /// Get numbers already placed in the active ticket
  Set<int> get _usedNumbersInActiveTicket {
    final set = <int>{};
    for (final row in _activeTicket.ticketData) {
      for (final cell in row) {
        if (cell != null) set.add(cell);
      }
    }
    return set;
  }

  /// Set a number in a specific cell
  void _setCell(int row, int col, int number) {
    if (!isValidForColumn(number, col)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ $number is invalid for Column ${col + 1} (${getColMin(col)}-${getColMax(col)})'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final newGrid = List<List<int?>>.from(
      _activeTicket.ticketData.map((r) => List<int?>.from(r)),
    );

    // Remove this number if it was already placed elsewhere in this ticket
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 9; c++) {
        if (newGrid[r][c] == number) {
          newGrid[r][c] = null;
        }
      }
    }

    newGrid[row][col] = number;

    setState(() {
      _tickets[_activeSlIndex] = _activeTicket.copyWith(ticketData: newGrid);
    });
  }

  /// Clear a specific cell
  void _clearCell(int row, int col) {
    if (_activeTicket.ticketData[row][col] == null) return;

    final newGrid = List<List<int?>>.from(
      _activeTicket.ticketData.map((r) => List<int?>.from(r)),
    );
    newGrid[row][col] = null;

    setState(() {
      _tickets[_activeSlIndex] = _activeTicket.copyWith(ticketData: newGrid);
    });
  }

  /// Tap-to-place helper: places number in the first available empty slot of that column
  void _tapToPlace(int number) {
    int targetCol = -1;
    for (int col = 0; col < 9; col++) {
      if (isValidForColumn(number, col)) {
        targetCol = col;
        break;
      }
    }
    if (targetCol == -1) return;

    // Find first empty cell in this column
    for (int row = 0; row < 3; row++) {
      if (_activeTicket.ticketData[row][targetCol] == null) {
        _setCell(row, targetCol, number);
        return;
      }
    }

    // If column is already full (3 rows)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Column ${targetCol + 1} is already full in this ticket.'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  /// Clear the active ticket to all empty cells
  void _clearActiveTicket() {
    setState(() {
      _tickets[_activeSlIndex] = TambolaTicketModel.empty(
        widget.ticket.ticketId,
        _activeSlIndex + 1,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared SL ${_activeSlIndex + 1} to empty grid.'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  /// Auto-fill current ticket with valid random Tambola numbers
  void _autoFillActiveTicket() {
    setState(() {
      _tickets[_activeSlIndex] = TambolaTicketModel.generateRandom(
        widget.ticket.ticketId,
        _activeSlIndex + 1,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-filled SL ${_activeSlIndex + 1} with 15 numbers.'),
        backgroundColor: const Color(0xFF00B894),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  /// Auto-fill all 6 tickets at once
  void _autoFillAllTickets() {
    setState(() {
      for (int i = 0; i < _tickets.length; i++) {
        _tickets[i] = TambolaTicketModel.generateRandom(
          widget.ticket.ticketId,
          i + 1,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Auto-filled all 6 Tambola tickets!'),
        backgroundColor: Color(0xFF00B894),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Save all tickets to Supabase DB
  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<TicketProvider>(context, listen: false);

    final success = await provider.saveTambolaTickets(
      widget.ticket.ticketId,
      _tickets,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Saved 6 Tambola tickets for ${widget.ticket.ticketId} in DB!'),
          backgroundColor: const Color(0xFF196144),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '⚠️ Could not save to DB. Local changes are preserved.'),
          backgroundColor: Colors.amber.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          GaGaAppHeader(
            compact: true,
            title: 'Tambola Setup',
            subtitle: 'Draw: ${widget.ticket.ticketId} • Set Numbers',
            showBackButton: true,
            showSearch: false,
            showBalance: false,
            onBackPressed: () => Navigator.pop(context),
          ),

          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Info Card
                    _buildTopInfoCard(),

                    const SizedBox(height: 10),

                    // SL Selector Bar (SL 1 to SL 6)
                    _buildSlSelector(),

                    const SizedBox(height: 12),

                    // The Tambola Ticket Preview & Drag Target Grid
                    _buildTambolaGridCard(),

                    const SizedBox(height: 10),

                    // Quick Actions Row (Auto-fill, Clear)
                    _buildQuickActionButtons(),

                    const SizedBox(height: 12),

                    // Draggable Number Tray / Palette
                    _buildNumberTray(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

          // Bottom Action Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// Top Info Card with Main Draw Ticket Context
  Widget _buildTopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ticket.ticketTitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'ID: ${widget.ticket.ticketId} • Draw: ${widget.ticket.drawDate}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.ticket.price,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SL Selector: Horizontal pills for SL 1 through SL 6
  Widget _buildSlSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Ticket SL to Edit:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              'Set 1: SL 1–3 • Set 2: SL 4–6',
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(6, (index) {
            final isCurrent = index == _activeSlIndex;
            final ticket = _tickets[index];
            final filledCount = ticket.filledNumbersCount;
            final isComplete = ticket.isComplete;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeSlIndex = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primaryGreen
                        : (filledCount > 0
                            ? const Color(0xFFE8F5E9)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrent
                          ? AppColors.primaryGreen
                          : (filledCount > 0
                              ? AppColors.primaryGreen.withOpacity(0.3)
                              : Colors.grey.shade300),
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SL ${index + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white
                              : (filledCount > 0
                                  ? AppColors.primaryGreen
                                  : const Color(0xFF1F2937)),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isComplete ? '✓ 15' : '$filledCount/15',
                        style: TextStyle(
                          color: isCurrent
                              ? Colors.white70
                              : (filledCount > 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey.shade500),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
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
  }

  /// The Tambola Ticket Card (Layout matching ticket_selection_page.dart exactly)
  Widget _buildTambolaGridCard() {
    final ticket = _activeTicket;
    final grid = ticket.ticketData;
    final filledCount = ticket.filledNumbersCount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00B894),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B894).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row matching ticket_selection_page.dart
          Row(
            children: [
              // SL Number Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    ticket.slNo.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Title / Set label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambola Ticket SL ${ticket.slNo}',
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ticket.slNo <= 3 ? 'Set 1' : 'Set 2',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Serial Number
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00B894).withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  ticket.serialNumber,
                  style: const TextStyle(
                    color: Color(0xFF00B894),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Unique Code & Fill Count Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B894).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ticket.uniqueCode,
                  style: const TextStyle(
                    color: Color(0xFF00B894),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: filledCount == 15
                      ? const Color(0xFF00B894).withOpacity(0.15)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: filledCount == 15
                        ? const Color(0xFF00B894)
                        : Colors.amber.shade300,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '$filledCount / 15 Numbers',
                  style: TextStyle(
                    color: filledCount == 15
                        ? const Color(0xFF00B894)
                        : Colors.amber.shade900,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Tambola Ticket Grid (3 rows x 9 columns) with Drag Targets!
          ...List.generate(3, (rowIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: List.generate(9, (colIndex) {
                  final number = grid[rowIndex][colIndex];
                  final isFreeSlot = number == null;

                  return Expanded(
                    child: DragTarget<int>(
                      onWillAcceptWithDetails: (details) {
                        return isValidForColumn(details.data, colIndex);
                      },
                      onAcceptWithDetails: (details) {
                        _setCell(rowIndex, colIndex, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            if (!isFreeSlot) {
                              _clearCell(rowIndex, colIndex);
                            } else {
                              setState(() => _selectedColTab = colIndex + 1);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            height: 32,
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? const Color(0xFF00B894).withOpacity(0.3)
                                  : (isFreeSlot
                                      ? Colors.grey.withOpacity(0.05)
                                      : const Color(0xFF00B894)
                                          .withOpacity(0.15)),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isHovered
                                    ? const Color(0xFF00B894)
                                    : (isFreeSlot
                                        ? Colors.grey.withOpacity(0.2)
                                        : const Color(0xFF00B894)),
                                width: isHovered || !isFreeSlot ? 1.5 : 0.8,
                              ),
                            ),
                            child: Center(
                              child: isFreeSlot
                                  ? (isHovered
                                      ? const Icon(
                                          Icons.add_rounded,
                                          size: 14,
                                          color: Color(0xFF00B894),
                                        )
                                      : Text(
                                          '·',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 16,
                                          ),
                                        ))
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          number.toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF00B894),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            );
          }),

          // Column Headers (1-9, 10-19, ..., 80-90)
          Row(
            children: List.generate(9, (index) {
              final min = getColMin(index);
              final max = getColMax(index);
              final isSelectedCol = _selectedColTab == index + 1;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedColTab = index + 1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelectedCol
                          ? const Color(0xFF00B894).withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Center(
                      child: Text(
                        '$min-$max',
                        style: TextStyle(
                          color: isSelectedCol
                              ? const Color(0xFF00B894)
                              : Colors.grey.shade600,
                          fontSize: 7.5,
                          fontWeight: isSelectedCol
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Quick Action Buttons (Auto-fill, Clear)
  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        // Auto-fill active ticket
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _autoFillActiveTicket,
            icon: const Icon(Icons.shuffle_rounded, size: 14),
            label: const Text('Auto-Fill SL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: BorderSide(
                  color: AppColors.primaryGreen.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Auto-fill all 6 tickets
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _autoFillAllTickets,
            icon: const Icon(Icons.auto_awesome_rounded, size: 14),
            label: const Text('Fill All 6 SL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0284C7),
              side: const BorderSide(color: Color(0xFF38BDF8)),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Clear ticket
        OutlinedButton.icon(
          onPressed: _clearActiveTicket,
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          label: const Text('Clear'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            side: BorderSide(color: Colors.red.shade300),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Draggable Number Tray / Palette
  Widget _buildNumberTray() {
    final usedNumbers = _usedNumbersInActiveTicket;

    // Filter numbers depending on selected tab
    List<int> numbersToShow;
    if (_selectedColTab == 0) {
      numbersToShow = List.generate(90, (i) => i + 1);
    } else {
      final col = _selectedColTab - 1;
      final min = getColMin(col);
      final max = getColMax(col);
      numbersToShow = List.generate(max - min + 1, (i) => min + i);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tray Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    size: 15,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Number Bank • Drag or Tap to Place',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Text(
                '${90 - usedNumbers.length} Available',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Decade Column Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDecadeFilterTab(0, 'All (1-90)'),
                ...List.generate(9, (i) {
                  return _buildDecadeFilterTab(
                    i + 1,
                    'Col ${i + 1} (${getColMin(i)}-${getColMax(i)})',
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Numbers Grid (Draggable Number Chips)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: numbersToShow.map((numberVal) {
              final isUsed = usedNumbers.contains(numberVal);
              return _buildDraggableNumberChip(numberVal, isUsed);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDecadeFilterTab(int index, String label) {
    final isSelected = _selectedColTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedColTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.primaryGreen,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Draggable Number Chip with feedback and tap-to-place
  Widget _buildDraggableNumberChip(int number, bool isUsed) {
    final chip = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUsed
            ? Colors.grey.shade200
            : AppColors.primaryGreen.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: isUsed
              ? Colors.grey.shade300
              : AppColors.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: TextStyle(
            color: isUsed ? Colors.grey.shade400 : AppColors.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            decoration: isUsed ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );

    if (isUsed) {
      return chip;
    }

    return Draggable<int>(
      data: number,
      feedback: Material(
        elevation: 6,
        color: Colors.transparent,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppColors.greenGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: chip,
      ),
      child: GestureDetector(
        onTap: () => _tapToPlace(number),
        child: chip,
      ),
    );
  }

  /// Bottom Bar with summary and Save to DB action
  Widget _buildBottomBar() {
    final completedCount = _tickets.where((t) => t.isComplete).length;
    final totalFilled = _tickets.fold<int>(
        0, (acc, curr) => acc + curr.filledNumbersCount);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completedCount of 6 Complete',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  '$totalFilled/90 Total Numbers Set',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 16),
              label: Text(
                  _isSaving ? 'Saving to DB...' : 'Save Tambola Tickets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
