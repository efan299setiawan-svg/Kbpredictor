import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/history_provider.dart';
import 'services/rules_provider.dart';
import 'services/settings_provider.dart';
import 'services/theme_provider.dart';
import 'screens/root_screen.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KbPredictorApp());
}

/// Root widget - wires up all app-wide Providers (state management) and
/// the Material 3 light/dark theme. The app is fully offline: no
/// networking package is imported anywhere in this project.
class KbPredictorApp extends StatelessWidget {
  const KbPredictorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => RulesProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'KB Predictor AI',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.mode,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const RootScreen(),
          );
        },
      ),
    );
  }
}
