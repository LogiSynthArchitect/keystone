import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Sync Flow — Checkpoint 2', () {
    testWidgets('data saved offline is never lost', (tester) async {
      // TODO
      // 1. Turn off connectivity
      // 2. Log 3 jobs
      // 3. Verify all 3 appear in list with pending badge
      // 4. Turn on connectivity
      // 5. Pull to refresh
      // 6. Verify all 3 show synced status
    });

    testWidgets('customer created offline syncs correctly', (tester) async {
      // TODO
      // 1. Turn off connectivity
      // 2. Add a new customer
      // 3. Verify customer appears in list
      // 4. Turn on connectivity
      // 5. Verify customer syncs to Supabase
    });
  });
}
