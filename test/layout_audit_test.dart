import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sasta/data/mock_catalog.dart';
import 'package:sasta/data/sasta_app_state.dart';
import 'package:sasta/widgets/product_art.dart';
import 'package:sasta/widgets/product_grid_card.dart';
import 'package:sasta/models/models.dart';
import 'package:sasta/screens/basket/basket_screen.dart';
import 'package:sasta/screens/basket/basket_select_screen.dart';
import 'package:sasta/screens/basket/basket_sheets.dart';
import 'package:sasta/screens/comparison/basket_compare_screen.dart';
import 'package:sasta/screens/help_legal/about_screen.dart';
import 'package:sasta/screens/help_legal/app_info_screen.dart';
import 'package:sasta/screens/help_legal/contact_support_screen.dart';
import 'package:sasta/screens/help_legal/faq_screen.dart';
import 'package:sasta/screens/help_legal/feedback_screen.dart';
import 'package:sasta/screens/help_legal/help_centre_screen.dart';
import 'package:sasta/screens/help_legal/legal_screens.dart';
import 'package:sasta/screens/home/categories_screen.dart';
import 'package:sasta/screens/home/home_screen.dart';
import 'package:sasta/screens/home/home_search_screen.dart';
import 'package:sasta/screens/onboarding/onboarding_screen.dart';
import 'package:sasta/screens/onboarding/pincode_screen.dart';
import 'package:sasta/screens/onboarding/splash_screen.dart';
import 'package:sasta/screens/profile/appearance_screen.dart';
import 'package:sasta/screens/profile/comparison_prefs_screen.dart';
import 'package:sasta/screens/profile/locations_screen.dart';
import 'package:sasta/screens/profile/notification_settings_screen.dart';
import 'package:sasta/screens/profile/personal_info_screen.dart';
import 'package:sasta/screens/profile/profile_screen.dart';
import 'package:sasta/screens/profile/saved_baskets_screen.dart';
import 'package:sasta/screens/profile/security_screen.dart';
import 'package:sasta/screens/sasta_plus/checkout_screen.dart';
import 'package:sasta/screens/sasta_plus/manage_membership_screen.dart';
import 'package:sasta/screens/sasta_plus/pay_success_screen.dart';
import 'package:sasta/screens/sasta_plus/plans_screen.dart';
import 'package:sasta/screens/sasta_plus/plus_landing_screen.dart';
import 'package:sasta/screens/sasta_plus/sub_history_screen.dart';
import 'package:sasta/screens/search_products/favourites_screen.dart';
import 'package:sasta/screens/search_products/notifications_screen.dart';
import 'package:sasta/screens/search_products/price_history_screen.dart';
import 'package:sasta/screens/search_products/product_compare_screen.dart';
import 'package:sasta/screens/search_products/product_details_screen.dart';
import 'package:sasta/screens/search_products/search_history_screen.dart';
import 'package:sasta/screens/search_products/search_results_screen.dart';
import 'package:sasta/theme/sasta_theme.dart';
import 'package:sasta/widgets/sasta_components.dart';
import 'package:sasta/widgets/sasta_sheets.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  SastaAppState makeState() {
    final s = SastaAppState();
    s.completeSplash();
    s.completeOnboarding();
    s.completePincode('110001', area: 'Central Delhi');
    return s;
  }

  Future<List<String>> auditScreen(
    WidgetTester tester, {
    required String name,
    required Widget child,
    SastaAppState? stateOverride,
    Size size = const Size(320, 568),
    double textScale = 1.25,
    Brightness brightness = Brightness.light,
    bool inScaffold = false,
  }) async {
    final errors = <String>[];
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final full = details.toString();
      final lines = full.split('\n');
      final first = details.exceptionAsString().split('\n').first;
      final widgetLines = lines
          .where((l) => l.contains('file:///') && l.contains('sasta/lib/'))
          .take(2)
          .map((l) => l.trim())
          .join(' | ');
      final suffix = widgetLines.isNotEmpty ? ' -> $widgetLines' : '';
      final mode = brightness == Brightness.dark ? ' Dark' : '';
      errors.add(
        '[$name ${size.width.toInt()}x${size.height.toInt()} @${textScale}x$mode] $first$suffix',
      );
    };

    try {
      await tester.binding.setSurfaceSize(size);
      final state = stateOverride ?? makeState();
      if (stateOverride == null) {
        addTearDown(state.dispose);
      }

      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(brightness),
            builder: (ctx, c) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: c!,
            ),
            home: inScaffold ? Scaffold(body: SafeArea(child: child)) : child,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll vertically through primary scrollables if any to trigger lazy build overflows
      final scrollables = find.byWidgetPredicate(
        (w) =>
            w is Scrollable &&
            (w.axisDirection == AxisDirection.down ||
                w.axisDirection == AxisDirection.up),
      );
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(
          scrollables.first,
          const Offset(0, -350),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.drag(
          scrollables.first,
          const Offset(0, -350),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    } finally {
      FlutterError.onError = prevOnError;
      await tester.binding.setSurfaceSize(null);
    }
    return errors;
  }

  testWidgets('Full screen & sheet layout overflow audit across viewports', (tester) async {
    final failures = <String>[];

    final homeEmptyState = makeState()..setFirstTimeUserMode(true);
    final homeOfflineState = makeState()..setHomeOfflineError(true);
    final emptyBasketState = makeState()..clearActiveBasket();
    final basketOfflineState = makeState()..setBasketOfflineError(true);

    final screens = <({String name, Widget widget, SastaAppState? state, bool inScaffold})>[
      (name: 'SplashScreen', widget: const SplashScreen(), state: null, inScaffold: false),
      (name: 'OnboardingScreen', widget: const OnboardingScreen(), state: null, inScaffold: false),
      (name: 'PincodeScreen', widget: const PincodeScreen(), state: null, inScaffold: false),
      (name: 'HomeScreen', widget: const HomeScreen(), state: null, inScaffold: true),
      (name: 'HomeScreen-FirstTime', widget: const HomeScreen(), state: homeEmptyState, inScaffold: true),
      (name: 'HomeScreen-Offline', widget: const HomeScreen(), state: homeOfflineState, inScaffold: true),
      (name: 'HomeSearchScreen', widget: const HomeSearchScreen(), state: null, inScaffold: false),
      (name: 'CategoriesScreen', widget: const CategoriesScreen(), state: null, inScaffold: false),
      (name: 'SearchResultsScreen', widget: const SearchResultsScreen(), state: null, inScaffold: false),
      (name: 'ProductDetailsScreen', widget: const ProductDetailsScreen(), state: null, inScaffold: false),
      (name: 'ProductCompareScreen', widget: const ProductCompareScreen(), state: null, inScaffold: false),
      (name: 'PriceHistoryScreen', widget: const PriceHistoryScreen(), state: null, inScaffold: false),
      (name: 'FavouritesScreen', widget: const FavouritesScreen(isTabRoot: true), state: null, inScaffold: true),
      (name: 'FavouritesScreen-Push', widget: const FavouritesScreen(isTabRoot: false), state: null, inScaffold: false),
      (name: 'NotificationsScreen', widget: const NotificationsScreen(), state: null, inScaffold: false),
      (name: 'SearchHistoryScreen', widget: const SearchHistoryScreen(), state: null, inScaffold: false),
      (name: 'BasketScreen', widget: const BasketScreen(), state: null, inScaffold: true),
      (name: 'BasketScreen-Empty', widget: const BasketScreen(), state: emptyBasketState, inScaffold: true),
      (name: 'BasketScreen-Offline', widget: const BasketScreen(), state: basketOfflineState, inScaffold: true),
      (name: 'BasketSelectScreen', widget: const BasketSelectScreen(), state: null, inScaffold: false),
      (name: 'BasketCompareScreen', widget: const BasketCompareScreen(), state: null, inScaffold: false),
      (name: 'ProfileScreen', widget: const ProfileScreen(), state: null, inScaffold: true),
      (name: 'PersonalInfoScreen', widget: const PersonalInfoScreen(), state: null, inScaffold: false),
      (name: 'LocationsScreen', widget: const LocationsScreen(), state: null, inScaffold: false),
      (name: 'ComparisonPrefsScreen', widget: const ComparisonPrefsScreen(), state: null, inScaffold: false),
      (name: 'NotificationSettingsScreen', widget: const NotificationSettingsScreen(), state: null, inScaffold: false),
      (name: 'AppearanceScreen', widget: const AppearanceScreen(), state: null, inScaffold: false),
      (name: 'SecurityScreen', widget: const SecurityScreen(), state: null, inScaffold: false),
      (name: 'SavedBasketsScreen', widget: const SavedBasketsScreen(), state: null, inScaffold: false),
      (name: 'PlusLandingScreen', widget: const PlusLandingScreen(), state: null, inScaffold: false),
      (name: 'PlansScreen', widget: const PlansScreen(), state: null, inScaffold: false),
      (name: 'CheckoutScreen', widget: const CheckoutScreen(planType: SastaPlanType.yearly), state: null, inScaffold: false),
      (name: 'PaySuccessScreen', widget: const PaySuccessScreen(planType: SastaPlanType.yearly), state: null, inScaffold: false),
      (name: 'ManageMembershipScreen', widget: const ManageMembershipScreen(), state: null, inScaffold: false),
      (name: 'SubHistoryScreen', widget: const SubHistoryScreen(), state: null, inScaffold: false),
      (name: 'HelpCentreScreen', widget: const HelpCentreScreen(), state: null, inScaffold: false),
      (name: 'FaqScreen', widget: const FaqScreen(), state: null, inScaffold: false),
      (name: 'ContactSupportScreen', widget: const ContactSupportScreen(), state: null, inScaffold: false),
      (name: 'FeedbackScreen', widget: const FeedbackScreen(), state: null, inScaffold: false),
      (name: 'AboutScreen', widget: const AboutScreen(), state: null, inScaffold: false),
      (name: 'AppInfoScreen', widget: const AppInfoScreen(), state: null, inScaffold: false),
      (name: 'PrivacyScreen', widget: const PrivacyScreen(), state: null, inScaffold: false),
      (name: 'TermsScreen', widget: const TermsScreen(), state: null, inScaffold: false),
      (name: 'SastaBottomNav', widget: SastaBottomNav(activeIndex: 0, onSelect: (_) {}, basketCount: 4), state: null, inScaffold: true),
      (name: 'BasketFloatingBar', widget: BasketFloatingBar(productCount: 4, estimateTotal: 266, onCompare: () {}), state: null, inScaffold: true),
    ];

    for (final s in screens) {
      failures.addAll(
        await auditScreen(
          tester,
          name: s.name,
          child: s.widget,
          stateOverride: s.state,
          size: const Size(320, 568),
          textScale: 1.25,
          brightness: Brightness.light,
          inScaffold: s.inScaffold,
        ),
      );
      failures.addAll(
        await auditScreen(
          tester,
          name: s.name,
          child: s.widget,
          stateOverride: s.state,
          size: const Size(360, 640),
          textScale: 1.0,
          brightness: Brightness.light,
          inScaffold: s.inScaffold,
        ),
      );
    }

    // Dark-mode stress check at 320x568 @1.25x on core dense screens
    for (final s in [
      (name: 'HomeScreen', widget: const HomeScreen(), inScaffold: true),
      (name: 'CategoriesScreen', widget: const CategoriesScreen(), inScaffold: false),
      (name: 'SearchResultsScreen', widget: const SearchResultsScreen(), inScaffold: false),
      (name: 'ProductCompareScreen', widget: const ProductCompareScreen(), inScaffold: false),
      (name: 'BasketScreen', widget: const BasketScreen(), inScaffold: true),
      (name: 'PlusLandingScreen', widget: const PlusLandingScreen(), inScaffold: false),
      (name: 'HelpCentreScreen', widget: const HelpCentreScreen(), inScaffold: false),
    ]) {
      failures.addAll(
        await auditScreen(
          tester,
          name: s.name,
          child: s.widget,
          size: const Size(320, 568),
          textScale: 1.25,
          brightness: Brightness.dark,
          inScaffold: s.inScaffold,
        ),
      );
    }

    // Also audit bottom sheets on 320x568 @1.25x
    Future<void> auditSheet(
      String name,
      Future<void> Function(BuildContext ctx) opener,
    ) async {
      final errors = <String>[];
      final prevOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add('[Sheet:$name] ${details.exceptionAsString().split('\n').first}');
      };
      try {
        await tester.binding.setSurfaceSize(const Size(320, 568));
        final state = makeState();
        addTearDown(state.dispose);
        late BuildContext capturedCtx;
        await tester.pumpWidget(
          SastaScope(
            state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            builder: (ctx, c) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(
                textScaler: const TextScaler.linear(1.25),
              ),
              child: c!,
            ),
            home: Scaffold(
              body: Builder(
                  builder: (ctx) {
                    capturedCtx = ctx;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        );
        opener(capturedCtx);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
      } finally {
        FlutterError.onError = prevOnError;
        await tester.binding.setSurfaceSize(null);
      }
      failures.addAll(errors);
    }

    await auditSheet('CreatePriceAlert', (c) => showCreatePriceAlertSheet(c));
    await auditSheet(
      'RetailerHandoff',
      (c) => showRetailerHandoffSheet(
        c,
        retailer: RetailerId.zepto,
        estimatedAmount: 266,
        itemLabel: 'Amul Taaza Toned Milk (1 L)',
      ),
    );
    await auditSheet('MonthlySavings', (c) => showMonthlySavingsSheet(c));
    await auditSheet('BasketShare', (c) => showBasketShareSheet(c));
    await auditSheet('BasketOptions', (c) => showBasketOptionsSheet(c));

    // Pump out extra states to avoid pending timers if any
    homeEmptyState.dispose();
    homeOfflineState.dispose();
    emptyBasketState.dispose();
    basketOfflineState.dispose();

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  testWidgets(
    'Real retailer icons resolve, ProductGridCard children stay bounded & non-overlapping, and Onboarding/Compare tabs fit 320x568',
    (WidgetTester tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // 1. Every official retailer PNG asset must exist in bundle and start with PNG signature.
      for (final retailer in RetailerId.values) {
        final data = await rootBundle.load(retailer.assetPath);
        final bytes = data.buffer.asUint8List();
        expect(bytes.length, greaterThan(1000), reason: retailer.assetPath);
        expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      }

      // 2. ProductGridCard at tight 320px 2-column width (~133px): badge, heart, and art stay inside bounds & never overlap.
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final sampleProduct = MockCatalog.products.first;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSastaTheme(Brightness.light),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 133,
                child: ProductGridCard(
                  product: sampleProduct,
                  badgeText: '-40%',
                  showFavouriteButton: true,
                  onToggleFavourite: () {},
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final cardRect = tester.getRect(find.byType(ProductGridCard));
      final badgeRect = tester.getRect(find.text('-40%'));
      final heartRect =
          tester.getRect(find.byIcon(Icons.favorite_border_rounded));
      final artRect = tester.getRect(
        find.descendant(
          of: find.byType(ProductGridCard),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is ProductArtPainter,
          ),
        ),
      );

      expect(cardRect.left <= badgeRect.left, isTrue);
      expect(cardRect.top <= badgeRect.top, isTrue);
      expect(cardRect.right >= heartRect.right, isTrue);
      expect(cardRect.top <= heartRect.top, isTrue);
      expect(badgeRect.overlaps(heartRect), isFalse);
      expect(badgeRect.overlaps(artRect), isFalse);
      expect(heartRect.overlaps(artRect), isFalse);

      // 3. RetailerAvatar widgets render all 4 brands without overflow or error.
      await tester.pumpWidget(
        MaterialApp(
          theme: buildSastaTheme(Brightness.dark),
          home: Scaffold(
            body: Wrap(
              spacing: 12,
              children: [
                for (final r in RetailerId.values)
                  RetailerAvatar(retailer: r, size: 64, showBorder: true),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(Image), findsNWidgets(RetailerId.values.length));

      // 4. OnboardingScreen orb stays within 320x568 @1.25x viewport.
      final state = makeState();
      addTearDown(state.dispose);
      final overflowErrors = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) => overflowErrors.add(d.exceptionAsString());
      try {
        await tester.pumpWidget(
          SastaScope(
            state: state,
            child: MaterialApp(
              theme: buildSastaTheme(Brightness.light),
              builder: (ctx, c) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(1.25),
                ),
                child: c!,
              ),
              home: const OnboardingScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));

        // 5. BasketCompareScreen Mix Stores + Savings tabs at 320x568 @1.25x.
        await tester.pumpWidget(
          SastaScope(
            state: state,
            child: MaterialApp(
              theme: buildSastaTheme(Brightness.light),
              builder: (ctx, c) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: const TextScaler.linear(1.25),
                ),
                child: c!,
              ),
              home: const BasketCompareScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(find.text('Mix Stores'));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.tap(find.text('Savings'));
        await tester.pump(const Duration(milliseconds: 350));
      } finally {
        FlutterError.onError = prev;
      }
      expect(overflowErrors, isEmpty, reason: overflowErrors.join('\n'));
    },
  );
}
