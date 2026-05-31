import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_settings.dart';
import 'data/finance_data.dart';
import 'data/pet_data.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'dart:developer' as developer;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    final settings = AppSettings();
    final data = FinanceData();

    // Load essential data
    await settings.load();
    await PetData.instance.load();
    data.seedDefaultAccount();

    // Set UI style early but safely
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    runApp(PaolyApp(settings: settings, data: data));
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

    // Defer orientation locking to ensure engine is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    });
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
      home: widget.settings.isFirstLaunch
          ? OnboardingScreen(settings: widget.settings)
          : DashboardScreen(data: widget.data, settings: widget.settings),
    );
  }
}
