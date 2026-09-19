import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/vulnerability_profile.dart';
import 'services/offline_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OfflineService()),
      ],
      child: const DrishtiApp(),
    ),
  );
}

class DrishtiApp extends StatelessWidget {
  const DrishtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DRISHTI AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: const Color(0xFFEF4444), // Emergency Red
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          secondary: Color(0xFF3B82F6), // Accent Blue
          surface: Color(0xFF1E293B), // Slate 800
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E293B),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        useMaterial3: true,
      ),
      home: const RootGate(),
    );
  }
}

/// RootGate routes users to OnboardingScreen on first launch (when profile is notCompleted),
/// or to HomeScreen once onboarding is completed/skipped.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineService = Provider.of<OfflineService>(context);

    // If profile is not completed, route to onboarding flow (T042)
    if (offlineService.profileStatus == ProfileStatus.notCompleted) {
      return const OnboardingScreen();
    }

    return const HomeScreen();
  }
}
