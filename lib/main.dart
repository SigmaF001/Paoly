import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_settings.dart';
import 'data/finance_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/session_app.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://mdmbgilrssqypanvnddp.supabase.co',
    );
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_gHFKsCoknYzB0WhtdDWmaw_wRvE7M_8',
    );
    SupabaseClient? client;
    if (url.isNotEmpty && key.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, publishableKey: key);
        client = Supabase.instance.client;
      } catch (_) {
        // Optional authentication must not prevent using the guest notebook.
      }
    }

    // Set UI style early but safely
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(SessionApp(client: client));
  } catch (e, stack) {
    developer.log('Fatal startup error', error: e, stackTrace: stack);
    // Even if it fails, try to show something or let it crash gracefully
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Startup Error: $e'))),
      ),
    );
  }
}

class PaolyApp extends StatefulWidget {
  final AppSettings settings;
  final FinanceData data;
  const PaolyApp({super.key, required this.settings, required this.data});

  @override
  State<PaolyApp> createState() => _PaolyAppState();
}

class _PaolyAppState extends State<PaolyApp> {
  late final ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _theme = AppTheme.theme;
    widget.settings.addListener(_onSettingsChanged);

    // Do not lock orientation: the app adapts its layout for phones, tablets,
    // and desktop windows in either orientation.
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paoly',
      debugShowCheckedModeBanner: false,
      theme: _theme,
      locale: Locale(widget.settings.langCode),
      supportedLocales: const [Locale('th'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: widget.settings.isFirstLaunch
          ? OnboardingScreen(settings: widget.settings)
          : DashboardScreen(data: widget.data, settings: widget.settings),
    );
  }
}
