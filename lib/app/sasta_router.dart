import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sasta_app_state.dart';
import '../models/models.dart';
import '../screens/basket/basket_screen.dart';
import '../screens/comparison/basket_compare_screen.dart';
import '../screens/help_legal/about_screen.dart';
import '../screens/help_legal/app_info_screen.dart';
import '../screens/help_legal/contact_support_screen.dart';
import '../screens/help_legal/faq_screen.dart';
import '../screens/help_legal/feedback_screen.dart';
import '../screens/help_legal/help_centre_screen.dart';
import '../screens/help_legal/legal_screens.dart';
import '../screens/home/categories_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/home_search_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/pincode_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/profile/appearance_screen.dart';
import '../screens/profile/comparison_prefs_screen.dart';
import '../screens/profile/locations_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../screens/profile/personal_info_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/saved_baskets_screen.dart';
import '../screens/profile/security_screen.dart';
import '../screens/sasta_plus/checkout_screen.dart';
import '../screens/sasta_plus/manage_membership_screen.dart';
import '../screens/sasta_plus/pay_success_screen.dart';
import '../screens/sasta_plus/plans_screen.dart';
import '../screens/sasta_plus/plus_landing_screen.dart';
import '../screens/sasta_plus/sub_history_screen.dart';
import '../screens/search_products/favourites_screen.dart';
import '../screens/search_products/notifications_screen.dart';
import '../screens/search_products/price_history_screen.dart';
import '../screens/search_products/product_compare_screen.dart';
import '../screens/search_products/product_details_screen.dart';
import '../screens/search_products/search_history_screen.dart';
import '../screens/search_products/search_results_screen.dart';
import '../theme/sasta_tokens.dart';
import '../widgets/sasta_background.dart';
import '../widgets/sasta_components.dart';
import 'sasta_routes.dart';

/// Root flow coordinating Splash -> Onboarding -> Pincode -> Main App Shell.
class SastaRootFlow extends StatelessWidget {
  const SastaRootFlow({super.key});

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final Widget child;
    if (!state.hasCompletedSplash) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!state.hasSeenOnboarding) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else if (!state.hasSetPincode) {
      child = const PincodeScreen(key: ValueKey('pincode'));
    } else {
      child = const SastaShell(key: ValueKey('shell'));
    }

    return AnimatedSwitcher(
      duration: disabled ? Duration.zero : SastaMotion.fadeUp,
      switchInCurve: SastaMotion.curve,
      switchOutCurve: SastaMotion.curve,
      child: child,
    );
  }
}

/// Persistent 4-tab shell holding Home, Basket, Saved, and Profile with floating nav.
class SastaShell extends StatefulWidget {
  const SastaShell({super.key});

  @override
  State<SastaShell> createState() => _SastaShellState();
}

class _SastaShellState extends State<SastaShell> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final state = SastaScope.of(context);
    final activeIndex = state.activeTabIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (activeIndex != 0) {
          state.setActiveTab(0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressed != null &&
            now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressed = now;
        showSastaToast(context, 'Press back again to exit Sasta');
      },
      child: Scaffold(
        body: SastaBackground(
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                IndexedStack(
                  index: activeIndex,
                  children: const [
                    HomeScreen(),
                    BasketScreen(),
                    FavouritesScreen(isTabRoot: true),
                    ProfileScreen(),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SastaBottomNav(
                    activeIndex: activeIndex,
                    onSelect: state.setActiveTab,
                    basketCount: state.activeBasket.uniqueProducts,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Route<dynamic> onGenerateSastaRoute(RouteSettings settings) {
  final Widget page = switch (settings.name) {
    SastaRouteNames.homeSearch => const HomeSearchScreen(),
    SastaRouteNames.categories => const CategoriesScreen(),
    SastaRouteNames.searchResults => SearchResultsScreen(
        args: settings.arguments as SearchResultsArgs?,
      ),
    SastaRouteNames.productCompare => ProductCompareScreen(
        args: settings.arguments as ProductRouteArgs?,
      ),
    SastaRouteNames.productDetails => ProductDetailsScreen(
        args: settings.arguments as ProductRouteArgs?,
      ),
    SastaRouteNames.priceHistory => PriceHistoryScreen(
        args: settings.arguments as ProductRouteArgs?,
      ),
    SastaRouteNames.searchHistory => const SearchHistoryScreen(),
    SastaRouteNames.notifications => const NotificationsScreen(),
    SastaRouteNames.basketCompare => BasketCompareScreen(
        args: settings.arguments as BasketCompareArgs?,
      ),
    SastaRouteNames.favouritesPush => const FavouritesScreen(isTabRoot: false),
    SastaRouteNames.personalInfo => const PersonalInfoScreen(),
    SastaRouteNames.locations => const LocationsScreen(),
    SastaRouteNames.security => const SecurityScreen(),
    SastaRouteNames.savedBaskets => const SavedBasketsScreen(),
    SastaRouteNames.comparisonPrefs => const ComparisonPrefsScreen(),
    SastaRouteNames.appearance => const AppearanceScreen(),
    SastaRouteNames.notificationSettings => const NotificationSettingsScreen(),
    SastaRouteNames.pincodePicker => const PincodeScreen(isModalPicker: true),
    SastaRouteNames.plusLanding => const PlusLandingScreen(),
    SastaRouteNames.plusPlans => PlansScreen(
        initialPlan: (settings.arguments as CheckoutArgs?)?.planType ??
            SastaPlanType.yearly,
      ),
    SastaRouteNames.plusCheckout => CheckoutScreen(
        planType: (settings.arguments as CheckoutArgs?)?.planType ??
            SastaPlanType.yearly,
      ),
    SastaRouteNames.plusSuccess => PaySuccessScreen(
        planType: (settings.arguments as CheckoutArgs?)?.planType ??
            SastaPlanType.yearly,
      ),
    SastaRouteNames.plusManage => const ManageMembershipScreen(),
    SastaRouteNames.plusHistory => const SubHistoryScreen(),
    SastaRouteNames.helpCentre => const HelpCentreScreen(),
    SastaRouteNames.faq => FaqScreen(
        initialCategory: settings.arguments as String?,
      ),
    SastaRouteNames.contactSupport => const ContactSupportScreen(),
    SastaRouteNames.sendFeedback => const FeedbackScreen(),
    SastaRouteNames.about => const AboutScreen(),
    SastaRouteNames.appInfo => const AppInfoScreen(),
    SastaRouteNames.privacy => const PrivacyScreen(),
    SastaRouteNames.terms => const TermsScreen(),
    _ => const SastaRootFlow(),
  };

  return PageRouteBuilder<dynamic>(
    settings: settings,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: SastaMotion.curve,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
