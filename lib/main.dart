import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data/app_settings.dart';
import 'data/finance_data.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final settings = AppSettings();
  await settings.load();
  final data = FinanceData();
  data.seedDefaultAccount();

  runApp(PaolyApp(settings: settings, data: data));
}

class PaolyApp extends StatefulWidget {
  final AppSettings settings;
  final FinanceData data;
  const PaolyApp({super.key, required this.settings, required this.data});

  @override
  State<PaolyApp> createState() => _PaolyAppState();
}

class _PaolyAppState extends State<PaolyApp> {
  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
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
      theme: AppTheme.theme,
      locale: Locale(widget.settings.langCode),
      home: widget.settings.isFirstLaunch
          ? OnboardingScreen(settings: widget.settings)
          : DashboardScreen(data: widget.data, settings: widget.settings),
    );
  }
}
