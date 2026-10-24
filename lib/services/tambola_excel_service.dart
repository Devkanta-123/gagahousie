import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/tambola_ticket_model.dart';

/// Result container for Excel / CSV Tambola import
class TambolaImportResult {
  final bool success;
  final List<TambolaTicketModel> tickets;
  final String message;
  final List<String> warnings;
  final List<String> errors;
  final int totalNumbersCount;

  const TambolaImportResult({
    required this.success,
    required this.tickets,
    required this.message,
    this.warnings = const [],
    this.errors = const [],
    this.totalNumbersCount = 0,
  });
}

class TambolaExcelService {
  TambolaExcelService._();
  static final TambolaExcelService instance = TambolaExcelService._();

  /// Extract an integer from any Excel CellValue or dynamic object
  static int? extractInt(dynamic cellValue) {
    if (cellValue == null) return null;
    if (cellValue is IntCellValue) return cellValue.value;
    if (cellValue is DoubleCellValue) return cellValue.value.toInt();
    if (cellValue is TextCellValue) {
      final text = cellValue.value.text?.trim() ?? cellValue.toString().trim();
      return int.tryParse(text);
    }
    if (cellValue is FormulaCellValue) {
      final clean = cellValue.formula.replaceAll(RegExp(r'[^0-9]'), '').trim();
      return int.tryParse(clean);
    }
    final raw = cellValue.toString().trim();
    if (raw.isEmpty || raw == '-' || raw == '.' || raw.toLowerCase() == 'null') {
      return null;
    }
    return int.tryParse(raw);
  }

  /// Check if a cell contains an SL / Ticket header indicator, e.g. "SL 1", "Ticket 2", "SL: 3"
  static int? detectSlHeader(String text) {
    final clean = text.trim().toLowerCase();
    // Patterns like "sl 1", "sl-1", "sl1", "ticket 1", "ticket-1", "tkt 1", "t1"
    final slMatch = RegExp(r'^(?:sl|ticket|tkt|t)\s*[:#\-]?\s*(\d+)$').firstMatch(clean);
    if (slMatch != null) {
      return int.tryParse(slMatch.group(1)!);
    }
    // Also check for "sl 1 - set 1", "sl 1 (set 1)", etc.
    final slContainsMatch = RegExp(r'\b(?:sl|ticket)\s*[:#\-]?\s*(\d+)\b').firstMatch(clean);
    if (slContainsMatch != null) {
      return int.tryParse(slContainsMatch.group(1)!);
    }
    return null;
  }

  /// Get column index (0..8) for a number 1..90
  static int getColumnForNumber(int number) {
    if (number < 1 || number > 90) return -1;
    if (number <= 9) return 0;
    if (number >= 80) return 8;
    return number ~/ 10;
  }

  /// Main method: Parse raw bytes from .xlsx, .xls, or .csv
  TambolaImportResult parseBytes(
    Uint8List bytes,
    String fileName,
    String ticketId, {
    List<TambolaTicketModel>? existingTickets,
  }) {
    final lowerName = fileName.toLowerCase();
    final warnings = <String>[];
    final errors = <String>[];

    List<List<dynamic>> rows = [];

    if (lowerName.endsWith('.csv')) {
      try {
        final csvString = utf8.decode(bytes);
        rows = Csv().decoder.convert(csvString);
      } catch (e) {
        try {
          // Fallback decoding if utf8 fails (e.g. latin1)
          final latinString = latin1.decode(bytes);
          rows = Csv().decoder.convert(latinString);
        } catch (e2) {
          return TambolaImportResult(
            success: false,
            tickets: [],
            message: 'Failed to read CSV file: $e2',
            errors: ['Invalid CSV encoding or corrupt file.'],
          );
        }
      }
    } else {
      // Excel (.xlsx or .xls)
      try {
        final excel = Excel.decodeBytes(bytes);
        // Find non-empty sheets
        for (final table in excel.tables.keys) {
          final sheet = excel.tables[table];
          if (sheet == null) continue;
          for (final row in sheet.rows) {
            final rowValues = row.map((cell) => cell?.value).toList();
            // Only add if row has some non-null values
            if (rowValues.any((v) => v != null && v.toString().trim().isNotEmpty)) {
              rows.add(rowValues);
            }
          }
        }
      } catch (e) {
        // If Excel decode fails, try CSV as fallback
        try {
          final csvString = utf8.decode(bytes);
          rows = Csv().decoder.convert(csvString);
        } catch (_) {
          return TambolaImportResult(
            success: false,
            tickets: [],
            message: 'Failed to parse Excel file: $e',
            errors: ['Please ensure the file is a valid .xlsx, .xls, or .csv spreadsheet.'],
          );
        }
      }
    }

    if (rows.isEmpty) {
      return const TambolaImportResult(
        success: false,
        tickets: [],
        message: 'The uploaded file is empty.',
        errors: ['No data found in the spreadsheet.'],
      );
    }

    return _parseRows(rows, ticketId, existingTickets, warnings, errors);
  }

  /// Internal parser that inspects raw rows and reconstructs Tambola tickets
  TambolaImportResult _parseRows(
    List<List<dynamic>> rawRows,
    String ticketId,
    List<TambolaTicketModel>? existingTickets,
    List<String> warnings,
    List<String> errors,
  ) {
    // Map to hold grid data for each SL (1 to 6, or more)
    final Map<int, List<List<int?>>> ticketGrids = {};

    int currentSl = 1;
    List<List<int?>> currentTicketRows = [];

    void finalizeCurrentTicket() {
      if (currentTicketRows.isNotEmpty) {
        if (currentTicketRows.length == 3) {
          ticketGrids[currentSl] = currentTicketRows;
        } else if (currentTicketRows.length > 3) {
          // If more than 3 rows were captured, take first 3
          ticketGrids[currentSl] = currentTicketRows.sublist(0, 3);
          warnings.add('SL $currentSl had more than 3 rows; used the first 3 rows.');
        } else {
          // If fewer than 3 rows, pad with empty rows
          while (currentTicketRows.length < 3) {
            currentTicketRows.add(List<int?>.filled(9, null));
          }
          ticketGrids[currentSl] = currentTicketRows;
          warnings.add('SL $currentSl had fewer than 3 rows; padded missing rows with empty slots.');
        }
        currentTicketRows = [];
        currentSl++;
      }
    }

    for (int r = 0; r < rawRows.length; r++) {
      final row = rawRows[r];

      // Convert row to string / int representations
      final rowStrings = row.map((c) => c?.toString().trim() ?? '').toList();

      // Check if this row is an explicit SL or Ticket header
      int? foundSl;
      for (final cellStr in rowStrings) {
        if (cellStr.isNotEmpty) {
          final detected = detectSlHeader(cellStr);
          if (detected != null) {
            foundSl = detected;
            break;
          }
        }
      }

      if (foundSl != null) {
        finalizeCurrentTicket();
        currentSl = foundSl;
        continue;
      }

      // Check if this is a column header row like "1-9", "10-19", "Col 1", "Column 1"
      final isHeaderRow = rowStrings.any((s) =>
          RegExp(r'^(?:col|column|1-9|10-19|20-29|30-39|40-49|50-59|60-69|70-79|80-90|\d+-\d+)$',
                  caseSensitive: false)
              .hasMatch(s.replaceAll(' ', '')));
      if (isHeaderRow) {
        continue;
      }

      // Extract numeric cells from this row
      final List<int?> gridRow = List<int?>.filled(9, null);
      final List<int> numbersInRow = [];

      for (int c = 0; c < row.length && c < 9; c++) {
        final val = extractInt(row[c]);
        if (val != null && val >= 1 && val <= 90) {
          gridRow[c] = val;
          numbersInRow.add(val);
        }
      }

      // Check if the row has any numbers
      if (numbersInRow.isNotEmpty) {
        // If the row has 15 numbers (Compact single-row ticket format)
        final allNumbersInRow = <int>[];
        for (final cell in row) {
          final val = extractInt(cell);
          if (val != null && val >= 1 && val <= 90) {
            allNumbersInRow.add(val);
          }
        }

        if (allNumbersInRow.length >= 12 && allNumbersInRow.length <= 15) {
          // This row is a complete ticket in single-row format!
          finalizeCurrentTicket();
          final compactGrid = _buildGridFrom15Numbers(allNumbersInRow);
          ticketGrids[currentSl] = compactGrid;
          currentSl++;
          continue;
        }

        // Standard 3x9 grid row:
        // Ensure numbers are aligned with their proper columns
        final List<int?> alignedRow = List<int?>.filled(9, null);
        for (int c = 0; c < 9; c++) {
          final val = gridRow[c];
          if (val != null) {
            final properCol = getColumnForNumber(val);
            if (properCol == c) {
              alignedRow[c] = val;
            } else if (properCol != -1 && alignedRow[properCol] == null) {
              // Auto-align to correct column if displaced
              alignedRow[properCol] = val;
            } else {
              alignedRow[c] = val;
            }
          }
        }

        currentTicketRows.add(alignedRow);

        // When we accumulate 3 rows, we have a complete ticket
        if (currentTicketRows.length == 3) {
          finalizeCurrentTicket();
        }
      }
    }

    // Finalize any trailing ticket
    finalizeCurrentTicket();

    if (ticketGrids.isEmpty) {
      return const TambolaImportResult(
        success: false,
        tickets: [],
        message: 'Could not find valid Tambola ticket numbers in the file.',
        errors: [
          'No valid 3x9 grids or 15-number ticket rows found in the uploaded file.',
          'Please ensure the file contains numbers 1 to 90 arranged in 3 rows of 9 columns per ticket.',
        ],
      );
    }

    // Build the final list of tickets (SL 1 to 6)
    final List<TambolaTicketModel> resultTickets = [];
    int totalNumbers = 0;

    // Determine target tickets count (at least 6 or max SL found)
    final maxSl = ticketGrids.keys.fold(6, (prev, curr) => curr > prev ? curr : prev);
    final count = maxSl > 12 ? 12 : (maxSl < 6 ? 6 : maxSl);

    for (int sl = 1; sl <= count; sl++) {
      final grid = ticketGrids[sl] ?? List.generate(3, (_) => List<int?>.filled(9, null));

      // Validate ticket numbers
      final usedNumbers = <int>{};
      int ticketNumCount = 0;

      for (int r = 0; r < 3; r++) {
        int rowCount = 0;
        for (int c = 0; c < 9; c++) {
          final val = grid[r][c];
          if (val != null) {
            if (usedNumbers.contains(val)) {
              warnings.add('SL $sl: Duplicate number $val was removed from row ${r + 1}.');
              grid[r][c] = null;
            } else {
              usedNumbers.add(val);
              ticketNumCount++;
              rowCount++;
            }
          }
        }
        if (rowCount > 5) {
          warnings.add('SL $sl, Row ${r + 1} has $rowCount numbers (max is 5).');
        }
      }

      totalNumbers += ticketNumCount;

      // Check if existing ticket matches to preserve serial number / unique code
      TambolaTicketModel? existing;
      if (existingTickets != null && (sl - 1) < existingTickets.length) {
        existing = existingTickets[sl - 1];
      }

      final base = existing ?? TambolaTicketModel.empty(ticketId, sl);
      resultTickets.add(base.copyWith(
        slNo: sl,
        ticketData: grid,
      ));
    }

    return TambolaImportResult(
      success: true,
      tickets: resultTickets,
      message: 'Successfully imported ${ticketGrids.length} Tambola ticket(s) with $totalNumbers numbers total!',
      warnings: warnings,
      errors: errors,
      totalNumbersCount: totalNumbers,
    );
  }

  /// Helper to convert a list of up to 15 numbers into a compliant 3x9 grid
  static List<List<int?>> _buildGridFrom15Numbers(List<int> numbers) {
    final List<List<int?>> grid = List.generate(3, (_) => List<int?>.filled(9, null));
    final sorted = List<int>.from(numbers.toSet())..sort();

    // Group by column (decade)
    final Map<int, List<int>> byColumn = {};
    for (int c = 0; c < 9; c++) {
      byColumn[c] = [];
    }
    for (final num in sorted) {
      final col = getColumnForNumber(num);
      if (col >= 0 && col < 9) {
        byColumn[col]!.add(num);
      }
    }

    // Distribute into 3 rows
    for (int col = 0; col < 9; col++) {
      final colNums = byColumn[col]!;
      for (int i = 0; i < colNums.length && i < 3; i++) {
        grid[i][col] = colNums[i];
      }
    }

    return grid;
  }

  /// Generate a ready-to-use sample Excel workbook with 6 formatted Tambola tickets
  static Uint8List generateSampleExcel({String ticketId = 'GAGA26000001'}) {
    final excel = Excel.createExcel();
    // Default sheet is 'Sheet1'
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'Tambola Tickets');
    final sheet = excel['Tambola Tickets'];

    // Title Row
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('GAGA HOUSIE - TAMBOLA TICKETS IMPORT TEMPLATE');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value =
        TextCellValue('Draw Ticket ID: $ticketId • Standard 6-Ticket Sheet (3 rows x 9 cols per ticket)');

    int currentRow = 3;

    // Generate 6 sample tickets with standard Tambola layout
    for (int sl = 1; sl <= 6; sl++) {
      final setName = sl <= 3 ? 'Set 1' : 'Set 2';

      // SL Header
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow)).value =
          TextCellValue('SL $sl ($setName)');
      currentRow++;

      // Column Headers
      final colHeaders = [
        'Col 1 (1-9)',
        'Col 2 (10-19)',
        'Col 3 (20-29)',
        'Col 4 (30-39)',
        'Col 5 (40-49)',
        'Col 6 (50-59)',
        'Col 7 (60-69)',
        'Col 8 (70-79)',
        'Col 9 (80-90)'
      ];
      for (int c = 0; c < 9; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow)).value =
            TextCellValue(colHeaders[c]);
      }
      currentRow++;

      // 3 Rows of Tambola Grid
      final sampleGrid = TambolaTicketModel.generateRandomGrid();
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 9; c++) {
          final val = sampleGrid[r][c];
          final cellIndex = CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow);
          if (val != null) {
            sheet.cell(cellIndex).value = IntCellValue(val);
          } else {
            // Empty cell
            sheet.cell(cellIndex).value = TextCellValue('');
          }
        }
        currentRow++;
      }

      // Empty separator row between tickets
      currentRow++;
    }

    // Add Instructions Sheet
    final instrSheet = excel['Instructions'];
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('HOW TO FILL THIS EXCEL FILE:');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('1. Each Tambola ticket consists of 3 rows and 9 columns.');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('2. Each row must have exactly 5 numbers and 4 blank cells.');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value =
        TextCellValue('3. Total numbers per ticket should be exactly 15.');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value =
        TextCellValue('4. Column 1: numbers 1 to 9');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6)).value =
        TextCellValue('5. Column 2: numbers 10 to 19');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7)).value =
        TextCellValue('6. Column 3: numbers 20 to 29 (and so on up to Column 9: 80 to 90)');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8)).value =
        TextCellValue('7. Leave empty slots blank (or clear cell).');
    instrSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9)).value =
        TextCellValue('8. You can also import CSV files in the same layout.');

    return Uint8List.fromList(excel.save()!);
  }

  /// Export or save sample Excel file to device storage
  static Future<String?> exportSampleExcel({String ticketId = 'GAGA26000001'}) async {
    try {
      final bytes = generateSampleExcel(ticketId: ticketId);

      // Determine directory
      Directory? dir;
      try {
        dir = await getDownloadsDirectory();
      } catch (_) {}
      dir ??= await getApplicationDocumentsDirectory();

      final fileName = 'GaGa_Tambola_Template_${ticketId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('❌ [EXCEL EXPORT ERROR] $e');
      return null;
    }
  }
}
