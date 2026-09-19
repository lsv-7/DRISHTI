import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:disaster_response_flutter/main.dart';
import 'package:disaster_response_flutter/services/offline_service.dart';
import 'package:disaster_response_flutter/repositories/local_emergency_repository.dart';

void main() {
  testWidgets('DrishtiApp initial widget tree builds cleanly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalEmergencyRepository.inMemory();
    final offlineService = OfflineService(repository: repository);
    await offlineService.ensureInitialized();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        ],
        child: const DrishtiApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(DrishtiApp), findsOneWidget);

    offlineService.dispose();
    await repository.database.close();
  });
}
