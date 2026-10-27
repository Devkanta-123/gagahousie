import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ticket_model.dart';
import '../models/tambola_ticket_model.dart';
import '../providers/ticket_provider.dart';
import '../services/tambola_excel_service.dart';
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

    final isExistingInTicket = _usedNumbersInActiveTicket.contains(number);
    final isCellOccupied = _activeTicket.ticketData[row][col] != null;

    // Strict 15 numbers max per Tambola ticket validation
    if (!isExistingInTicket &&
        !isCellOccupied &&
        _activeTicket.filledNumbersCount >= 15) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Maximum 15 numbers allowed per Tambola ticket. Cannot add more.'),
          backgroundColor: Color(0xFFE53935),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Row 5-number maximum limit validation
    final rowCount =
        _activeTicket.ticketData[row].where((c) => c != null).length;
    final isReplacingInRow = _activeTicket.ticketData[row][col] != null;
    final isMovingWithinSameRow =
        _activeTicket.ticketData[row].contains(number);
    if (!isReplacingInRow && !isMovingWithinSameRow && rowCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Row ${row + 1} already has maximum 5 numbers.'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
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
    final isExistingInTicket = _usedNumbersInActiveTicket.contains(number);
    if (!isExistingInTicket && _activeTicket.filledNumbersCount >= 15) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⚠️ Maximum 15 numbers allowed per Tambola ticket. Cannot add more.'),
          backgroundColor: Color(0xFFE53935),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int targetCol = -1;
    for (int col = 0; col < 9; col++) {
      if (isValidForColumn(number, col)) {
        targetCol = col;
        break;
      }
    }
    if (targetCol == -1) return;

    // Find first empty cell in this column where row has < 5 numbers
    for (int row = 0; row < 3; row++) {
      if (_activeTicket.ticketData[row][targetCol] == null) {
        final rowCount =
            _activeTicket.ticketData[row].where((c) => c != null).length;
        if (rowCount < 5) {
          _setCell(row, targetCol, number);
          return;
        }
      }
    }

    // If column is full or rows in that column already have 5 numbers
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Cannot place in Column ${targetCol + 1} (already full or row has 5 numbers).'),
        duration: const Duration(milliseconds: 1200),
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

  /// Pick an Excel (.xlsx, .xls) or CSV file and load Tambola tickets
  Future<void> _handleUploadExcel() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (files.isEmpty) {
        return; // User cancelled
      }

      final file = files.first;
      Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (readErr) {
        if (file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        } else {
          rethrow;
        }
      }

      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Selected file is empty. Please try another file.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      final importResult = TambolaExcelService.instance.parseBytes(
        bytes,
        file.name,
        widget.ticket.ticketId,
        existingTickets: _tickets,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (!mounted) return;

      if (importResult.success && importResult.tickets.isNotEmpty) {
        setState(() {
          // Fill all imported tickets into _tickets
          for (final imported in importResult.tickets) {
            final idx = imported.slNo - 1;
            if (idx >= 0 && idx < _tickets.length) {
              _tickets[idx] = imported;
            } else if (idx >= _tickets.length && _tickets.length < 12) {
              _tickets.add(imported);
            }
          }
          _activeSlIndex = 0; // Point to SL 1
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Successfully filled cells for ${importResult.tickets.length} tickets from ${file.name}!',
            ),
            backgroundColor: const Color(0xFF107C41),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // Open detailed review dialog
        _showImportReviewDialog(importResult, file.name);
      } else {
        _showImportErrorDialog(importResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error uploading Excel file: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  /// Review bottom sheet shown immediately after Excel upload
  void _showImportReviewDialog(TambolaImportResult result, String fileName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final completeCount = result.tickets.where((t) => t.isComplete).length;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF107C41),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Excel Upload Successful! 🎉',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Stats Row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${result.tickets.length}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF107C41),
                                    ),
                                  ),
                                  const Text(
                                    'Tickets Loaded',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '${result.totalNumbersCount}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  const Text(
                                    'Numbers Filled',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 30, color: Colors.grey.shade300),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    '$completeCount/${result.tickets.length}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: completeCount == result.tickets.length
                                          ? const Color(0xFF107C41)
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                  const Text(
                                    '15/15 Complete',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Step-by-step guidance banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00B894).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00B894).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: Color(0xFF00B894),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'All cells have been populated into the grid. You can switch between tickets (SL 1 to 6) to review, tap any cell to change numbers, and tap "Save Tambola Tickets" when satisfied.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (result.warnings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 16, color: Colors.orange.shade800),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Notes (${result.warnings.length}):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ...result.warnings.map(
                                (w) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    '• $w',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const Text(
                        'Imported Tickets Breakdown:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // List of tickets preview
                      ...List.generate(result.tickets.length, (idx) {
                        final t = result.tickets[idx];
                        final isFull = t.isComplete;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFull
                                  ? const Color(0xFF00B894).withOpacity(0.3)
                                  : Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? const Color(0xFF00B894)
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${t.slNo}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SL ${t.slNo} (${t.slNo <= 3 ? "Set 1" : "Set 2"})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      t.serialNumber,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isFull
                                      ? const Color(0xFFE8F5E9)
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isFull
                                      ? '✓ 15 Numbers'
                                      : '${t.filledNumbersCount}/15 Numbers',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isFull
                                        ? const Color(0xFF2E7D32)
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Review & Edit Cells',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleSave();
                        },
                        icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                        label: const Text('Save to DB'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dialog shown when Excel parsing fails or no tickets are recognized
  void _showImportErrorDialog(TambolaImportResult result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Import Failed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.message,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...result.errors.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $e', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Tip: You can download our sample Excel template to view the expected format.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF107C41)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showTemplateDialog();
              },
              child: const Text('View Template', style: TextStyle(color: Color(0xFF107C41), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Template & formatting guide modal with one-tap Download Sample Excel
  void _showTemplateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF107C41).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: Color(0xFF107C41),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Excel Format & Template Guide',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Standard Tambola Sheet Layout',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Guide content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📋 How to Format Your Excel / CSV File:',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildRuleItem('1', '3 Rows x 9 Columns per Ticket: Each ticket has exactly 3 rows and 9 columns.'),
                      _buildRuleItem('2', '5 Numbers per Row: Exactly 5 filled numbers and 4 empty cells per row (15 numbers per ticket).'),
                      _buildRuleItem('3', 'Column Decades:\n • Col 1: 1–9\n • Col 2: 10–19\n • Col 3: 20–29\n • Col 4: 30–39\n • Col 5: 40–49\n • Col 6: 50–59\n • Col 7: 60–69\n • Col 8: 70–79\n • Col 9: 80–90'),
                      _buildRuleItem('4', 'Leave blank spaces empty (or empty cell) in Excel.'),
                      _buildRuleItem('5', 'Separate tickets with a label row e.g. "SL 1", "SL 2" or blank lines. A standard sheet has SL 1 to SL 6.'),

                      const SizedBox(height: 16),
                      const Text(
                        'Visual Example Preview:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Example table preview
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SL 1 (Set 1)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF107C41),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              children: const [
                                TableRow(children: [
                                  Center(child: Text('4', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('25', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('41', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('62', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('85', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                ]),
                                TableRow(children: [
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('12', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('33', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('55', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('74', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                ]),
                                TableRow(children: [
                                  Center(child: Text('7', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('29', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('48', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('', style: TextStyle(fontSize: 11))),
                                  Center(child: Text('79', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                  Center(child: Text('90', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                                ]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          final savedPath = await TambolaExcelService.exportSampleExcel(
                            ticketId: widget.ticket.ticketId,
                          );
                          if (!mounted) return;
                          if (savedPath != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('📥 Sample Excel template saved to:\n$savedPath'),
                                backgroundColor: const Color(0xFF107C41),
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label: 'Dismiss',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('⚠️ Could not save sample Excel.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download Sample Excel (.xlsx)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF107C41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF107C41).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF107C41),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cell Action Modal: Allows inspecting, replacing, or clearing a filled cell
  void _showCellActionModal(int row, int col, int currentNumber) {
    final colMin = getColMin(col);
    final colMax = getColMax(col);
    final usedInTicket = _usedNumbersInActiveTicket;

    // Available unused numbers for this column
    final availableInCol = <int>[];
    for (int n = colMin; n <= colMax; n++) {
      if (!usedInTicket.contains(n)) {
        availableInCol.add(n);
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Cell: Row ${row + 1}, Col ${col + 1}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Column Decade: $colMin to $colMax',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$currentNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Replace with Unused Number in this Column:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              if (availableInCol.isEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No other unused numbers available in this column.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableInCol.map((n) {
                    return ActionChip(
                      label: Text(
                        '$n',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.08),
                      side: BorderSide(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _setCell(row, col, n);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearCell(row, col);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.red),
                      label: const Text(
                        'Clear Cell',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _selectedColTab = col + 1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Filter Tray to Col',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Save all tickets to Supabase DB
  Future<void> _handleSave() async {
    // Validate maximum 15 numbers per ticket constraint
    for (int i = 0; i < _tickets.length; i++) {
      final t = _tickets[i];
      if (t.filledNumbersCount > 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ SL ${i + 1} has ${t.filledNumbersCount} numbers. Maximum allowed is 15.'),
            backgroundColor: const Color(0xFFE53935),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      for (int r = 0; r < 3; r++) {
        final rowCount = t.ticketData[r].where((c) => c != null).length;
        if (rowCount > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '⚠️ SL ${i + 1} Row ${r + 1} has $rowCount numbers. Maximum allowed is 5.'),
              backgroundColor: const Color(0xFFE53935),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
    }

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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Upload from Excel',
                  icon: const Icon(Icons.table_chart_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _handleUploadExcel,
                ),
                IconButton(
                  tooltip: 'Excel Template',
                  icon: const Icon(Icons.download_rounded,
                      color: Colors.white, size: 20),
                  onPressed: _showTemplateDialog,
                ),
              ],
            ),
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

                    // Excel Upload Banner Card
                    _buildExcelUploadCard(),

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
          Expanded(
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ticket.ticketTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'ID: ${widget.ticket.ticketId} • Draw: ${widget.ticket.drawDate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

  /// Banner card promoting Excel upload and template guidance
  Widget _buildExcelUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF107C41).withOpacity(0.08),
            AppColors.primaryGreen.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF107C41).withOpacity(0.28),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF107C41), // Microsoft Excel Green
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bulk Import Tambola Tickets from Excel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Upload spreadsheet (.xlsx, .xls, .csv) to auto-fill cells instantly',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _handleUploadExcel,
                  icon: const Icon(Icons.file_upload_outlined, size: 15),
                  label: const Text('Upload Excel Sheet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF107C41),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _showTemplateDialog,
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: const Text('Template'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF107C41),
                    side: const BorderSide(color: Color(0xFF107C41), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
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
            const Flexible(
              child: Text(
                'Select Ticket SL to Edit:',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Set 1: SL 1–3 • Set 2: SL 4–6',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                ),
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
                        final val = details.data;
                        if (!isValidForColumn(val, colIndex)) return false;
                        final isExisting =
                            _usedNumbersInActiveTicket.contains(val);
                        final isFree = grid[rowIndex][colIndex] == null;
                        if (!isExisting &&
                            isFree &&
                            _activeTicket.filledNumbersCount >= 15) {
                          return false; // Reject exceeding 15 numbers limit
                        }
                        final rowCount =
                            grid[rowIndex].where((c) => c != null).length;
                        final isReplacingInRow =
                            grid[rowIndex][colIndex] != null;
                        final isMovingInSameRow =
                            grid[rowIndex].contains(val);
                        if (!isReplacingInRow &&
                            !isMovingInSameRow &&
                            rowCount >= 5) {
                          return false; // Reject exceeding 5 numbers per row limit
                        }
                        return true;
                      },
                      onAcceptWithDetails: (details) {
                        _setCell(rowIndex, colIndex, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;

                        return GestureDetector(
                          onTap: () {
                            if (!isFreeSlot) {
                              _showCellActionModal(rowIndex, colIndex, number);
                            } else {
                              setState(() => _selectedColTab = colIndex + 1);
                            }
                          },
                          onLongPress: () {
                            if (!isFreeSlot) {
                              _clearCell(rowIndex, colIndex);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cleared number $number from cell.'),
                                  duration: const Duration(milliseconds: 700),
                                ),
                              );
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Upload from Excel button
          ElevatedButton.icon(
            onPressed: _handleUploadExcel,
            icon: const Icon(Icons.table_chart_rounded, size: 14),
            label: const Text('Upload Excel'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF107C41),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Auto-fill active ticket
          OutlinedButton.icon(
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
          const SizedBox(width: 8),

          // Auto-fill all 6 tickets
          OutlinedButton.icon(
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
      ),
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
          // Tray Header (Responsive)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 15,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Number Bank • Drag/Tap',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${90 - usedNumbers.length} Left',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
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

    final draggable = Draggable<int>(
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
      child: chip,
    );

    return GestureDetector(
      key: ValueKey('number_chip_$number'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapToPlace(number),
      child: draggable,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$completedCount of 6 Complete',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '$totalFilled/90 Numbers Set',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 15),
              label: Text(
                  _isSaving ? 'Saving...' : 'Save Tickets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
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
