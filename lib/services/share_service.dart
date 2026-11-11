import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

typedef ShareDelegate = Future<void> Function(String text, {String? subject});
typedef WhatsAppLaunchDelegate = Future<bool> Function(Uri uri);

/// Handles OS share sheet, WhatsApp deep sharing, and clipboard fallback cleanly.
class SastaShareService {
  SastaShareService({
    ShareDelegate? shareDelegate,
    WhatsAppLaunchDelegate? whatsAppDelegate,
  })  : _shareDelegate = shareDelegate,
        _whatsAppDelegate = whatsAppDelegate;

  final ShareDelegate? _shareDelegate;
  final WhatsAppLaunchDelegate? _whatsAppDelegate;

  /// Invokes the OS share sheet and copies text to clipboard if no share target exists.
  Future<bool> shareText(String text, {String? subject}) async {
    try {
      if (_shareDelegate != null) {
        await _shareDelegate(text, subject: subject);
        return true;
      }
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
        ),
      );
      return true;
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return false;
    }
  }

  /// Opens WhatsApp share URI (`wa.me`), falling back to OS share sheet or clipboard.
  Future<bool> shareToWhatsApp(String text, {String? subject}) async {
    final uri = Uri.https('wa.me', '/', {'text': text});
    try {
      final launched = _whatsAppDelegate != null
          ? await _whatsAppDelegate(uri)
          : await launcher.launchUrl(
              uri,
              mode: launcher.LaunchMode.externalApplication,
            );
      if (launched) return true;
    } on MissingPluginException {
      // Fall through to OS share / clipboard.
    } catch (_) {
      // Fall through to OS share / clipboard.
    }
    return shareText(text, subject: subject);
  }
}
