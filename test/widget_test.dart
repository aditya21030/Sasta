import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

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
import 'package:sasta/screens/profile/profile_screen.dart';
import 'package:sasta/screens/sasta_plus/plus_landing_screen.dart';
import 'package:sasta/services/local_storage_service.dart';
import 'package:sasta/services/pincode_location_service.dart';
import 'package:sasta/services/quick_commerce_api.dart';
import 'package:sasta/services/retailer_launcher_service.dart';
import 'package:sasta/services/share_service.dart';

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
}
