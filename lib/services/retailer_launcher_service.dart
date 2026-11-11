import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../models/models.dart';

/// Result of handing off a product or basket search to a quick-commerce retailer.
class RetailerLaunchOutcome {
  const RetailerLaunchOutcome({
    required this.launched,
    required this.openedNativeApp,
    required this.targetUri,
  });

  final bool launched;
  final bool openedNativeApp;
  final Uri targetUri;
}

typedef UriLauncherDelegate = Future<bool> Function(
  Uri uri, {
  launcher.LaunchMode mode,
});
typedef CanLaunchDelegate = Future<bool> Function(Uri uri);

/// Opens Blinkit, Zepto, Swiggy Instamart, Flipkart Minutes, or mail links cleanly.
class RetailerLauncherService {
  RetailerLauncherService({
    UriLauncherDelegate? launchUrlDelegate,
    CanLaunchDelegate? canLaunchDelegate,
  })  : _launchUrlDelegate = launchUrlDelegate,
        _canLaunchDelegate = canLaunchDelegate;

  final UriLauncherDelegate? _launchUrlDelegate;
  final CanLaunchDelegate? _canLaunchDelegate;

  /// Builds the native app URI scheme for a retailer (used when the app is installed).
  static Uri buildNativeUri(RetailerId retailer, {String? query}) {
    final trimmed = query?.trim() ?? '';
    switch (retailer) {
      case RetailerId.blinkit:
        return trimmed.isEmpty
            ? Uri.parse(retailer.schemeUrl)
            : Uri(scheme: 'blinkit', host: 'search', queryParameters: {'q': trimmed});
      case RetailerId.zepto:
        return trimmed.isEmpty
            ? Uri.parse(retailer.schemeUrl)
            : Uri(scheme: 'zepto', host: 'search', queryParameters: {'q': trimmed});
      case RetailerId.instamart:
        return trimmed.isEmpty
            ? Uri.parse(retailer.schemeUrl)
            : Uri(
                scheme: 'swiggy',
                host: 'instamart',
                path: '/search',
                queryParameters: {'query': trimmed},
              );
      case RetailerId.flipkartMinutes:
        return Uri.parse(retailer.schemeUrl);
    }
  }

  /// Builds the official HTTPS search URL fallback for a retailer.
  static Uri buildWebUri(RetailerId retailer, {String? query}) {
    final trimmed = query?.trim() ?? '';
    switch (retailer) {
      case RetailerId.blinkit:
        return trimmed.isEmpty
            ? Uri.https('blinkit.com', '/')
            : Uri.https('blinkit.com', '/s/', {'q': trimmed});
      case RetailerId.zepto:
        return trimmed.isEmpty
            ? Uri.https('www.zeptonow.com', '/')
            : Uri.https('www.zeptonow.com', '/search', {'query': trimmed});
      case RetailerId.instamart:
        return trimmed.isEmpty
            ? Uri.https('www.swiggy.com', '/instamart')
            : Uri.https('www.swiggy.com', '/instamart/search', {
                'custom_back': 'true',
                'query': trimmed,
              });
      case RetailerId.flipkartMinutes:
        return trimmed.isEmpty
            ? Uri.https('www.flipkart.com', '/flipkart-minutes-store')
            : Uri.https('www.flipkart.com', '/search', {
                'q': trimmed,
                'marketplace': 'HYPERLOCAL',
              });
    }
  }

  /// Launches the installed retailer app via URI scheme, falling back to its web store URL.
  Future<RetailerLaunchOutcome> openRetailer(
    RetailerId retailer, {
    String? query,
  }) async {
    final nativeUri = buildNativeUri(retailer, query: query);
    final webUri = buildWebUri(retailer, query: query);

    try {
      final canNative = await _canLaunch(nativeUri);
      if (canNative) {
        final ok = await _launch(
          nativeUri,
          mode: launcher.LaunchMode.externalApplication,
        );
        if (ok) {
          return RetailerLaunchOutcome(
            launched: true,
            openedNativeApp: true,
            targetUri: nativeUri,
          );
        }
      }
      final okWeb = await _launch(
        webUri,
        mode: launcher.LaunchMode.externalApplication,
      );
      return RetailerLaunchOutcome(
        launched: okWeb,
        openedNativeApp: false,
        targetUri: webUri,
      );
    } on MissingPluginException {
      return RetailerLaunchOutcome(
        launched: false,
        openedNativeApp: false,
        targetUri: webUri,
      );
    } catch (_) {
      return RetailerLaunchOutcome(
        launched: false,
        openedNativeApp: false,
        targetUri: webUri,
      );
    }
  }

  /// Opens a pre-populated email composer for customer support or feedback.
  Future<bool> openSupportEmail({
    required String subject,
    required String body,
    String to = 'support@sastaapp.in',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    try {
      return await _launch(uri, mode: launcher.LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _canLaunch(Uri uri) {
    if (_canLaunchDelegate != null) return _canLaunchDelegate(uri);
    return launcher.canLaunchUrl(uri);
  }

  Future<bool> _launch(
    Uri uri, {
    launcher.LaunchMode mode = launcher.LaunchMode.externalApplication,
  }) {
    if (_launchUrlDelegate != null) return _launchUrlDelegate(uri, mode: mode);
    return launcher.launchUrl(uri, mode: mode);
  }
}
