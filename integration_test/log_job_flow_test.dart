import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Log Job Flow — Checkpoint 2', () {
    testWidgets('logs a job and sees it in the list', (tester) async {
      // TODO
      // 1. Start at JobListScreen
      // 2. Tap FAB
      // 3. Select service type
      // 4. Enter customer name and phone
      // 5. Tap Save job
      // 6. Expect job appears in list
    });

    testWidgets('logs job offline and syncs when online', (tester) async {
      // TODO
      // 1. Set connectivity to offline
      // 2. Log a job
      // 3. Expect job saved locally with pending status
      // 4. Set connectivity to online
      // 5. Trigger sync
      // 6. Expect job status becomes synced
    });
  });
}
