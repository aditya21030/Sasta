import 'package:flutter/material.dart';

import 'app/sasta_router.dart';
import 'data/sasta_app_state.dart';
import 'theme/sasta_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final loadedState = await SastaAppState.createAndLoad();
  runApp(SastaApp(stateOverride: loadedState));
}

/// Root widget for Sasta — Mehenga Kyun? Sasta Hai Na!
class SastaApp extends StatefulWidget {
  const SastaApp({super.key, this.stateOverride});

  /// Optional pre-seeded state instance for widget tests and previews.
  final SastaAppState? stateOverride;

  @override
  State<SastaApp> createState() => _SastaAppState();
}

class _SastaAppState extends State<SastaApp> {
  late final SastaAppState _state;
  late final bool _ownsState;

  @override
  void initState() {
    super.initState();
    _ownsState = widget.stateOverride == null;
    _state = widget.stateOverride ?? SastaAppState();
  }

  @override
  void dispose() {
    if (_ownsState) {
      _state.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SastaScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'Sasta',
            debugShowCheckedModeBanner: false,
            theme: buildSastaTheme(Brightness.light),
            darkTheme: buildSastaTheme(Brightness.dark),
            themeMode: _state.themeMode,
            onGenerateRoute: onGenerateSastaRoute,
            home: const SastaRootFlow(),
          );
        },
      ),
    );
  }
}
