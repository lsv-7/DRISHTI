import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/vulnerability_profile.dart';
import 'services/offline_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

import 'theme/drishti_theme.dart';

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
      theme: DrishtiTheme.lightTheme,
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
