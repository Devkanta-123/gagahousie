import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaga_housie/screens/home_tab.dart';
import 'package:gaga_housie/utils/constants.dart';

void main() {
  Widget createTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: HomeTab(),
      ),
    );
  }

  group('HomeTab Responsiveness and Ticket Slider Tests', () {
    testWidgets('renders properly on narrow screen (320x640) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tickets'), findsOneWidget);
      expect(find.text('Recent Winners'), findsOneWidget);

      final upcomingSlider = find.byType(PageView).first;
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );
    });

    testWidgets('renders 2 tickets per slide on standard screen (390x844)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('GaGa'), findsOneWidget);
      expect(find.text('Upcoming Tickets'), findsOneWidget);

      final upcomingSlider = find.byType(PageView).first;
      // Verify that both Ticket 1 and Ticket 2 are displayed simultaneously on the first slide
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );

      // Verify BUY NOW buttons exist for both visible tickets
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('BUY NOW')),
        findsNWidgets(2),
      );
    });

    testWidgets('slides sideways to show Ticket 3 and Ticket 4 on next slide',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final upcomingSlider = find.byType(PageView).first;
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );

      // Tap the right chevron for upcoming tickets slider
      final rightChevron = find.byIcon(Icons.chevron_right_rounded).first;
      await tester.tap(rightChevron);
      await tester.pumpAndSettle();

      // Now Ticket 3 and Ticket 4 should be visible
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 4')),
        findsOneWidget,
      );

      // Tap the left chevron to go back
      final leftChevron = find.byIcon(Icons.chevron_left_rounded).first;
      await tester.tap(leftChevron);
      await tester.pumpAndSettle();

      // Now Ticket 1 and Ticket 2 should be visible again
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on tablet screen (768x1024)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tickets'), findsOneWidget);
      final upcomingSlider = find.byType(PageView).first;
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );
    });
  });
}
