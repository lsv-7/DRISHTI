import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:disaster_response_flutter/models/citizen_profile.dart';
import 'package:disaster_response_flutter/models/vulnerability_profile.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/screens/onboarding_screen.dart';
import 'package:disaster_response_flutter/screens/profile_screen.dart';
import 'package:disaster_response_flutter/screens/home_screen.dart';
import 'package:disaster_response_flutter/theme/drishti_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6: Citizen Basic Details & Profile Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. Model: CitizenProfile serialization and deserialization', () {
      const profile = CitizenProfile(
        fullName: 'Ravi Kumar',
        phoneNumber: '+91 9876543210',
        email: 'ravi.kumar@example.com',
        age: 32,
        gender: 'Male',
        address: 'Flat 4B, Coastal Heights',
        city: 'Vijayawada',
        emergencyContactName: 'Lakshmi Kumar',
        emergencyContactPhone: '+91 9123456780',
        status: CitizenProfileStatus.complete,
      );

      final jsonMap = profile.toJson();
      expect(jsonMap['full_name'], 'Ravi Kumar');
      expect(jsonMap['phone'], '+91 9876543210');
      expect(jsonMap['email'], 'ravi.kumar@example.com');
      expect(jsonMap['age'], 32);
      expect(jsonMap['gender'], 'Male');
      expect(jsonMap['address'], 'Flat 4B, Coastal Heights');
      expect(jsonMap['city'], 'Vijayawada');
      expect(jsonMap['emergency_contact_name'], 'Lakshmi Kumar');
      expect(jsonMap['emergency_contact_phone'], '+91 9123456780');

      final deserialized = CitizenProfile.fromJson(jsonMap);
      expect(deserialized.fullName, 'Ravi Kumar');
      expect(deserialized.phoneNumber, '+91 9876543210');
      expect(deserialized.email, 'ravi.kumar@example.com');
      expect(deserialized.city, 'Vijayawada');
      expect(deserialized.emergencyContactName, 'Lakshmi Kumar');
      expect(deserialized.emergencyContactPhone, '+91 9123456780');
      expect(deserialized.isComplete, isTrue);
    });

    test('2. Model: Persistence JSON includes status and roundtrips accurately', () {
      const profile = CitizenProfile(
        fullName: 'Sunita Rao',
        phoneNumber: '9876543210',
        city: 'Guntur',
        status: CitizenProfileStatus.complete,
      );

      final persistenceJson = profile.toPersistenceJson();
      expect(persistenceJson['status'], 'complete');
      expect(persistenceJson['full_name'], 'Sunita Rao');

      final restored = CitizenProfile.fromJson(persistenceJson);
      expect(restored.fullName, 'Sunita Rao');
      expect(restored.phoneNumber, '9876543210');
      expect(restored.city, 'Guntur');
      expect(restored.status, CitizenProfileStatus.complete);
      expect(restored.isComplete, isTrue);
    });

    test('3. Validation: Full name constraints (2 to 100 chars, non-empty)', () {
      expect(CitizenProfile.validateFullName(''), isNotNull);
      expect(CitizenProfile.validateFullName('   '), isNotNull);
      expect(CitizenProfile.validateFullName('A'), isNotNull);
      expect(CitizenProfile.validateFullName('A' * 101), isNotNull);

      expect(CitizenProfile.validateFullName('Al'), isNull);
      expect(CitizenProfile.validateFullName('Ravi Kumar'), isNull);
      expect(CitizenProfile.validateFullName('A' * 100), isNull);
    });

    test('4. Validation: Phone number constraints (8 to 15 digits)', () {
      expect(CitizenProfile.validatePhoneNumber(''), isNotNull);
      expect(CitizenProfile.validatePhoneNumber('1234567'), isNotNull); // 7 digits
      expect(CitizenProfile.validatePhoneNumber('1234567890123456'), isNotNull); // 16 digits
      expect(CitizenProfile.validatePhoneNumber('not-a-number'), isNotNull);

      expect(CitizenProfile.validatePhoneNumber('12345678'), isNull); // 8 digits
      expect(CitizenProfile.validatePhoneNumber('9876543210'), isNull); // 10 digits
      expect(CitizenProfile.validatePhoneNumber('+91 9876543210'), isNull); // 12 digits
      expect(CitizenProfile.validatePhoneNumber('123456789012345'), isNull); // 15 digits
    });

    test('5. Validation: Email constraints (optional, valid format if present)', () {
      expect(CitizenProfile.validateEmail(null), isNull);
      expect(CitizenProfile.validateEmail(''), isNull);
      expect(CitizenProfile.validateEmail('   '), isNull);

      expect(CitizenProfile.validateEmail('plainaddress'), isNotNull);
      expect(CitizenProfile.validateEmail('@missingusername.com'), isNotNull);
      expect(CitizenProfile.validateEmail('user@.com'), isNotNull);

      expect(CitizenProfile.validateEmail('user@example.com'), isNull);
      expect(CitizenProfile.validateEmail('first.last@sub.domain.org'), isNull);
    });

    test('6. Validation: Emergency contact phone constraints (optional)', () {
      expect(CitizenProfile.validateEmergencyPhone(null), isNull);
      expect(CitizenProfile.validateEmergencyPhone(''), isNull);

      expect(CitizenProfile.validateEmergencyPhone('123'), isNotNull);
      expect(CitizenProfile.validateEmergencyPhone('9876543210'), isNull);
      expect(CitizenProfile.validateEmergencyPhone('+91 9876543210'), isNull);
    });

    test('7. Distinction: Basic Profile vs Vulnerability Profile completion states', () {
      // Basic profile complete, vulnerability not completed
      const basicOnly = CitizenProfile(
        fullName: 'Citizen One',
        phoneNumber: '9876543210',
        status: CitizenProfileStatus.complete,
      );
      expect(basicOnly.isComplete, isTrue);

      // Incomplete basic profile
      final incomplete = CitizenProfile.empty();
      expect(incomplete.isComplete, isFalse);

      // Default profile
      final def = CitizenProfile.defaultProfile();
      expect(def.isComplete, isTrue);
      expect(def.fullName, 'Citizen User');
    });

    test('8. OfflineService: Persistence across simulated app restarts', () async {
      final initialService = OfflineService();
      await initialService.ensureInitialized();

      const profile = CitizenProfile(
        fullName: 'Ananya Verma',
        phoneNumber: '+91 9876500000',
        email: 'ananya@example.com',
        city: 'Tirupati',
        emergencyContactName: 'Rajesh Verma',
        emergencyContactPhone: '+91 9876511111',
        status: CitizenProfileStatus.complete,
      );

      await initialService.saveCitizenProfile(profile);

      expect(initialService.citizenProfile.fullName, 'Ananya Verma');
      expect(initialService.citizenProfile.phoneNumber, '+91 9876500000');
      expect(initialService.citizenProfile.city, 'Tirupati');
      expect(initialService.isBasicProfileComplete, isTrue);

      // Simulate app restart by creating a new OfflineService instance
      final restartedService = OfflineService();
      await restartedService.ensureInitialized();

      expect(restartedService.citizenProfile.fullName, 'Ananya Verma');
      expect(restartedService.citizenProfile.phoneNumber, '+91 9876500000');
      expect(restartedService.citizenProfile.city, 'Tirupati');
      expect(restartedService.citizenProfile.emergencyContactName, 'Rajesh Verma');
      expect(restartedService.isBasicProfileComplete, isTrue);
    });

    test('9. Emergency Submission: Reporter details at top level, strictly isolated from vulnerability snapshot', () async {
      final service = OfflineService();
      await service.ensureInitialized();
      service.setConnectivity(ConnectivityState.offline);

      // Configure citizen profile
      await service.saveCitizenProfile(const CitizenProfile(
        fullName: 'Dr. Suresh Babu',
        phoneNumber: '+91 9440012345',
        city: 'Kakinada',
        status: CitizenProfileStatus.complete,
      ));

      // Configure vulnerability profile
      await service.saveVulnerabilityProfile(const VulnerabilityProfile(
        age: 58,
        ageGroup: 'ADULT',
        canSwim: true,
        mobilityStatus: 'FULL',
        medicalConditions: ['Hypertension'],
        status: ProfileStatus.completed,
      ));

      // Submit emergency
      final submission = await service.submitEmergency(
        title: 'Flash Flood Rescue',
        description: 'Water surrounding house',
        category: 'FLOOD_RESCUE',
        latitude: 16.98,
        longitude: 82.24,
        affectedCount: 2,
      );
      final emergency = (submission['item'] ?? submission) as Map<String, dynamic>;

      // 1. Reporter identity MUST be at top level
      expect(emergency['reporter_name'], 'Dr. Suresh Babu');
      expect(emergency['contact_phone'], '+91 9440012345');

      // 2. Vulnerability snapshot MUST be strictly isolated
      final snapshot = emergency['vulnerability_snapshot'] as Map<String, dynamic>;
      expect(snapshot.containsKey('reporter_name'), isFalse);
      expect(snapshot.containsKey('contact_phone'), isFalse);
      expect(snapshot.containsKey('full_name'), isFalse);
      expect(snapshot['age'], 58);
      expect(snapshot['medical_conditions'], ['Hypertension']);

      // 3. Snapshot Immutability: Editing citizen profile afterward does NOT affect active emergency snapshot
      await service.saveCitizenProfile(const CitizenProfile(
        fullName: 'Updated Name After Emergency',
        phoneNumber: '+91 9999999999',
        status: CitizenProfileStatus.complete,
      ));

      expect(service.activeEmergency!['reporter_name'], 'Dr. Suresh Babu');
      final activeSnapshot = service.activeEmergency!['vulnerability_snapshot'] as Map<String, dynamic>;
      expect(activeSnapshot['age'], 58);
      expect(activeSnapshot.containsKey('reporter_name'), isFalse);
    });

    test('10. Background Sync: PUT /api/v1/profile/{user_id} when online', () async {
      var syncedPayload = '';
      var requestMethod = '';
      var requestUrl = '';

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/v1/profile/')) {
          requestMethod = request.method;
          requestUrl = request.url.path;
          syncedPayload = request.body;
          return http.Response(
            jsonEncode({
              'id': 'usr_citizen_local',
              'full_name': 'Meena Devi',
              'phone': '9876543210',
              'city': 'Ongole',
              'created_at': DateTime.now().toIso8601String(),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final service = OfflineService();
      await service.ensureInitialized();
      service.setConnectivity(ConnectivityState.online);

      const profile = CitizenProfile(
        fullName: 'Meena Devi',
        phoneNumber: '9876543210',
        city: 'Ongole',
        status: CitizenProfileStatus.complete,
      );

      await service.saveCitizenProfile(profile, client: mockClient);

      expect(requestMethod, 'PUT');
      expect(requestUrl, contains('/profile/'));
      final decodedBody = jsonDecode(syncedPayload) as Map<String, dynamic>;
      expect(decodedBody['full_name'], 'Meena Devi');
      expect(decodedBody['phone'], '9876543210');
      expect(decodedBody['city'], 'Ongole');
    });

    testWidgets('11. UI: OnboardingScreen Step 1 validates required citizen details', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = OfflineService();
      await service.ensureInitialized();

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1 title must be visible
      expect(find.text('Citizen Details'), findsOneWidget);
      expect(find.text('Step 1: Citizen Identification'), findsOneWidget);

      // Attempt to tap Continue without entering details
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue to Vulnerability Setup');
      expect(continueButton, findsOneWidget);
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Inline validation errors should appear
      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Phone number is required.'), findsOneWidget);
    });

    testWidgets('12. UI: OnboardingScreen transitions from Step 1 to Step 2 upon valid input', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = OfflineService();
      await service.ensureInitialized();

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in Name and Phone
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Manoj Reddy');
      await tester.enterText(textFields.at(1), '9876543210');
      await tester.pumpAndSettle();

      // Tap Continue
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue to Vulnerability Setup');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Should now be on Step 2
      expect(find.text('Step 2: Vulnerability Profile'), findsOneWidget);
      expect(find.text('Operational Priority Heuristic Notice'), findsOneWidget);
    });

    testWidgets('13. UI: OnboardingScreen skip vulnerability retains complete citizen profile', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = OfflineService();
      await service.ensureInitialized();

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in citizen details on Step 1
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Kavitha Patel');
      await tester.enterText(textFields.at(1), '9123456789');
      await tester.enterText(textFields.at(3), 'Nellore');
      await tester.pumpAndSettle();

      // Go to Step 2
      final continueButton = find.widgetWithText(ElevatedButton, 'Continue to Vulnerability Setup');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      // Tap Skip
      final skipButton = find.widgetWithText(OutlinedButton, 'Skip Vulnerability Info (Save Basic Details Only)');
      expect(skipButton, findsOneWidget);
      await tester.ensureVisible(skipButton);
      await tester.tap(skipButton);
      await tester.pumpAndSettle();

      // Verify citizen profile has complete status and data
      expect(service.citizenProfile.fullName, 'Kavitha Patel');
      expect(service.citizenProfile.phoneNumber, '9123456789');
      expect(service.citizenProfile.city, 'Nellore');
      expect(service.isBasicProfileComplete, isTrue);

      // Vulnerability profile should be default
      expect(service.vulnerabilityProfile.status, ProfileStatus.defaultProfile);
      expect(service.hasCompletedOnboarding, isTrue);
    });

    testWidgets('14. UI: ProfileScreen renders distinct Citizen and Vulnerability sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final service = OfflineService();
      await service.ensureInitialized();

      await service.saveCitizenProfile(const CitizenProfile(
        fullName: 'Venkat Rao',
        phoneNumber: '9876543210',
        email: 'venkat@example.com',
        city: 'Visakhapatnam',
        emergencyContactName: 'Padma Rao',
        emergencyContactPhone: '9876543211',
        status: CitizenProfileStatus.complete,
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify sections are clearly displayed
      expect(find.text('My Citizen Profile'), findsOneWidget);
      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Location & Personal Details'), findsOneWidget);
      expect(find.text('Emergency Contact'), findsOneWidget);
      expect(find.text('Vulnerability Profile'), findsOneWidget);
      expect(find.text('Operational Priority Heuristic Notice'), findsOneWidget);

      // Verify prefilled values
      expect(find.text('Venkat Rao'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('venkat@example.com'), findsOneWidget);
      expect(find.text('Visakhapatnam'), findsOneWidget);
      expect(find.text('Padma Rao'), findsOneWidget);
    });

    testWidgets('15. UI: HomeScreen renders personalized greeting and citizen info card', (tester) async {
      final service = OfflineService();
      await service.ensureInitialized();

      await service.saveCitizenProfile(const CitizenProfile(
        fullName: 'Deepika Nair',
        phoneNumber: '9876543210',
        city: 'Kurnool',
        status: CitizenProfileStatus.complete,
      ));

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

      // Top bar greeting
      expect(find.text('Hi, Deepika'), findsOneWidget);

      // Citizen details in card
      expect(find.text('Deepika Nair'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('Kurnool'), findsOneWidget);
    });

    testWidgets('16. UI: ProfileScreen saves updated details and calls OfflineService', (tester) async {
      final service = OfflineService();
      await service.ensureInitialized();

      await service.saveCitizenProfile(const CitizenProfile(
        fullName: 'Initial Name',
        phoneNumber: '9876543210',
        city: 'Initial City',
        status: CitizenProfileStatus.complete,
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: service,
          child: MaterialApp(
            theme: DrishtiTheme.lightTheme,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Edit full name
      final nameField = find.widgetWithText(TextField, 'Initial Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Updated Full Name');
      await tester.pumpAndSettle();

      // Tap Save Profile Changes button
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Profile Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(service.citizenProfile.fullName, 'Updated Full Name');
    });
  });
}
