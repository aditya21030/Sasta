import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sasta/data/sasta_app_state.dart';
import 'package:sasta/main.dart';
import 'package:sasta/models/models.dart';
import 'package:sasta/screens/basket/basket_screen.dart';
import 'package:sasta/screens/comparison/basket_compare_screen.dart';
import 'package:sasta/screens/help_legal/help_centre_screen.dart';
import 'package:sasta/screens/home/home_search_screen.dart';
import 'package:sasta/screens/profile/profile_screen.dart';
import 'package:sasta/screens/sasta_plus/plus_landing_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  SastaAppState onboardedState() {
    final state = SastaAppState();
    state.completeSplash();
    state.completeOnboarding();
    state.completePincode('110001', area: 'Central Delhi');
    return state;
  }

  Finder scrollableIn(Type parentType) {
    return find.descendant(
      of: find.byType(parentType),
      matching: find.byType(Scrollable),
    ).first;
  }

  Future<void> pumpRoute(WidgetTester tester, [int ms = 500]) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(Duration(milliseconds: ms));
  }

  Future<void> scrollSafeIntoView(
    WidgetTester tester,
    Finder target,
    Finder scrollable, {
    double delta = 200,
    double bottomMargin = 140,
  }) async {
    await tester.scrollUntilVisible(target, delta, scrollable: scrollable);
    final dy = tester.getCenter(target).dy;
    final viewHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    if (dy > viewHeight - bottomMargin) {
      await tester.drag(scrollable, const Offset(0, -110));
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  test(
    'Weekly Essentials comparison math matches Sasta spec (Zepto ₹266, Split ₹264)',
    () {
      final state = onboardedState();
      final comp = state.computeBasketComparison();
      expect(comp.cheapestCompleteStore?.retailer, RetailerId.zepto);
      expect(comp.cheapestCompleteStore?.totalPrice, 266);
      expect(comp.priciestCompleteStore?.retailer, RetailerId.blinkit);
      expect(comp.priciestCompleteStore?.totalPrice, 274);
      expect(comp.splitTotal, 264);
      expect(comp.savingsVsPriciest, 8);
    },
  );

  testWidgets(
    'Splash -> Onboarding -> Pincode -> Home full initial flow',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const SastaApp());
      expect(find.text('Search once. Compare everywhere.'), findsOneWidget);

      // Splash auto-advances after 1650ms
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 550));

      expect(find.text('Search once.\nCompare everywhere.'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Where should we\ndeliver?'), findsOneWidget);
      await tester.tap(find.text('110001 · Central Delhi'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 650));

      expect(find.text('What are we\nsaving on today?'), findsOneWidget);
      expect(find.text('Shop by category'), findsOneWidget);
    },
  );

  testWidgets(
    'Home -> Search -> Product Details variant switch -> Compare -> Price History',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = onboardedState();
      await tester.pumpWidget(SastaApp(stateOverride: state));
      await tester.pump(const Duration(milliseconds: 650));

      await tester.tap(find.text('Search groceries, brands, products…'));
      await pumpRoute(tester, 550);

      expect(find.byType(HomeSearchScreen), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await pumpRoute(tester, 550);

      expect(find.text('Amul Taaza Toned Milk'), findsWidgets);
      await tester.tap(find.text('Amul Taaza Toned Milk').first);
      await pumpRoute(tester, 550);

      expect(find.text('₹26'), findsWidgets);

      // Switch variant 500 ml -> 1 L
      await tester.tap(find.textContaining('1 L').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('₹52'), findsWidgets);

      // Open platform comparison
      await tester.tap(find.text('Compare'));
      await pumpRoute(tester, 550);
      expect(find.text('Compare prices'), findsOneWidget);
      expect(find.text('Swiggy Instamart'), findsWidgets);
      expect(find.text('Flipkart Minutes'), findsWidgets);

      // Open Price History from compare screen
      await tester.tap(find.text('View price history →').first);
      await pumpRoute(tester, 550);
      expect(find.text('7D'), findsOneWidget);
      expect(find.text('30D'), findsOneWidget);
    },
  );

  testWidgets(
    'Smart Basket single store vs split basket vs savings math & UI',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = onboardedState();
      await tester.pumpWidget(SastaApp(stateOverride: state));
      await tester.pump(const Duration(milliseconds: 650));

      await tester.tap(find.bySemanticsLabel('Basket'));
      await pumpRoute(tester, 450);

      expect(find.text('Weekly Essentials'), findsWidgets);
      expect(find.text('Compare basket'), findsOneWidget);

      await tester.tap(find.text('Compare basket'));
      await pumpRoute(tester, 550);

      expect(find.byType(BasketCompareScreen), findsOneWidget);
      expect(find.text('Single store'), findsOneWidget);
      expect(find.text('Split basket'), findsOneWidget);
      expect(find.text('₹266'), findsWidgets);

      await tester.tap(find.text('Split basket'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('₹264'), findsWidgets);

      await tester.tap(find.text('Savings'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('₹8'), findsWidgets);
    },
  );

  testWidgets(
    'Profile Appearance Dark Mode, Sasta+ Checkout, and Help Centre FAQs',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = onboardedState();
      await tester.pumpWidget(SastaApp(stateOverride: state));
      await tester.pump(const Duration(milliseconds: 650));

      // Navigate to Profile tab
      await tester.tap(find.bySemanticsLabel('Profile'));
      await pumpRoute(tester, 450);
      expect(find.text('Your name'), findsOneWidget);

      // Scroll Appearance comfortably above the floating BottomNav
      await scrollSafeIntoView(
        tester,
        find.text('Appearance'),
        scrollableIn(ProfileScreen),
      );

      await tester.tap(find.text('Appearance'));
      await pumpRoute(tester, 550);
      expect(find.text('Pick your look'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(state.themeMode, ThemeMode.dark);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await pumpRoute(tester, 450);

      // Scroll back up to Explore Sasta+ card
      await tester.scrollUntilVisible(
        find.text('Explore Sasta+'),
        -220,
        scrollable: scrollableIn(ProfileScreen),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Explore Sasta+'));
      await pumpRoute(tester, 550);
      expect(find.text('Save smarter, every week.'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Subscribe to Sasta+'),
        220,
        scrollable: scrollableIn(PlusLandingScreen),
      );
      await tester.tap(find.text('Subscribe to Sasta+'));
      await pumpRoute(tester, 550);
      expect(find.text('Pick a plan'), findsOneWidget);

      await tester.tap(find.text('Continue to checkout'));
      await pumpRoute(tester, 550);
      expect(find.text('Confirm & pay ₹399'), findsOneWidget);

      await tester.tap(find.text('Confirm & pay ₹399'));
      await pumpRoute(tester, 550);
      expect(find.text('You’re on Sasta+!'), findsOneWidget);
      expect(state.planType, SastaPlanType.yearly);
      expect(state.isPlusActive, isTrue);

      await tester.tap(find.text('Back to Home'));
      await pumpRoute(tester, 550);
      expect(state.activeTabIndex, 0);

      // Verify compact 360x640 viewport + Help Centre FAQs with zero overflow
      await tester.binding.setSurfaceSize(const Size(360, 640));
      await tester.tap(find.bySemanticsLabel('Saved'));
      await pumpRoute(tester, 350);
      await tester.tap(find.bySemanticsLabel('Profile'));
      await pumpRoute(tester, 350);

      await scrollSafeIntoView(
        tester,
        find.text('Help centre'),
        scrollableIn(ProfileScreen),
        delta: 220,
      );
      await tester.tap(find.text('Help centre'));
      await pumpRoute(tester, 550);

      await tester.scrollUntilVisible(
        find.text('Still stuck?'),
        200,
        scrollable: scrollableIn(HelpCentreScreen),
      );
      expect(find.text('Still stuck?'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Smart Basket'),
        -200,
        scrollable: scrollableIn(HelpCentreScreen),
      );
      await tester.tap(find.text('Smart Basket'));
      await pumpRoute(tester, 550);
      expect(find.text('FAQs'), findsOneWidget);
    },
  );

  testWidgets(
    'Pincode Back -> Onboarding, Basket stepper updates, Favourites & 360x640 compact layout',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = SastaAppState();
      state.completeSplash();
      state.completeOnboarding();
      await tester.pumpWidget(SastaApp(stateOverride: state));
      await pumpRoute(tester, 450);

      expect(find.text('Where should we\ndeliver?'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await pumpRoute(tester, 550);
      expect(find.text('Search once.\nCompare everywhere.'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await pumpRoute(tester, 550);
      await tester.ensureVisible(find.text('110001 · Central Delhi'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('110001 · Central Delhi'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.ensureVisible(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.tap(find.text('Continue'));
      await pumpRoute(tester, 650);

      // Basket quantity stepper increment / decrement on compact 360x640 screen
      final initialItems = state.activeBasket.totalItems;
      await tester.tap(find.bySemanticsLabel('Basket'));
      await pumpRoute(tester, 450);

      await tester.scrollUntilVisible(
        find.bySemanticsLabel('Increase quantity').first,
        200,
        scrollable: scrollableIn(BasketScreen),
      );
      await tester.tap(find.bySemanticsLabel('Increase quantity').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(state.activeBasket.totalItems, initialItems + 1);

      await tester.tap(find.bySemanticsLabel('Decrease quantity').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(state.activeBasket.totalItems, initialItems);

      // Compare basket -> Split basket & Savings on 360x640
      await tester.tap(find.text('Compare basket'));
      await pumpRoute(tester, 550);
      await tester.tap(find.text('Split basket'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Savings'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await pumpRoute(tester, 450);

      // Toggle favourite on Amul Milk and verify Saved tab
      final wasFav = state.isFavourite('amul_milk');
      state.toggleFavourite('amul_milk');
      expect(state.isFavourite('amul_milk'), !wasFav);
      await tester.tap(find.bySemanticsLabel('Saved'));
      await pumpRoute(tester, 400);
      expect(find.text('Saved'), findsWidgets);
    },
  );
}
