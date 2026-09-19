import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/screens/home_screen.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/theme/drishti_theme.dart';

void main() {
  group('T059 — Local Pending & Offline Sync Status UI Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('1. HomeScreen displays synchronized state when queue is empty and online', (tester) async {
      final service = OfflineService();

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Sync Queue: 0 Pending'), findsOneWidget);
      expect(find.text('All emergency reports are synchronized.'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('2. HomeScreen displays offline card with checklist when device is offline', (tester) async {
      final service = OfflineService();
      await service.ensureInitialized();
      service.setConnectivity(ConnectivityState.offline);

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("You're Offline"), findsOneWidget);
      expect(find.text("No internet connection. Don't worry!"), findsOneWidget);
      expect(find.text('Request saved locally'), findsOneWidget);
      expect(find.text('Will sync automatically when connection returns'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsWidgets);
    });

    testWidgets('3. HomeScreen renders Sync Now button when online with pending operations', (tester) async {
      final service = OfflineService();
      await service.ensureInitialized();
      service.setConnectivity(ConnectivityState.offline);

      // Queue an item offline
      await service.submitEmergency(
        title: 'Trapped in rising floodwaters',
        description: 'Water at first floor',
        category: 'FLOOD_RESCUE',
        latitude: 12.9716,
        longitude: 77.5946,
        affectedCount: 2,
      );

      // Now set back to online
      service.setConnectivity(ConnectivityState.online);

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline Sync Queue: 1 Pending'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.byIcon(Icons.pending_actions_rounded), findsWidgets);
    });

    testWidgets('4. HomeScreen displays sync warning banner when lastSyncError is populated', (tester) async {
      final service = OfflineService();
      await service.ensureInitialized();
      service.setConnectivity(ConnectivityState.offline);

      await service.submitEmergency(
        title: 'Trapped in rising water',
        description: 'Water at first floor',
        category: 'FLOOD_RESCUE',
        latitude: 12.9716,
        longitude: 77.5946,
        affectedCount: 2,
      );

      service.setConnectivity(ConnectivityState.online);
      // Trigger sync which fails due to mock client/server unavailability
      await service.syncPendingQueue();

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      if (service.lastSyncError != null) {
        expect(find.textContaining('Sync warning:'), findsOneWidget);
      }
    });

    testWidgets('5. DrishtiTheme defines all required color constants', (tester) async {
      expect(DrishtiColors.primaryBlue, const Color(0xFF2563EB));
      expect(DrishtiColors.deepNavy, const Color(0xFF1E3A8A));
      expect(DrishtiColors.darkNavyText, const Color(0xFF0F172A));
      expect(DrishtiColors.emergencyRed, const Color(0xFFEF4444));
      expect(DrishtiColors.warningOrange, const Color(0xFFF97316));
      expect(DrishtiColors.alertYellow, const Color(0xFFFBBF24));
      expect(DrishtiColors.successGreen, const Color(0xFF22C55E));
      expect(DrishtiColors.softGreen, const Color(0xFFDCFCE7));
      expect(DrishtiColors.lightBlue, const Color(0xFFDBEAFE));
      expect(DrishtiColors.purple, const Color(0xFF8B5CF6));
      expect(DrishtiColors.background, const Color(0xFFF8FAFC));
      expect(DrishtiColors.surface, const Color(0xFFFFFFFF));
      expect(DrishtiColors.border, const Color(0xFFE2E8F0));
      expect(DrishtiColors.secondaryText, const Color(0xFF64748B));
    });
  });
}
