import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gaga_housie/screens/home_screen.dart';
import 'package:gaga_housie/screens/home_tab.dart';
import 'package:gaga_housie/screens/tickets_tab.dart';
import 'package:gaga_housie/screens/results_tab.dart';
import 'package:gaga_housie/screens/profile_tab.dart';
import 'package:gaga_housie/screens/my_tickets.dart';
import 'package:gaga_housie/screens/wallet_page.dart';
import 'package:gaga_housie/screens/draw_page.dart';
import 'package:gaga_housie/screens/login_screen.dart';
import 'package:gaga_housie/screens/register_screen.dart';
import 'package:gaga_housie/screens/otp_screen.dart';
import 'package:gaga_housie/screens/splash_screen.dart';
import 'package:gaga_housie/screens/ticket_details.dart';
import 'package:gaga_housie/screens/ticket_purchase_page.dart';
import 'package:gaga_housie/screens/qr_scanner_page.dart';
import 'package:gaga_housie/screens/admin_tickets_tab.dart';
import 'package:gaga_housie/screens/admin_tambola_configurator_page.dart';
import 'package:gaga_housie/models/tambola_ticket_model.dart';
import 'package:gaga_housie/models/ticket_model.dart';
import 'package:gaga_housie/providers/auth_provider.dart';
import 'package:gaga_housie/providers/ticket_provider.dart';
import 'package:gaga_housie/widgets/gaga_app_header.dart';
import 'package:gaga_housie/widgets/gaga_header.dart';
import 'package:gaga_housie/utils/constants.dart';

void main() {
  Widget createWithAuth(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('HomeTab Responsiveness and Ticket Slider Tests', () {
    testWidgets('renders properly on narrow screen (320x640) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: HomeTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tickets'), findsOneWidget);
      expect(find.text('Recent Winners'), findsOneWidget);
      expect(find.text('Recharge'), findsOneWidget);

      final upcomingSlider = find.byType(PageView).first;
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
    });

    testWidgets('HomeTab renders professional straight emerald gradient header with search, notification, and borderless balance card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: HomeTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byType(GaGaAppHeader);
      expect(headerFinder, findsOneWidget);

      // Search section in header
      expect(find.descendant(of: headerFinder, matching: find.byIcon(Icons.search_rounded)), findsOneWidget);
      expect(find.descendant(of: headerFinder, matching: find.text('Search draws, tickets, games...')), findsOneWidget);

      // Notification bell in header
      expect(find.descendant(of: headerFinder, matching: find.byIcon(Icons.notifications_outlined)), findsOneWidget);

      // Brand emblem icon
      expect(find.descendant(of: headerFinder, matching: find.byIcon(Icons.confirmation_number_rounded)), findsWidgets);

      // Integrated borderless Balance Card
      expect(find.descendant(of: headerFinder, matching: find.text(AppStrings.balance)), findsOneWidget);
      expect(find.descendant(of: headerFinder, matching: find.text('₹1000.00')), findsOneWidget);
      expect(find.descendant(of: headerFinder, matching: find.text('Recharge')), findsOneWidget);
      expect(find.descendant(of: headerFinder, matching: find.byIcon(Icons.account_balance_wallet)), findsOneWidget);
    });

    testWidgets('renders 1 full ticket card with circular peek (last ticket on left) and chevron navigation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: HomeTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tickets'), findsOneWidget);

      final upcomingSlider = find.byType(PageView).first;
      // Ticket 1 is the main active ticket
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
      // To the left, Ticket 4 (last ticket) is partially visible
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 4')),
        findsOneWidget,
      );
      // To the right, Ticket 2 is partially visible
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );

      // Verify BUY NOW button exists
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('BUY NOW')),
        findsWidgets,
      );

      // Tap right chevron to navigate to Ticket 2
      final rightChevron = find.byIcon(Icons.chevron_right_rounded).first;
      await tester.tap(rightChevron);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 2')),
        findsOneWidget,
      );

      // Tap left chevron to go back to Ticket 1
      final leftChevron = find.byIcon(Icons.chevron_left_rounded).first;
      await tester.tap(leftChevron);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );

      // Tap left chevron again to navigate to Ticket 4 (last ticket)
      await tester.tap(leftChevron);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 4')),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on tablet screen (768x1024)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.background,
            body: HomeTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tickets'), findsOneWidget);
      final upcomingSlider = find.byType(PageView).first;
      expect(
        find.descendant(of: upcomingSlider, matching: find.text('Ticket 1')),
        findsOneWidget,
      );
    });
  });

  group('SplashScreen Branding & Developer Attribution Tests', () {
    testWidgets('displays GaGa brand, developer credit, and version in white on green',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWithAuth(const SplashScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      final gagaText = tester.widget<Text>(find.text('GaGa'));
      expect(gagaText.style?.color, Colors.white);

      final badgeText = tester.widget<Text>(find.text('HOUSIE TAMBOLA'));
      expect(badgeText.style?.color, Colors.white);

      final devText = tester.widget<Text>(find.text('Developed By Devkanta Singh'));
      expect(devText.style?.color, Colors.white);

      final verText = tester.widget<Text>(find.text('Version 1.0.0'));
      expect(verText.style?.color, Colors.white);
    });
  });

  group('ProfileTab About & Developer Section Tests', () {
    testWidgets('displays About GaGa Housie card with developer credit and version',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createWithAuth(
          const Scaffold(
            backgroundColor: AppColors.background,
            body: ProfileTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About GaGa Housie'), findsOneWidget);
      expect(find.text('Devkanta Singh'), findsWidgets);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('My Account & Preferences'), findsOneWidget);
    });
  });

  group('GaGaAppHeader Global Component Tests', () {
    testWidgets('renders search section, notification bell, optional subtitle, and back button',
        (WidgetTester tester) async {
      bool backPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GaGaAppHeader(
              subtitle: 'Global Subtitle Test',
              showBackButton: true,
              onBackPressed: () => backPressed = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Global Subtitle Test'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backPressed, isTrue);
    });

    testWidgets('supports backward-compatibility alias GagaHeader',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GagaHeader(
              subtitle: 'Alias Test',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Alias Test'), findsOneWidget);
    });

    testWidgets('renders integrated borderless Balance section when showBalance is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GaGaAppHeader(
              showBalance: true,
              balance: 2500.50,
              showRechargeButton: true,
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.balance), findsOneWidget);
      expect(find.text('₹2500.50'), findsOneWidget);
      expect(find.text('Recharge'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('tapping notification bell opens game alerts bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GaGaAppHeader(
              subtitle: 'Alerts Test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bell = find.byIcon(Icons.notifications_outlined);
      expect(bell, findsOneWidget);

      await tester.tap(bell);
      await tester.pumpAndSettle();

      expect(find.text('Notifications & Alerts'), findsOneWidget);
      expect(find.text('Live Tambola Draw Starting'), findsOneWidget);
    });
  });

  group('Multi-screen GaGaAppHeader Integration Tests', () {
    testWidgets('TicketsTab renders GaGaAppHeader with search and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TicketsTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Available Draws & Tickets'), findsOneWidget);
    });

    testWidgets('ResultsTab renders GaGaAppHeader with search and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultsTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('Draw Results & Recent Winners'), findsOneWidget);
    });

    testWidgets('MyTicketsPage renders GaGaAppHeader with back button and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyTicketsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('My Purchased Tickets'), findsOneWidget);
    });

    testWidgets('WalletPage renders compact QR section, header balance, and opens proof modal',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WalletPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Header with integrated balance
      expect(find.text('Wallet & Top Up'), findsOneWidget);
      expect(find.text('₹1000.00'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // Compact QR Section
      expect(find.text('Scan to Recharge'), findsOneWidget);
      expect(find.textContaining('UPI ID: gagahousie@upi'), findsOneWidget);

      // Action button to open modal
      final proofButton = find.text('I Have Paid / Upload Payment Proof');
      expect(proofButton, findsOneWidget);

      // Tap proof button to open bottom modal sheet
      await tester.tap(proofButton);
      await tester.pumpAndSettle();

      expect(find.text('Payment Verification'), findsOneWidget);
      expect(find.text('Upload Payment Screenshot'), findsOneWidget);
      expect(find.text('IFSC Code'), findsOneWidget);
      expect(find.text('Bank Account Number'), findsOneWidget);
      expect(find.text('Submit Verification'), findsOneWidget);
    });

    testWidgets('DrawPage renders GaGaAppHeader with back button and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DrawPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('Live Tambola Draw'), findsOneWidget);
    });

    testWidgets('LoginScreen renders professional wavy header with GaGa brand, welcome, and demo info',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('GaGa'), findsOneWidget);
      expect(find.text('HOUSIE TAMBOLA'), findsOneWidget);
      expect(find.text('Welcome Back • Sign In to Continue'), findsOneWidget);
      expect(find.text('Email Address or 10-Digit Mobile'), findsOneWidget);
      expect(find.byType(ClipPath), findsWidgets);
      expect(find.text('Recharge'), findsNothing);
    });

    testWidgets('RegisterScreen renders professional wavy header with back button and brand info',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('GaGa'), findsOneWidget);
      expect(find.text('HOUSIE TAMBOLA'), findsOneWidget);
      expect(find.text('Create Account • Join the Platform'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byType(ClipPath), findsWidgets);
      expect(find.text('Recharge'), findsNothing);
    });

    testWidgets('OTPScreen renders professional wavy header with back button and brand info',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const OTPScreen()));
      await tester.pumpAndSettle();

      expect(find.text('GaGa'), findsOneWidget);
      expect(find.text('HOUSIE TAMBOLA'), findsOneWidget);
      expect(find.text('Verification • Enter OTP'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byType(ClipPath), findsWidgets);
    });
  });

  group('HomeScreen Water Grid Toggle Bar Tests', () {
    testWidgets('HomeScreen has 4 tabs without Alerts and displays HomeTab initially',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Alerts'), findsNothing);
      expect(find.text('Upcoming Tickets'), findsOneWidget);
    });

    testWidgets('HomeScreen switches to TicketsTab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tickets'));
      await tester.pumpAndSettle();
      expect(find.text('Available Draws & Tickets'), findsOneWidget);
    });

    testWidgets('HomeScreen switches to ResultsTab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Results'));
      await tester.pumpAndSettle();
      expect(find.text('Draw Results & Recent Winners'), findsOneWidget);
    });

    testWidgets('HomeScreen switches to AccountTab',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWithAuth(const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('My Account & Preferences'), findsOneWidget);
    });
  });

  group('New Feature Verification Tests', () {
    testWidgets('GaGaAppHeader search panel is interactive and searchable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GaGaAppHeader(
              subtitle: 'Search Test',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'Ticket');
      await tester.pumpAndSettle();

      expect(find.text('Ticket'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Ticket'), findsNothing);
    });

    testWidgets('ResultsTab uses green for trophy icons without yellow',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultsTab(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final trophyIcons = tester.widgetList<Icon>(find.byIcon(Icons.emoji_events_rounded));
      expect(trophyIcons.isNotEmpty, isTrue);
      for (final icon in trophyIcons) {
        expect(icon.color, AppColors.primaryGreen);
      }
    });

    testWidgets('WalletPage displays green text on white card containers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WalletPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Scan to recharge heading in primary green
      final scanText = tester.widget<Text>(find.text('Scan to Recharge'));
      expect(scanText.style?.color, AppColors.primaryGreen);

      // Guide heading in primary green
      final guideText = tester.widget<Text>(find.text('How To Recharge'));
      expect(guideText.style?.color, AppColors.primaryGreen);

      // Recent transactions heading in primary green
      final txText = tester.widget<Text>(find.text('Recent Transactions'));
      expect(txText.style?.color, AppColors.primaryGreen);

      // UPI ID in primary green
      final upiText = tester.widget<Text>(find.text('UPI ID: gagahousie@upi'));
      expect(upiText.style?.color, AppColors.primaryGreen);
    });

    testWidgets('TicketDetailsPage renders consistent full-width GaGaAppHeader with back button and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TicketDetailsPage(
            ticketNumber: '01. 02. 03.',
            date: '12/05/2024',
            time: '01:30 PM',
            price: '100',
            ticketId: 'TKT001',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GaGaAppHeader), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text('01. 02. 03. • Ticket Details'), findsOneWidget);
      expect(find.text('Your Ticket'), findsOneWidget);
    });

    testWidgets('Notification modal displays frosted white glass styling with 4 New badge and emerald icons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GaGaAppHeader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the notification bell icon
      final bellIcon = find.byIcon(Icons.notifications_outlined);
      expect(bellIcon, findsOneWidget);
      await tester.tap(bellIcon);
      await tester.pumpAndSettle();

      expect(find.text('Notifications & Alerts'), findsOneWidget);
      expect(find.text('4 New'), findsOneWidget);
      expect(find.text('Housefull Winner #1234!'), findsOneWidget);
      expect(find.text('Live Tambola Draw Starting'), findsOneWidget);
      expect(find.text('Wallet Recharged'), findsOneWidget);
    });

    testWidgets('MyTicketsPage renders list of green cards with status badges and consistent header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyTicketsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GaGaAppHeader), findsOneWidget);
      expect(find.text('My Purchased Tickets'), findsOneWidget);
      expect(find.text('Purchased Tickets'), findsOneWidget);
      expect(find.text('4 Active'), findsOneWidget);
      expect(find.text('Ticket #TKT001'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
      expect(find.text('Active'), findsNWidgets(2));
      expect(find.text('Booked'), findsNWidgets(2));
    });

    testWidgets('TicketPurchasePage displays professional celebratory confirmation modal with verified receipt and actions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TicketPurchasePage(
            ticket: {
              'ticket': 'Ticket #001',
              'date': '25/09/2024',
              'price': '₹20',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GaGaAppHeader), findsOneWidget);
      expect(find.text('Purchase Ticket • Confirm Order'), findsOneWidget);

      // Find and tap the Confirm Purchase button
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirm Purchase (₹20.00)');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Check professional celebratory modal elements
      expect(find.text('Purchase Confirmed!'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('View My Tickets'), findsOneWidget);
      expect(find.text('Done • Back to Draws'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('MyTicketsPage renders properly on narrow screen (320x640) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: MyTicketsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ticket #TKT001'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
      expect(find.text('Purchased Tickets'), findsOneWidget);
    });

    testWidgets('TicketPurchasePage integrates balance card in header and streamlines single ticket purchase without quantity selector',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TicketPurchasePage(
            ticket: {
              'ticket': 'Ticket #001',
              'date': '25/09/2024',
              'price': '₹20',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header should have integrated balance card with ₹1000.00 and Recharge
      expect(find.text('Recharge'), findsOneWidget);
      expect(find.text('₹1000.00'), findsWidgets);

      // Hero Card elements
      expect(find.text('Live Tambola Housie Draw'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('Ticket Price'), findsWidgets);

      // Quantity selector should be removed
      expect(find.text('Ticket Quantity'), findsNothing);
      expect(find.text('Number of tickets to book'), findsNothing);

      // Order summary and payment method elements
      expect(find.text('Payment Breakdown'), findsOneWidget);
      expect(find.text('Total Payable'), findsOneWidget);
      expect(find.text('₹20.00'), findsWidgets);
      expect(find.text('GaGa Wallet (₹1000.00)'), findsOneWidget);

      // Branded confirm purchase button for single ticket
      expect(find.widgetWithText(ElevatedButton, 'Confirm Purchase (₹20.00)'), findsOneWidget);
    });

    testWidgets('QRScannerPage renders perfectly fitted QR image inside border container',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QRScannerPage(
            selectedTickets: ['TKT001'],
            totalAmount: 20.0,
            ticketId: 'GH-987654',
          ),
        ),
      );
      await tester.pump();

      // Verify header and page content
      expect(find.byType(GaGaAppHeader), findsOneWidget);
      expect(find.text('Scan QR Code • Payment'), findsOneWidget);
      expect(find.text('Time Remaining'), findsOneWidget);

      // Verify QR Image and border container
      expect(find.byType(ClipRRect), findsWidgets);
      expect(find.byType(Image), findsOneWidget);

      // Verify payment info
      expect(find.text('Ticket ID:'), findsOneWidget);
      expect(find.text('GH-987654'), findsOneWidget);
      expect(find.text('₹20.00'), findsOneWidget);
    });
  });

  group('AdminTicketsTab Ticket ID Search Filter Tests', () {
    Widget createAdminTicketsApp({List<TicketModel>? customTickets}) {
      final ticketProvider = TicketProvider();
      ticketProvider.setTickets(customTickets ?? [
        TicketModel(
          ticketId: 'GAGA26000001',
          ticketTitle: 'Morning Draw #1',
          drawDate: '25/09/2026',
          drawTime: '10:00 AM',
          price: '₹20',
          totalPrize: '₹75000',
          status: 'Active',
          prizes: TicketModel.defaultPrizes(),
        ),
        TicketModel(
          ticketId: 'GAGA26000002',
          ticketTitle: 'Evening Draw #2',
          drawDate: '25/09/2026',
          drawTime: '08:00 PM',
          price: '₹50',
          totalPrize: '₹150000',
          status: 'Active',
          prizes: TicketModel.defaultPrizes(),
        ),
        TicketModel(
          ticketId: 'TKT-99999',
          ticketTitle: 'Midnight Bumper',
          drawDate: '26/09/2026',
          drawTime: '11:59 PM',
          price: '₹100',
          totalPrize: '₹300000',
          status: 'Active',
          prizes: TicketModel.defaultPrizes(),
        ),
      ]);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider.value(value: ticketProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminTicketsTab(),
          ),
        ),
      );
    }

    testWidgets('renders Ticket ID search filter bar with badge and placeholder',
        (WidgetTester tester) async {
      await tester.pumpWidget(createAdminTicketsApp());
      await tester.pumpAndSettle();

      expect(find.text('Published Draw Tickets'), findsOneWidget);
      expect(find.text('TICKET ID'), findsOneWidget);
      expect(find.text('Search by Ticket ID (e.g. GAGA26000001)...'), findsOneWidget);
      expect(find.text('3 in DB • Page 1 of 1'), findsOneWidget);
    });

    testWidgets('filters tickets by ticket ID in real time and highlights matched ticket',
        (WidgetTester tester) async {
      await tester.pumpWidget(createAdminTicketsApp());
      await tester.pumpAndSettle();

      expect(find.text('GAGA26000001'), findsOneWidget);
      expect(find.text('GAGA26000002'), findsOneWidget);
      expect(find.text('TKT-99999'), findsOneWidget);

      final searchInput = find.widgetWithText(TextField, 'Search by Ticket ID (e.g. GAGA26000001)...');
      await tester.enterText(searchInput, '000002');
      await tester.pumpAndSettle();

      // Only GAGA26000002 should remain
      expect(find.text('GAGA26000002'), findsOneWidget);
      expect(find.text('GAGA26000001'), findsNothing);
      expect(find.text('TKT-99999'), findsNothing);

      // Verify active filter indicators
      expect(find.text('1 found • Page 1 of 1'), findsOneWidget);
      expect(find.text('Filtering by Ticket ID: "000002"'), findsOneWidget);
      expect(find.text('(1 match)'), findsOneWidget);
      expect(find.text('Clear Filter'), findsOneWidget);
    });

    testWidgets('clearing search filter restores full list of tickets',
        (WidgetTester tester) async {
      await tester.pumpWidget(createAdminTicketsApp());
      await tester.pumpAndSettle();

      final searchInput = find.widgetWithText(TextField, 'Search by Ticket ID (e.g. GAGA26000001)...');
      await tester.enterText(searchInput, 'TKT-99999');
      await tester.pumpAndSettle();

      final listViewFinder = find.byType(ListView);
      expect(find.descendant(of: listViewFinder, matching: find.text('TKT-99999')), findsOneWidget);
      expect(find.descendant(of: listViewFinder, matching: find.text('GAGA26000001')), findsNothing);

      // Tap 'Clear Filter'
      await tester.tap(find.text('Clear Filter'));
      await tester.pumpAndSettle();

      // All tickets restored
      expect(find.descendant(of: listViewFinder, matching: find.text('GAGA26000001')), findsOneWidget);
      expect(find.descendant(of: listViewFinder, matching: find.text('GAGA26000002')), findsOneWidget);
      expect(find.descendant(of: listViewFinder, matching: find.text('TKT-99999')), findsOneWidget);
      expect(find.text('3 in DB • Page 1 of 1'), findsOneWidget);
    });

    testWidgets('displays dedicated empty state when no tickets match the searched Ticket ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(createAdminTicketsApp());
      await tester.pumpAndSettle();

      final searchInput = find.widgetWithText(TextField, 'Search by Ticket ID (e.g. GAGA26000001)...');
      await tester.enterText(searchInput, 'NON_EXISTENT_ID');
      await tester.pumpAndSettle();

      expect(find.text('No Matching Tickets Found'), findsOneWidget);
      expect(find.textContaining('No published ticket matches Ticket ID "NON_EXISTENT_ID"'), findsOneWidget);
      expect(find.text('Reset Search Filter'), findsOneWidget);

      // Tapping Reset Search Filter resets the search
      await tester.tap(find.text('Reset Search Filter'));
      await tester.pumpAndSettle();

      expect(find.text('No Matching Tickets Found'), findsNothing);
      expect(find.text('GAGA26000001'), findsOneWidget);
      expect(find.text('3 in DB • Page 1 of 1'), findsOneWidget);
    });
  });

  group('Tambola Ticket Model & Admin Configurator Tests', () {
    test('TambolaTicketModel.empty initializes valid empty 3x9 grid', () {
      final emptyTicket = TambolaTicketModel.empty('GAGA26000001', 1);

      expect(emptyTicket.ticketId, 'GAGA26000001');
      expect(emptyTicket.slNo, 1);
      expect(emptyTicket.ticketData.length, 3);
      for (final row in emptyTicket.ticketData) {
        expect(row.length, 9);
        expect(row.every((cell) => cell == null), isTrue);
      }
      expect(emptyTicket.filledNumbersCount, 0);
      expect(emptyTicket.isComplete, isFalse);
    });

    test('TambolaTicketModel.generateRandom produces valid 15-number 3x9 grid with 5 numbers per row', () {
      final randomTicket = TambolaTicketModel.generateRandom('GAGA26000001', 2);

      expect(randomTicket.ticketData.length, 3);
      for (final row in randomTicket.ticketData) {
        expect(row.length, 9);
        final filledInRow = row.where((c) => c != null).length;
        expect(filledInRow, 5);
      }
      expect(randomTicket.filledNumbersCount, 15);
      expect(randomTicket.isComplete, isTrue);

      // Verify numbers match column decade bounds
      for (int col = 0; col < 9; col++) {
        final minVal = col == 0 ? 1 : col * 10;
        final maxVal = col == 8 ? 90 : (col * 10) + 9;
        for (int row = 0; row < 3; row++) {
          final cell = randomTicket.ticketData[row][col];
          if (cell != null) {
            expect(cell >= minVal && cell <= maxVal, isTrue);
          }
        }
      }
    });

    test('TambolaTicketModel json serialization roundtrip and toSelectionMap', () {
      final generated = TambolaTicketModel.generateRandom('GAGA26000001', 3);

      final json = generated.toJson();
      expect(json['ticket_id'], 'GAGA26000001');
      expect(json['sl_no'], 3);
      expect(json['serial_number'], generated.serialNumber);
      expect(json['unique_code'], generated.uniqueCode);

      final deserialized = TambolaTicketModel.fromJson(json);
      expect(deserialized.ticketId, generated.ticketId);
      expect(deserialized.slNo, generated.slNo);
      expect(deserialized.filledNumbersCount, 15);

      final selectionMap = deserialized.toSelectionMap();
      expect(selectionMap['slNo'], 3);
      expect(selectionMap['serialNumber'], generated.serialNumber);
      expect(selectionMap['uniqueCode'], generated.uniqueCode);
      expect(selectionMap['ticketData'], isNotNull);
      expect(selectionMap['selected'], false);
    });

    testWidgets('AdminTambolaConfiguratorPage renders ticket details, SL pills, 3x9 grid, and actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testTicket = TicketModel(
        ticketId: 'GAGA26000001',
        ticketTitle: 'GaGa Housie Draw',
        drawDate: '25/09/2026',
        drawTime: '07:00 PM',
        price: '₹20',
        totalPrize: '₹75000',
        status: 'Active',
        prizes: [
          PrizeItem(name: 'Housefull', price: '₹40000'),
          PrizeItem(name: '1st Line', price: '₹10000'),
        ],
      );

      final ticketProvider = TicketProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TicketProvider>.value(value: ticketProvider),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            home: AdminTambolaConfiguratorPage(
              ticket: testTicket,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header & ticket info card
      expect(find.text('Tambola Setup'), findsOneWidget);
      expect(find.textContaining('GAGA26000001'), findsWidgets);

      // Verify SL pills 1 through 6
      expect(find.text('SL 1'), findsOneWidget);
      expect(find.text('SL 2'), findsOneWidget);
      expect(find.text('SL 3'), findsOneWidget);
      expect(find.text('SL 4'), findsOneWidget);
      expect(find.text('SL 5'), findsOneWidget);
      expect(find.text('SL 6'), findsOneWidget);

      // Verify empty initial state (0 / 15 Numbers)
      expect(find.text('0 / 15 Numbers'), findsOneWidget);

      // Verify Quick Action buttons
      expect(find.text('Auto-Fill SL'), findsOneWidget);
      expect(find.text('Fill All 6 SL'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Verify Number Bank Tray
      expect(find.text('Number Bank • Drag or Tap to Place'), findsOneWidget);
      expect(find.text('All (1-90)'), findsOneWidget);

      // Tap 'Auto-Fill SL' to fill SL 1
      await tester.tap(find.text('Auto-Fill SL'));
      await tester.pumpAndSettle();

      // SL 1 should now be 15 / 15 Numbers
      expect(find.text('15 / 15 Numbers'), findsOneWidget);

      // Tap 'Clear' to reset SL 1
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // SL 1 should now be back to 0 / 15 Numbers
      expect(find.text('0 / 15 Numbers'), findsOneWidget);

      // Tap 'Fill All 6 SL' to fill all 6 tickets at once
      await tester.tap(find.text('Fill All 6 SL'));
      await tester.pumpAndSettle();

      // SL 1 should be 15 / 15 and overall completion 6 of 6
      expect(find.text('15 / 15 Numbers'), findsOneWidget);
      expect(find.text('6 of 6 Complete'), findsOneWidget);
      expect(find.text('90/90 Total Numbers Set'), findsOneWidget);

      // Bottom Save button is present and enabled
      expect(find.text('Save Tambola Tickets'), findsOneWidget);
    });
  });

  group('DB Zero Records, Tambola Filtering & 15-Number Max Validation Tests', () {
    test('TicketProvider returns 0 records and no dummy data when DB is empty', () {
      final provider = TicketProvider();
      // Ensure tickets list is empty
      provider.setTickets([]);
      provider.setTicketIdsWithTambola({});

      expect(provider.tickets.length, 0);
      expect(provider.totalTicketsCount, 0);
      expect(provider.upcomingTicketsMap.length, 0);
      expect(provider.liveTicketsMap.length, 0);
      expect(provider.ticketsWithTambola.length, 0);
    });

    test('TicketProvider only exposes tickets that have tambola numbers configured', () {
      final provider = TicketProvider();
      final ticket1 = TicketModel(
        ticketId: 'GAGA26000001',
        ticketTitle: 'Draw 1 (With Tambola)',
        drawDate: '25/09/2026',
        drawTime: '07:00 PM',
        prizes: [PrizeItem(name: 'Housefull', price: '₹40000')],
      );
      final ticket2 = TicketModel(
        ticketId: 'GAGA26000002',
        ticketTitle: 'Draw 2 (No Tambola)',
        drawDate: '26/09/2026',
        drawTime: '08:00 PM',
        prizes: [PrizeItem(name: 'Housefull', price: '₹50000')],
      );

      provider.setTickets([ticket1, ticket2]);

      // Initially neither has tambola configured
      provider.setTicketIdsWithTambola({});
      expect(provider.upcomingTicketsMap.length, 0);
      expect(provider.liveTicketsMap.length, 0);

      // Configure tambola for ticket1 only
      provider.setCachedTambolaTickets(
        'GAGA26000001',
        [TambolaTicketModel.generateRandom('GAGA26000001', 1)],
      );

      expect(provider.hasTambolaTickets('GAGA26000001'), isTrue);
      expect(provider.hasTambolaTickets('GAGA26000002'), isFalse);

      // Only ticket1 should appear for users!
      expect(provider.upcomingTicketsMap.length, 1);
      expect(provider.upcomingTicketsMap.first['ticket'], 'Draw 1 (With Tambola)');
      expect(provider.liveTicketsMap.length, 1);
      expect(provider.liveTicketsMap.first['ticket'], 'Draw 1 (With Tambola)');
    });

    test('TambolaTicketModel enforces max 15 numbers limit', () {
      final emptyTicket = TambolaTicketModel.empty('GAGA26000001', 1);
      expect(emptyTicket.isValid, isTrue);
      expect(emptyTicket.hasExceededLimit, isFalse);

      final fullTicket = TambolaTicketModel.generateRandom('GAGA26000001', 1);
      expect(fullTicket.filledNumbersCount, 15);
      expect(fullTicket.isValid, isTrue);
      expect(fullTicket.isComplete, isTrue);
      expect(fullTicket.hasExceededLimit, isFalse);

      // 16 numbers grid (invalid)
      final grid16 = List.generate(3, (r) => List<int?>.from(fullTicket.ticketData[r]));
      // Find an empty cell to put a 16th number
      bool added = false;
      for (int r = 0; r < 3 && !added; r++) {
        for (int c = 0; c < 9 && !added; c++) {
          if (grid16[r][c] == null) {
            grid16[r][c] = 99;
            added = true;
          }
        }
      }
      final invalidTicket = fullTicket.copyWith(ticketData: grid16);
      expect(invalidTicket.filledNumbersCount, 16);
      expect(invalidTicket.isValid, isFalse);
      expect(invalidTicket.hasExceededLimit, isTrue);
    });

    testWidgets('HomeTab shows 0 Available and No Upcoming Tickets when DB is empty',
        (WidgetTester tester) async {
      final provider = TicketProvider();
      provider.setTickets([]);
      provider.setTicketIdsWithTambola({});

      await tester.pumpWidget(
        ChangeNotifierProvider<TicketProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: HomeTab(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Tickets'), findsOneWidget);
      expect(find.text('0 Available'), findsOneWidget);
      expect(find.text('No Upcoming Tickets'), findsOneWidget);
      // Verify no upcoming tickets are displayed
      expect(find.text('There are no active draws scheduled right now.'), findsOneWidget);
    });

    testWidgets('TicketsTab shows 0 Active and No Live Tickets Available when DB is empty',
        (WidgetTester tester) async {
      final provider = TicketProvider();
      provider.setTickets([]);
      provider.setTicketIdsWithTambola({});

      await tester.pumpWidget(
        ChangeNotifierProvider<TicketProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: TicketsTab(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Tickets'), findsOneWidget);
      expect(find.text('0 Active'), findsOneWidget);
      expect(find.text('No Live Tickets Available'), findsOneWidget);
      // Dummy tickets must NOT be displayed
      expect(find.text('Ticket #001'), findsNothing);
      expect(find.text('Ticket #002'), findsNothing);
    });

    testWidgets('AdminTambolaConfiguratorPage strictly prevents adding more than 15 numbers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testTicket = TicketModel(
        ticketId: 'GAGA26000001',
        ticketTitle: 'GaGa Housie Draw',
        drawDate: '25/09/2026',
        drawTime: '07:00 PM',
        prizes: [PrizeItem(name: 'Housefull', price: '₹40000')],
      );

      final ticketProvider = TicketProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<TicketProvider>.value(value: ticketProvider),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            home: AdminTambolaConfiguratorPage(
              ticket: testTicket,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Auto-fill SL 1 to reach 15/15
      await tester.tap(find.text('Auto-Fill SL'));
      await tester.pumpAndSettle();
      expect(find.text('15 / 15 Numbers'), findsOneWidget);

      // Find an unused number from the tray using ValueKey to attempt adding a 16th number
      for (int n = 1; n <= 90; n++) {
        final chipFinder = find.byKey(ValueKey('number_chip_$n'));
        if (chipFinder.evaluate().isNotEmpty) {
          await tester.ensureVisible(chipFinder);
          await tester.tap(chipFinder);
          await tester.pumpAndSettle();
          break;
        }
      }

      // SnackBar should warn about 15 max numbers
      expect(
        find.text('⚠️ Maximum 15 numbers allowed per Tambola ticket. Cannot add more.'),
        findsOneWidget,
      );

      // Ticket must still have exactly 15 numbers, never 16
      expect(find.text('15 / 15 Numbers'), findsOneWidget);
    });
  });
}
