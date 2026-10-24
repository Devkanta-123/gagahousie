import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:gaga_housie/models/ticket_model.dart';
import 'package:gaga_housie/models/tambola_ticket_model.dart';
import 'package:gaga_housie/providers/ticket_provider.dart';
import 'package:gaga_housie/screens/admin_tambola_configurator_page.dart';
import 'package:gaga_housie/services/tambola_excel_service.dart';

void main() {
  test('generate and parse sample Excel', () {
    final sampleBytes = TambolaExcelService.generateSampleExcel(ticketId: 'TEST001');
    expect(sampleBytes, isNotEmpty);

    final result = TambolaExcelService.instance.parseBytes(
      sampleBytes,
      'sample_tickets.xlsx',
      'TEST001',
    );

    expect(result.success, isTrue);
    expect(result.tickets.length, 6);
    expect(result.totalNumbersCount, 90);

    for (int i = 0; i < 6; i++) {
      final ticket = result.tickets[i];
      expect(ticket.slNo, i + 1);
      expect(ticket.filledNumbersCount, 15);
      for (final row in ticket.ticketData) {
        expect(row.where((c) => c != null).length, 5);
      }
    }
  });

  test('parse CSV format', () {
    final csvContent = '''
SL 1
4,,25,,41,,62,,85
,12,,33,,55,68,74,
7,,29,,48,,,79,90

SL 2
2,,21,,43,,65,,82
,15,,36,,58,69,71,
9,,28,,49,,,77,88
''';

    final bytes = utf8.encode(csvContent);
    final result = TambolaExcelService.instance.parseBytes(
      bytes,
      'tickets.csv',
      'TEST002',
    );

    expect(result.success, isTrue);
    expect(result.tickets.length >= 2, isTrue);
    expect(result.tickets[0].filledNumbersCount, 15);
    expect(result.tickets[1].filledNumbersCount, 15);
  });

  test('parse single row 15 numbers format', () {
    final csvContent = '''
SL 1
4,7,12,25,29,33,41,48,55,62,74,79,85,90,1
''';

    final bytes = utf8.encode(csvContent);
    final result = TambolaExcelService.instance.parseBytes(
      bytes,
      'single_row.csv',
      'TEST003',
    );

    expect(result.success, isTrue);
    expect(result.tickets.isNotEmpty, isTrue);
    expect(result.tickets[0].filledNumbersCount, 15);
  });

  test('parse Excel with multiple sheets', () {
    final excel = Excel.createExcel();
    final sheet1 = excel['Ticket 1'];
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('SL 1');
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1)).value = IntCellValue(5);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 1)).value = IntCellValue(15);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 1)).value = IntCellValue(25);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 1)).value = IntCellValue(35);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 1)).value = IntCellValue(45);

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 2)).value = IntCellValue(46);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: 2)).value = IntCellValue(55);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: 2)).value = IntCellValue(65);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 2)).value = IntCellValue(75);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 2)).value = IntCellValue(85);

    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value = IntCellValue(8);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value = IntCellValue(18);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 3)).value = IntCellValue(28);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 3)).value = IntCellValue(38);
    sheet1.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: 3)).value = IntCellValue(88);

    final bytes = Uint8List.fromList(excel.save()!);
    final result = TambolaExcelService.instance.parseBytes(
      bytes,
      'multi_sheet.xlsx',
      'TEST004',
    );

    expect(result.success, isTrue);
    expect(result.tickets[0].filledNumbersCount, 15);
  });

  testWidgets('AdminTambolaConfiguratorPage renders Excel upload card, action buttons, and template dialog', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    final mockTicket = TicketModel(
      ticketId: 'GAGA26000001',
      ticketTitle: 'Mega Housie Draw',
      drawDate: '25/09/2026',
      drawTime: '07:00 PM',
      price: '₹20',
      totalPrize: '₹75000',
      prizes: [
        PrizeItem(name: 'Housefull', price: '₹50000'),
      ],
      status: 'Active',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<TicketProvider>(
        create: (_) => TicketProvider(),
        child: MaterialApp(
          home: AdminTambolaConfiguratorPage(ticket: mockTicket),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Excel Upload card is present
    expect(find.text('Bulk Import Tambola Tickets from Excel'), findsOneWidget);
    expect(find.text('Upload Excel Sheet'), findsOneWidget);
    expect(find.text('Upload Excel'), findsOneWidget); // Quick action button
    expect(find.text('Template'), findsWidgets);

    // Tap Template button to open template guide
    await tester.tap(find.text('Template').first);
    await tester.pumpAndSettle();

    // Verify Template Guide modal is shown
    expect(find.text('Excel Format & Template Guide'), findsOneWidget);
    expect(find.text('Download Sample Excel (.xlsx)'), findsOneWidget);

    // Close modal
    await tester.tap(find.text('Download Sample Excel (.xlsx)'));
    await tester.pumpAndSettle();
  });

  testWidgets('Filled cell tap opens cell action modal allowing review and edit', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(800, 1600);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    final mockTicket = TicketModel(
      ticketId: 'GAGA26000002',
      ticketTitle: 'Gold Housie Draw',
      drawDate: '26/09/2026',
      drawTime: '08:00 PM',
      price: '₹25',
      totalPrize: '₹95000',
      prizes: [],
      status: 'Active',
    );

    final provider = TicketProvider();
    // Cache a pre-filled ticket so cell is populated
    final sampleTickets = List.generate(
      6,
      (i) => TambolaTicketModel(
        ticketId: 'GAGA26000002',
        slNo: i + 1,
        serialNumber: 'SN: GAGA-0${i + 1}',
        uniqueCode: 'CODE: GH-SL${i + 1}',
        ticketData: [
          [5, null, 25, null, 45, null, 65, null, 85],
          [null, 15, null, 35, null, 55, 67, 75, null],
          [8, null, 28, null, 48, null, 68, null, 88],
        ],
      ),
    );
    provider.setCachedTambolaTickets('GAGA26000002', sampleTickets);

    await tester.pumpWidget(
      ChangeNotifierProvider<TicketProvider>.value(
        value: provider,
        child: MaterialApp(
          home: AdminTambolaConfiguratorPage(ticket: mockTicket),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify cell with '5' is rendered
    expect(find.text('5'), findsWidgets);

    // Tap the filled cell with number 5
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();

    // Verify Edit Cell modal appears with column decade and Clear Cell button
    expect(find.text('Edit Cell: Row 1, Col 1'), findsOneWidget);
    expect(find.text('Column Decade: 1 to 9'), findsOneWidget);
    expect(find.text('Clear Cell'), findsOneWidget);
    expect(find.text('Filter Tray to Col'), findsOneWidget);

    // Tap Clear Cell
    await tester.tap(find.text('Clear Cell'));
    await tester.pumpAndSettle();

    // Verify cell count decreased
    expect(find.text('14 / 15 Numbers'), findsOneWidget);
  });
}
