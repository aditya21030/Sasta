import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import 'package:sasta/app/sasta_routes.dart';
import 'package:sasta/data/mock_catalog.dart';
import 'package:sasta/data/sasta_app_state.dart';
import 'package:sasta/main.dart';
import 'package:sasta/models/models.dart';
import 'package:sasta/screens/basket/basket_screen.dart';
import 'package:sasta/screens/comparison/basket_compare_screen.dart';
import 'package:sasta/screens/help_legal/help_centre_screen.dart';
import 'package:sasta/screens/home/home_search_screen.dart';
import 'package:sasta/screens/onboarding/pincode_screen.dart';
import 'package:sasta/screens/profile/comparison_prefs_screen.dart';
import 'package:sasta/screens/profile/locations_screen.dart';
import 'package:sasta/screens/profile/profile_screen.dart';
import 'package:sasta/screens/sasta_plus/checkout_screen.dart';
import 'package:sasta/screens/sasta_plus/pay_success_screen.dart';
import 'package:sasta/screens/sasta_plus/plus_landing_screen.dart';
import 'package:sasta/screens/sasta_plus/sub_history_screen.dart';
import 'package:sasta/screens/search_products/price_history_screen.dart';
import 'package:sasta/screens/search_products/product_details_screen.dart';
import 'package:sasta/screens/search_products/search_results_screen.dart';
import 'package:sasta/widgets/product_art.dart';
import 'package:sasta/widgets/product_grid_card.dart';
import 'package:sasta/theme/sasta_theme.dart';
import 'package:sasta/theme/sasta_tokens.dart';
import 'package:sasta/services/local_storage_service.dart';
import 'package:sasta/services/pincode_location_service.dart';
import 'package:sasta/services/quick_commerce_api.dart';
import 'package:sasta/services/retailer_launcher_service.dart';
import 'package:sasta/services/share_service.dart';

const _testQuickCommerceConfig = QuickCommerceApiConfig(
  baseUrl: 'https://api.quickcommerceapi.com',
  apiKey: 'test-qc-api-key',
);

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
      expect(find.text('1 Store'), findsOneWidget);
      expect(find.text('Mix Stores'), findsOneWidget);
      expect(find.text('₹266'), findsWidgets);

      await tester.tap(find.text('Mix Stores'));
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

      // Compare basket -> Mix Stores & Savings on 360x640
      await tester.tap(find.text('Compare basket'));
      await pumpRoute(tester, 550);
      await tester.tap(find.text('Mix Stores'));
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

  test('Product and state models round-trip through JSON cleanly', () {
    final sample = MockCatalog.products.first;
    final decoded = Product.fromJson(
      jsonDecode(jsonEncode(sample.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.id, sample.id);
    expect(decoded.name, sample.name);
    expect(decoded.variants.length, sample.variants.length);
    expect(
      decoded.cheapestQuote(decoded.defaultVariantIndex)?.price,
      sample.cheapestQuote(sample.defaultVariantIndex)?.price,
    );

    const loc = SavedLocation(
      id: 'loc_x',
      label: 'Home',
      pincode: '560034',
      area: 'Koramangala, Bengaluru',
      isDefault: true,
    );
    final decodedLoc = SavedLocation.fromJson(
      jsonDecode(jsonEncode(loc.toJson())) as Map<String, dynamic>,
    );
    expect(decodedLoc.pincode, '560034');
    expect(decodedLoc.area, 'Koramangala, Bengaluru');
    expect(decodedLoc.isDefault, isTrue);
  });

  test(
    'SharedPreferences persists onboarding, pincode, basket, theme & API config',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();

      final s1 = await SastaAppState.createAndLoad(storage: storage);
      s1.completeSplash();
      s1.completeOnboarding();
      s1.completePincode('560034', area: 'Koramangala');
      s1.setThemeMode(ThemeMode.dark);
      s1.addToBasket('amul_butter', delta: 2);
      await s1.updateApiConfig(
        baseUrl: 'https://api.sasta.example',
        apiKey: 'secret_token',
        syncNow: false,
      );
      await s1.flushPersistence();
      s1.dispose();

      final s2 = await SastaAppState.createAndLoad(
        storage: storage,
        syncIfConfigured: false,
      );
      addTearDown(s2.dispose);
      expect(s2.hasSeenOnboarding, isTrue);
      expect(s2.hasSetPincode, isTrue);
      expect(s2.activeLocation.pincode, '560034');
      expect(s2.themeMode, ThemeMode.dark);
      expect(s2.quantityInActiveBasket('amul_butter'), 2);
      expect(s2.apiBaseUrl, 'https://api.sasta.example');
      expect(s2.apiKey, 'secret_token');
    },
  );

  test(
    'HttpQuickCommerceRepository syncs live API catalog and merges into SastaAppState',
    () async {
      Uri? capturedUri;
      Map<String, String>? capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        if (request.url.path.endsWith('/v1/catalog/home')) {
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'pincode': '560034',
                'area': 'Koramangala, Bengaluru',
                'serviceableRetailers': ['blinkit', 'zepto'],
                'products': [
                  {
                    'id': 'live_avocado',
                    'name': 'Hass Avocado Imported',
                    'brand': 'FreshKart',
                    'categoryId': 'fruits_veg',
                    'categoryLabel': 'Fruits & Vegetables',
                    'subtitle': '1 pc (approx 180 g)',
                    'artKind': 'veg',
                    'pastel': 'mint',
                    'defaultVariantIndex': 0,
                    'isDeal': true,
                    'variants': [
                      {
                        'label': '1 pc',
                        'quotes': [
                          {
                            'retailer': 'zepto',
                            'price': 89,
                            'mrp': 125,
                            'packLabel': '1 pc',
                            'unitPriceText': '₹89/pc',
                            'stockStatus': 'inStock',
                          },
                        ],
                      },
                    ],
                  },
                ],
              }),
            ),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not found', 404);
      });

      final repo = HttpQuickCommerceRepository(
        config: const QuickCommerceApiConfig(
          baseUrl: 'https://api.sasta.test',
          apiKey: 'key_99',
        ),
        client: mockClient,
      );

      final state = SastaAppState(repository: repo);
      addTearDown(state.dispose);
      state.completePincode('560034', area: 'Bengaluru');

      final synced = await state.syncCatalogForLocation();
      expect(synced, isTrue);
      expect(capturedUri?.path, '/v1/catalog/home');
      expect(capturedUri?.queryParameters['pincode'], '560034');
      expect(capturedHeaders?['Authorization'], 'Bearer key_99');
      expect(capturedHeaders?['X-API-Key'], 'key_99');
      expect(state.isLiveCatalogActive, isTrue);
      expect(state.activeLocation.area, 'Koramangala, Bengaluru');
      expect(state.productById('live_avocado')?.name, 'Hass Avocado Imported');
      expect(state.productById('live_avocado')?.cheapestQuote(0)?.price, 89);
    },
  );

  test(
    'PincodeLocationService resolves India Post pincodes & GPS Nominatim coordinates',
    () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.postalpincode.in') {
          return http.Response(
            jsonEncode([
              {
                'Status': 'Success',
                'PostOffice': [
                  {
                    'Name': 'Koramangala I Block',
                    'Block': 'Bengaluru South',
                    'District': 'Bengaluru',
                    'State': 'Karnataka',
                  },
                ],
              },
            ]),
            200,
          );
        }
        if (request.url.host == 'nominatim.openstreetmap.org') {
          return http.Response(
            jsonEncode({
              'address': {
                'postcode': '560034',
                'suburb': 'Koramangala',
                'city': 'Bengaluru',
                'state': 'Karnataka',
              },
            }),
            200,
          );
        }
        return http.Response('', 404);
      });

      final service = PincodeLocationService(
        client: mockClient,
        positionProvider: () async => (lat: 12.9352, lng: 77.6245),
      );
      addTearDown(service.dispose);

      final postal = await service.lookupPincode('560034');
      expect(postal?.pincode, '560034');
      expect(postal?.displayArea, 'Bengaluru South, Bengaluru');

      final gps = await service.detectCurrentLocation();
      expect(gps.isSuccess, isTrue);
      expect(gps.resolved?.pincode, '560034');
      expect(gps.resolved?.displayArea, 'Koramangala, Bengaluru');
    },
  );

  test(
    'RetailerLauncherService & SastaShareService build store links & delegate launches',
    () async {
      expect(
        RetailerLauncherService.buildWebUri(
          RetailerId.blinkit,
          query: 'Amul Milk',
        ).toString(),
        'https://blinkit.com/s/?q=Amul+Milk',
      );
      expect(
        RetailerLauncherService.buildWebUri(
          RetailerId.zepto,
          query: 'Bread',
        ).toString(),
        'https://www.zeptonow.com/search?query=Bread',
      );

      final launchedUris = <Uri>[];
      final launcher = RetailerLauncherService(
        canLaunchDelegate: (_) async => false,
        launchUrlDelegate: (uri, {mode = url_launcher.LaunchMode.platformDefault}) async {
          launchedUris.add(uri);
          return true;
        },
      );

      final outcome =
          await launcher.openRetailer(RetailerId.instamart, query: 'Dahi');
      expect(outcome.launched, isTrue);
      expect(outcome.openedNativeApp, isFalse);
      expect(launchedUris.single.host, 'www.swiggy.com');

      String? sharedPayload;
      final shareService = SastaShareService(
        shareDelegate: (text, {subject}) async {
          sharedPayload = text;
        },
        whatsAppDelegate: (uri) async {
          launchedUris.add(uri);
          return true;
        },
      );

      await shareService.shareToWhatsApp('Milk ₹27');
      await shareService.shareText('Basket ₹266');
      expect(launchedUris.last.host, 'wa.me');
      expect(sharedPayload, 'Basket ₹266');
    },
  );

  testWidgets(
    'PincodeScreen resolves India Post + GPS & ComparisonPrefs saves API config',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockClient = MockClient((request) async {
        if (request.url.host == 'api.postalpincode.in') {
          return http.Response(
            jsonEncode([
              {
                'Status': 'Success',
                'PostOffice': [
                  {
                    'Name': 'Indiranagar',
                    'Block': 'Bengaluru East',
                    'District': 'Bengaluru',
                    'State': 'Karnataka',
                  },
                ],
              },
            ]),
            200,
          );
        }
        if (request.url.host == 'nominatim.openstreetmap.org') {
          return http.Response(
            jsonEncode({
              'address': {
                'postcode': '560038',
                'suburb': 'Indiranagar',
                'city': 'Bengaluru',
              },
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final locService = PincodeLocationService(
        client: mockClient,
        positionProvider: () async => (lat: 12.9784, lng: 77.6408),
      );
      addTearDown(locService.dispose);

      final state = SastaAppState(locationService: locService);
      addTearDown(state.dispose);
      state.completeSplash();
      state.completeOnboarding();

      await tester.pumpWidget(SastaApp(stateOverride: state));
      await pumpRoute(tester, 450);

      expect(find.byType(PincodeScreen), findsOneWidget);
      await tester.tap(find.text('Use my current location'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('560038'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await pumpRoute(tester, 700);
      expect(state.activeLocation.pincode, '560038');
      expect(find.text('What are we\nsaving on today?'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Profile'));
      await pumpRoute(tester, 450);
      await scrollSafeIntoView(
        tester,
        find.text('Comparison preferences'),
        scrollableIn(ProfileScreen),
        delta: 220,
      );
      await tester.tap(find.text('Comparison preferences'));
      await pumpRoute(tester, 550);

      expect(find.byType(ComparisonPrefsScreen), findsOneWidget);
      await scrollSafeIntoView(
        tester,
        find.text('Live price server (Optional)'),
        scrollableIn(ComparisonPrefsScreen),
        delta: 220,
      );
      expect(find.text('Live price server (Optional)'), findsOneWidget);
      await tester.tap(find.text('Live price server (Optional)'));
      await pumpRoute(tester, 350);
      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Save & sync live prices'), findsOneWidget);
    },
  );

  testWidgets(
    'QuickCommerceAPI v1 maps cross-platform items, images, URLs, caches 6h & launches productUrl',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var groupSearchHits = 0;
      var creditsHits = 0;
      String? lastApiKeyHeader;

      final groupSearchPayload = {
        'status': 'success',
        'credits_remaining': 96,
        'data': {
          'query': 'milk',
          'results': {
            'BlinkIt': [
              {
                'id': 'bl_1',
                'name': 'Amul Taaza Toned Fresh Milk',
                'brand': 'Amul',
                'quantity': '500 ml',
                'mrp': 28,
                'offer_price': 27,
                'available': true,
                'inventory': 10,
                'rating': 4.8,
                'rating_count': 1240,
                'deeplink': 'https://blinkit.com/prn/amul-taaza/prid/19512',
                'images': ['https://cdn.example.com/blinkit-amul-500.png'],
                'platform': {'sla': '12 mins', 'open': true},
              },
            ],
            'Zepto': [
              {
                'id': 'zp_1',
                'name': 'Amul Taaza Toned Milk',
                'brand': 'Amul',
                'quantity': '1 pack (500 ml)',
                'mrp': 28,
                'offer_price': 26,
                'available': true,
                'inventory': 2,
                'deeplink': 'https://www.zepto.com/pn/amul-taaza/pvid/991',
                'images': ['https://cdn.example.com/zepto-amul-500.png'],
                'platform': {'sla': '8 mins', 'open': true},
              },
            ],
            'Swiggy': [
              {
                'id': 'sw_1',
                'name': 'Amul Taaza Toned Milk Pouch',
                'brand': 'Amul',
                'quantity': '500 ml',
                'mrp': '28',
                'offer_price': '27',
                'available': true,
                'inventory': 15,
                'deeplink': 'https://www.swiggy.com/stores/instamart/item/sw_1',
                'images': ['https://cdn.example.com/swiggy-amul-500.png'],
                'platform': {'sla': '14 mins', 'open': true},
              },
            ],
            'Minutes': [
              {
                'id': 'fm_1',
                'name': 'Amul Taaza Toned Milk 500 ml',
                'brand': 'Amul',
                'quantity': '',
                'mrp': 28,
                'offer_price': 28,
                'available': true,
                'deeplink': 'https://www.flipkart.com/amul-taaza/p/fm_1',
                'images': [],
                'platform': {'sla': '16 mins', 'open': true},
              },
            ],
          },
        },
      };

      final mockClient = MockClient((request) async {
        lastApiKeyHeader = request.headers['X-API-Key'];
        if (request.url.path == '/v1/groupsearch') {
          groupSearchHits++;
          return http.Response(
            jsonEncode(groupSearchPayload),
            200,
            headers: {'x-credits-remaining': '96'},
          );
        }
        if (request.url.path == '/v1/credits') {
          creditsHits++;
          return http.Response(
            jsonEncode({
              'summary': {
                'total_available': 96,
                'total_used': 4,
                'active_packs': 1,
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final repo = HttpQuickCommerceRepository(
        config: _testQuickCommerceConfig,
        client: mockClient,
      );
      addTearDown(repo.dispose);

      final launchedUris = <Uri>[];
      final launcher = RetailerLauncherService(
        canLaunchDelegate: (_) async => true,
        launchUrlDelegate: (
          uri, {
          mode = url_launcher.LaunchMode.platformDefault,
        }) async {
          launchedUris.add(uri);
          return true;
        },
      );

      final state = SastaAppState(
        repository: repo,
        retailerLauncher: launcher,
      );
      addTearDown(state.dispose);
      state.completeSplash();
      state.completeOnboarding();
      state.completePincode('560102', area: 'HSR Layout');

      // Direct QuickCommerceAPI defaults to credit-saver manual mode (0 auto calls).
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(state.onDemandLiveMode, isTrue);
      expect(groupSearchHits, 0);

      // Explicit Sync fetches catalog once.
      final firstSyncOk = await state.syncCatalogForLocation();
      expect(firstSyncOk, isTrue);
      expect(lastApiKeyHeader, 'test-qc-api-key');
      expect(groupSearchHits, 1);
      expect(state.isLiveCatalogActive, isTrue);
      expect(state.apiCreditsRemaining, 96);
      expect(state.etaFor(RetailerId.zepto), '8 mins');
      expect(state.etaFor(RetailerId.blinkit), '12 mins');
      expect(state.etaFor(RetailerId.instamart), '14 mins');
      expect(state.etaFor(RetailerId.flipkartMinutes), '16 mins');

      // Calling syncCatalogForLocation again within 6h must spend 0 extra requests.
      final secondSyncOk = await state.syncCatalogForLocation();
      expect(secondSyncOk, isTrue);
      expect(groupSearchHits, 1);

      // Free credit check endpoint works without consuming search credits.
      final creditInfo = await state.refreshCreditsBalance();
      expect(creditsHits, 1);
      expect(creditInfo?.totalAvailable, 96);

      // Mapped live product appears first in search & keeps real images, URLs, and 4 quotes.
      final found = state.searchProducts('amul taaza');
      expect(found, isNotEmpty);
      final liveAmul = found.first;
      expect(liveAmul.isLiveProduct, isTrue);
      expect(liveAmul.bestImageUrl, isNotNull);
      expect(liveAmul.availableAppCount(0), 4);
      final cheapest = liveAmul.cheapestQuote(0);
      expect(cheapest?.retailer, RetailerId.zepto);
      expect(cheapest?.price, 26);
      expect(
        cheapest?.productUrl,
        'https://www.zepto.com/pn/amul-taaza/pvid/991',
      );
      expect(cheapest?.unitPriceText, contains('100 ml'));

      // RetailerLauncherService prefers direct productUrl deeplink when provided.
      final outcome = await state.retailerLauncher.openRetailer(
        RetailerId.zepto,
        query: liveAmul.name,
        productUrl: cheapest?.productUrl,
      );
      expect(outcome.launched, isTrue);
      expect(
        launchedUris.single.toString(),
        'https://www.zepto.com/pn/amul-taaza/pvid/991',
      );

      // Verify UI screens render live product images, rating, deeplink & credit balance cleanly.
      await tester.pumpWidget(SastaApp(stateOverride: state));
      await pumpRoute(tester, 450);

      // Navigate into live product details & comparison screen from Home search.
      await tester.tap(find.text('Search groceries, brands, products…'));
      await pumpRoute(tester, 450);
      await tester.enterText(find.byType(TextField), 'amul taaza');
      await tester.pump(const Duration(milliseconds: 120));
      await tester.tap(find.text(liveAmul.name).first);
      await pumpRoute(tester, 550);
      expect(find.textContaining('4.8'), findsOneWidget);

      await tester.tap(find.text('Compare'));
      await pumpRoute(tester, 550);
      expect(find.text('8 mins'), findsOneWidget);
      await tester.tap(find.text('Open Zepto app ↗'));
      await pumpRoute(tester, 350);
      await tester.tap(find.text('Launch Zepto ↗'));
      await pumpRoute(tester, 250);
      expect(launchedUris.length, 2);
      expect(
        launchedUris.last.toString(),
        'https://www.zepto.com/pn/amul-taaza/pvid/991',
      );

      // Return to Home and check Comparison preferences.
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await pumpRoute(tester, 350);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await pumpRoute(tester, 350);
      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await pumpRoute(tester, 350);

      await tester.tap(find.bySemanticsLabel('Profile'));
      await pumpRoute(tester, 450);
      await scrollSafeIntoView(
        tester,
        find.text('Comparison preferences'),
        scrollableIn(ProfileScreen),
        delta: 220,
      );
      await tester.tap(find.text('Comparison preferences'));
      await pumpRoute(tester, 550);

      await scrollSafeIntoView(
        tester,
        find.text('Live price server (QuickCommerceAPI)'),
        scrollableIn(ComparisonPrefsScreen),
        delta: 220,
      );
      expect(
        find.text('Live price server (QuickCommerceAPI)'),
        findsOneWidget,
      );
      expect(find.text('Connected · 96 credits left'), findsOneWidget);

      await tester.tap(find.text('Live price server (QuickCommerceAPI)'));
      await pumpRoute(tester, 350);
      expect(find.text('Credits remaining: 96'), findsOneWidget);
      expect(find.text('Check balance'), findsOneWidget);
    },
  );

  testWidgets(
    'Credit-saver mode, subset retailers, disk cache persistence, daily quota & proxy rawGroupSearch',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});

      final recordedUris = <Uri>[];
      Map<String, dynamic> buildPayload(String q, List<String> platforms) {
        final results = <String, dynamic>{};
        if (platforms.contains('BlinkIt')) {
          results['BlinkIt'] = [
            {
              'id': 'bl_${q.hashCode}',
              'name': 'Fresh Tomato Hybrid ($q)',
              'brand': 'FarmFresh',
              'quantity': '500 g',
              'mrp': 40,
              'offer_price': 34,
              'available': true,
              'deeplink': 'https://blinkit.com/prn/tomato/prid/101',
              'images': ['https://cdn.example.com/bl-tomato.png'],
              'platform': {'sla': '10 mins', 'open': true},
            },
          ];
        }
        if (platforms.contains('Zepto')) {
          results['Zepto'] = [
            {
              'id': 'zp_${q.hashCode}',
              'name': 'Fresh Tomato Hybrid ($q)',
              'brand': 'FarmFresh',
              'quantity': '500 g',
              'mrp': 40,
              'offer_price': 31,
              'available': true,
              'deeplink': 'https://zepto.com/pn/tomato/pvid/202',
              'images': ['https://cdn.example.com/zp-tomato.png'],
              'platform': {'sla': '8 mins', 'open': true},
            },
          ];
        }
        return {
          'status': 'success',
          'credits_remaining': 80,
          'data': {'query': q, 'results': results},
        };
      }

      MockClient createMockClient() => MockClient((request) async {
            if (request.url.path == '/v1/groupsearch') {
              recordedUris.add(request.url);
              final q = request.url.queryParameters['q'] ?? 'milk';
              final plats = (request.url.queryParameters['platforms'] ?? '')
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .toList();
              return http.Response(
                jsonEncode(buildPayload(q, plats)),
                200,
                headers: {'x-credits-remaining': '80'},
              );
            }
            return http.Response('{}', 404);
          });

      // Boot 1: Credit-saver active by default for QuickCommerceAPI direct.
      final storage = LocalStorageService();
      final state1 = await SastaAppState.createAndLoad(
        storage: storage,
        defaultApiConfig: _testQuickCommerceConfig,
        repository: HttpQuickCommerceRepository(
          config: _testQuickCommerceConfig,
          client: createMockClient(),
        ),
      );
      addTearDown(state1.dispose);
      state1.completeSplash();
      state1.completeOnboarding();
      state1.completePincode('560102', area: 'HSR Layout');
      expect(recordedUris, isEmpty);

      // Opening Fruits category with onDemandLiveMode ON must spend 0 credits.
      await tester.pumpWidget(
        SastaScope(
          state: state1,
          child: AnimatedBuilder(
            animation: state1,
            builder: (_, _) => MaterialApp(
              theme: buildSastaTheme(Brightness.light),
              home: SearchResultsScreen(
                args: const SearchResultsArgs(
                  categoryId: 'fruits_veg',
                  titleOverride: 'Fruits & Veg',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(recordedUris, isEmpty);
      expect(find.text('Fetch live'), findsOneWidget);

      // Disabling Instamart & Minutes restricts network call to 2 platforms.
      state1.toggleRetailer(RetailerId.instamart, false);
      state1.toggleRetailer(RetailerId.flipkartMinutes, false);
      expect(state1.estimatedCreditsPerSearch, 2);

      // Tapping "Fetch live" sends subset platforms & snapped hub coordinates.
      await tester.tap(find.text('Fetch live'));
      await tester.pumpAndSettle();
      expect(recordedUris.length, 1);
      expect(recordedUris.last.queryParameters['platforms'], 'BlinkIt,Zepto');
      final sentLat = double.parse(recordedUris.last.queryParameters['lat']!);
      final sentLon = double.parse(recordedUris.last.queryParameters['lon']!);
      expect((sentLat * 50).roundToDouble(), closeTo(sentLat * 50, 0.0001));
      expect((sentLon * 50).roundToDouble(), closeTo(sentLon * 50, 0.0001));
      expect(find.text('Cached live prices · 0 credits'), findsOneWidget);

      // Persist & cold-restart into state2: cached category query hits disk at 0 calls.
      await state1.flushPersistence();
      final state2 = await SastaAppState.createAndLoad(
        storage: LocalStorageService(),
        defaultApiConfig: _testQuickCommerceConfig,
        repository: HttpQuickCommerceRepository(
          config: _testQuickCommerceConfig,
          client: createMockClient(),
        ),
      );
      addTearDown(state2.dispose);
      expect(
        state2.hasFreshCacheFor(
          query: 'tomato potato onion',
          categoryId: 'fruits_veg',
        ),
        isTrue,
      );
      final callsBeforeRestartSearch = recordedUris.length;
      await state2.searchProductsRemote(
        'tomato potato onion',
        categoryId: 'fruits_veg',
      );
      expect(recordedUris.length, callsBeforeRestartSearch);

      // Reach 3/3 daily free uncached search limit (1 used in state1 + 2 more here).
      await state2.searchProductsRemote('bread');
      await state2.searchProductsRemote('curd');
      expect(recordedUris.length, 3);
      expect(state2.isLiveQuotaExhausted, isTrue);

      // 4th uncached search stays local and spends 0 credits.
      await state2.searchProductsRemote('avocado');
      expect(recordedUris.length, 3);
      expect(state2.lastSyncError, contains('3/day'));

      // Sasta+ unlocks unlimited live searches.
      state2.subscribeToPlan(SastaPlanType.monthly);
      expect(state2.hasUnlimitedLiveSearches, isTrue);
      await state2.searchProductsRemote('avocado');
      expect(recordedUris.length, 4);

      // Shared backend proxy mode: maps `rawGroupSearch` seamlessly with onDemandLiveMode=false.
      Uri? proxySearchUri;
      final proxyClient = MockClient((request) async {
        if (request.url.path == '/v1/catalog/search') {
          proxySearchUri = request.url;
          return http.Response(
            jsonEncode({
              'pincode': '560102',
              'rawGroupSearch': buildPayload('paneer', ['BlinkIt', 'Zepto']),
              'serviceableRetailers': ['BlinkIt', 'Zepto'],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });
      final proxyRepo = HttpQuickCommerceRepository(
        config: const QuickCommerceApiConfig(
          baseUrl: 'https://proxy.sasta.test',
          apiKey: 'client_tok',
        ),
        client: proxyClient,
      );
      addTearDown(proxyRepo.dispose);

      final proxyState = SastaAppState(repository: proxyRepo);
      addTearDown(proxyState.dispose);
      expect(proxyState.onDemandLiveMode, isFalse);

      final proxyProducts = await proxyState.searchProductsRemote(
        'paneer',
      );
      expect(proxySearchUri?.path, '/v1/catalog/search');
      expect(proxyProducts.any((p) => p.name.contains('Fresh Tomato Hybrid')), isTrue);
      await state2.flushPersistence();
    },
  );

  test(
    'Variant-distinct basket entries track & update quantities independently',
    () {
      final state = onboardedState()..clearActiveBasket();
      addTearDown(state.dispose);

      // amul_milk has 2 variants (500 ml & 1 L)
      state.addToBasket('amul_milk', variantIndex: 0, delta: 2);
      state.addToBasket('amul_milk', variantIndex: 1, delta: 1);

      expect(state.quantityInActiveBasket('amul_milk', variantIndex: 0), 2);
      expect(state.quantityInActiveBasket('amul_milk', variantIndex: 1), 1);
      expect(state.quantityInActiveBasket('amul_milk'), 3);
      expect(state.activeBasket.uniqueProducts, 2);

      // Updating variant 1 to 0 removes only variant 1.
      state.updateBasketItemQuantity('amul_milk', 0, variantIndex: 1);
      expect(state.quantityInActiveBasket('amul_milk', variantIndex: 0), 2);
      expect(state.quantityInActiveBasket('amul_milk', variantIndex: 1), 0);
      expect(state.activeBasket.uniqueProducts, 1);
    },
  );

  testWidgets(
    'Empty BasketCompareScreen and empty-history PriceHistoryScreen render cleanly',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final state = onboardedState();
      addTearDown(() {
        state.dispose();
        tester.binding.setSurfaceSize(null);
      });

      final noHistoryProduct = const Product(
        id: 'live_empty_hist',
        name: 'Organic Kale Pack',
        brand: 'FreshFarm',
        categoryId: 'fruits_veg',
        categoryLabel: 'Fruits & Vegetables',
        subtitle: '200 g',
        artKind: ProductArtKind.veg,
        pastel: SastaPastel.mint,
        defaultVariantIndex: 0,
        variants: [
          PackVariant(
            label: '200 g',
            quotes: [
              RetailerQuote(
                retailer: RetailerId.zepto,
                price: 55,
                mrp: 70,
                packLabel: '200 g',
                unitPriceText: '₹27.5/100g',
                stockStatus: StockStatus.inStock,
              ),
            ],
          ),
        ],
        historyByRange: {},
      );

      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: const BasketCompareScreen(
              args: BasketCompareArgs(customEntries: []),
            ),
          ),
        ),
      );
      await pumpRoute(tester, 450);
      expect(find.text('No comparable in-stock items'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final liveClient = MockClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'pincode': '110001',
              'area': 'Central Delhi',
              'products': [noHistoryProduct.toJson()],
            }),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final liveRepo = HttpQuickCommerceRepository(
        config: const QuickCommerceApiConfig(
          baseUrl: 'https://proxy.sasta.test',
          apiKey: 'tok',
        ),
        client: liveClient,
      );
      final liveState = SastaAppState(repository: liveRepo)
        ..completeSplash()
        ..completeOnboarding()
        ..completePincode('110001', area: 'Central Delhi');
      addTearDown(() {
        liveState.dispose();
        liveRepo.dispose();
      });
      await liveState.syncCatalogForLocation(forceRefresh: true);

      await tester.pumpWidget(
        SastaScope(
          state: liveState,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: const PriceHistoryScreen(
              args: ProductRouteArgs(productId: 'live_empty_hist'),
            ),
          ),
        ),
      );
      await pumpRoute(tester, 450);
      expect(find.text('No price history recorded yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PincodeScreen & LocationsScreen reject empty and 000000 pincodes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final state = SastaAppState()
        ..completeSplash()
        ..completeOnboarding();
      addTearDown(() {
        state.dispose();
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: const PincodeScreen(),
          ),
        ),
      );
      await pumpRoute(tester, 450);

      // Empty Continue should remain a no-op (no silent 110001 fallback).
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(state.hasSetPincode, isFalse);

      // Invalid leading-zero 6-digit pincode is rejected inline.
      await tester.enterText(find.byType(TextField), '000000');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Please enter a valid 6-digit pincode'), findsOneWidget);
      expect(state.hasSetPincode, isFalse);

      // LocationsScreen modal validates 000000 inline too without adding a location.
      state.completePincode('110001', area: 'Central Delhi');
      final beforeLocationCount = state.locations.length;
      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: const LocationsScreen(),
          ),
        ),
      );
      await pumpRoute(tester, 450);

      await tester.tap(find.text('Add new location'));
      await pumpRoute(tester, 450);
      await tester.enterText(find.byType(TextField).at(1), '000000');
      await tester.tap(find.text('Save location'));
      await tester.pump();
      expect(find.text('Enter a valid 6-digit Indian pincode'), findsOneWidget);
      expect(state.locations.length, beforeLocationCount);
    },
  );

  testWidgets(
    'CheckoutScreen passes chosen payment method & deleteAccount wipes all state',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorageService();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final state = await SastaAppState.createAndLoad(
        storage: storage,
        syncIfConfigured: false,
      );
      state
        ..completeSplash()
        ..completeOnboarding()
        ..completePincode('560001', area: 'Bengaluru');
      addTearDown(() {
        state.dispose();
        tester.binding.setSurfaceSize(null);
      });

      // Fresh account has empty invoices (no phantom sample billing history).
      expect(state.invoices, isEmpty);

      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            onGenerateRoute: (settings) {
              if (settings.name == SastaRouteNames.plusSuccess) {
                final args = settings.arguments as CheckoutArgs?;
                return MaterialPageRoute(
                  builder: (_) => PaySuccessScreen(
                    planType: args?.planType ?? SastaPlanType.monthly,
                    paymentMethod: args?.paymentMethod ?? 'UPI',
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (_) =>
                    const CheckoutScreen(planType: SastaPlanType.monthly),
              );
            },
          ),
        ),
      );
      await pumpRoute(tester, 450);

      await tester.tap(find.text('Card'));
      await tester.pump();
      await tester.tap(find.text('Confirm & pay ₹49'));
      await pumpRoute(tester, 550);

      expect(find.text('You’re on Sasta+!'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(state.invoices.length, 1);
      expect(state.invoices.first.txnCode, contains('CARD'));

      // Check SubHistoryScreen renders the real Card invoice.
      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: const SubHistoryScreen(),
          ),
        ),
      );
      await pumpRoute(tester, 450);
      expect(find.text('Sasta+ Monthly'), findsOneWidget);

      // Delete account wipes state, billing history, and storage.
      await state.deleteAccount();
      expect(state.hasSeenOnboarding, isFalse);
      expect(state.hasSetPincode, isFalse);
      expect(state.invoices, isEmpty);
      expect(state.planType, SastaPlanType.free);
      expect(state.phoneVerified, isFalse);

      final reloaded = await SastaAppState.createAndLoad(
        storage: storage,
        syncIfConfigured: false,
      );
      addTearDown(reloaded.dispose);
      expect(reloaded.hasSeenOnboarding, isFalse);
      expect(reloaded.invoices, isEmpty);
    },
  );

  testWidgets(
    'Product image containers fill card, tile, and details hero bounds',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final state = onboardedState();
      addTearDown(state.dispose);
      final sample = state.products.first.copyWith(
        imageUrl: 'https://cdn.example.com/milk.png',
      );
      final networkImages = find.byWidgetPredicate(
        (w) => w is Image && w.image is NetworkImage,
      );

      await tester.pumpWidget(
        SastaScope(
          state: state,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: Scaffold(
              body: Column(
                children: [
                  ProductGridCard(width: 196, product: sample),
                  ProductArtTile(
                    kind: sample.artKind,
                    pastel: sample.pastel,
                    imageUrl: sample.imageUrl,
                    size: 96,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gridImageSize = tester.getSize(
        find.descendant(
          of: find.byType(ProductGridCard),
          matching: networkImages,
        ),
      );
      // 196 card - 24 horizontal padding = 172 width; full 106 showcase height.
      expect(gridImageSize.width, 172);
      expect(gridImageSize.height, 106);

      final tileImageSize = tester.getSize(
        find.descendant(
          of: find.byType(ProductArtTile),
          matching: networkImages,
        ),
      );
      // 96 tile - 2px hairline border = 94x94 edge-to-edge fill.
      expect(tileImageSize.width, 94);
      expect(tileImageSize.height, 94);

      // Verify ProductDetailsScreen hero image expands to the 204x204 card.
      final repo = HttpQuickCommerceRepository(
        config: _testQuickCommerceConfig,
        client: MockClient((request) async {
          if (request.url.path == '/v1/groupsearch') {
            return http.Response(
              jsonEncode({
                'status': 'success',
                'results': {
                  'Zepto': [
                    {
                      'id': 'z_milk_1',
                      'name': 'Aashirvaad Select Milk',
                      'brand': 'Aashirvaad',
                      'quantity': '500 ml',
                      'mrp': 31,
                      'offer_price': 22,
                      'available': true,
                      'deeplink': 'https://www.zepto.com/milk',
                      'images': ['https://cdn.example.com/select_milk.jpg'],
                      'platform': {'sla': '9 mins', 'open': true},
                    },
                  ],
                },
              }),
              200,
              headers: {'x-credits-remaining': '80'},
            );
          }
          return http.Response('{}', 404);
        }),
      );
      addTearDown(repo.dispose);
      final liveState = SastaAppState(repository: repo)
        ..completeSplash()
        ..completeOnboarding()
        ..completePincode('560102', area: 'HSR Layout');
      addTearDown(liveState.dispose);

      await liveState.searchProductsRemote('Aashirvaad Select Milk');
      final fetched = liveState.products.firstWhere(
        (p) => p.bestImageUrl != null,
      );

      await tester.pumpWidget(
        SastaScope(
          state: liveState,
          child: MaterialApp(
            theme: buildSastaTheme(Brightness.light),
            home: ProductDetailsScreen(
              args: ProductRouteArgs(productId: fetched.id),
            ),
          ),
        ),
      );
      await tester.pump();

      final detailsHeroImageSize = tester.getSize(networkImages.first);
      expect(detailsHeroImageSize.width, 204);
      expect(detailsHeroImageSize.height, 204);
    },
  );
}
