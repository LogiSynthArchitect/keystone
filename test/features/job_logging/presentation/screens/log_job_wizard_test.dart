import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keystone/features/job_logging/presentation/screens/log_job_screen.dart';
import 'package:keystone/features/service_types/presentation/widgets/service_type_picker_v2.dart';
import 'package:keystone/features/service_types/presentation/providers/service_type_provider.dart';
import 'package:keystone/features/service_types/domain/entities/service_type_entity.dart';
import 'package:keystone/core/providers/supabase_provider.dart';
import 'package:keystone/core/theme/app_theme.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

// Subclass that bypasses real datasources and returns fixed test data.
class _TestServiceTypeNotifier extends ServiceTypeNotifier {
  _TestServiceTypeNotifier(super.ref) {
    state = AsyncValue.data([
      ServiceTypeEntity(
        id: 'st1',
        userId: 'u1',
        name: 'Safe Opening',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
    ]);
  }

  @override
  Future<void> loadServiceTypes() async {
    // no-op — data is set in constructor above
  }
}

void main() {
  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
        serviceTypeProvider.overrideWith((ref) => _TestServiceTypeNotifier(ref)),
      ],
      child: MaterialApp(
        theme: buildDarkAppTheme(),
        home: const LogJobScreen(),
      ),
    );
  }

  group('LogJobScreen Wizard Flow', () {
    testWidgets('starts on Step 1 (SERVICE) and Next is disabled initially', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify Step 1 heading
      expect(find.text('SERVICE TYPE'), findsOneWidget);

      // Verify "NEXT STEP" button is present but dimmed (alpha 0.3)
      final nextStepText = find.text('NEXT STEP');
      expect(nextStepText, findsOneWidget);

      final textWidget = tester.widget<Text>(nextStepText);
      expect(textWidget.style?.color?.a, lessThan(1.0));
    });

    testWidgets('enabling a service type enables the Next button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // allow providers to settle

      // Tap on the first service type chip rendered by the picker
      await tester.tap(find.byType(ServiceTypePickerV2));
      await tester.pump();

      // Verify button is now enabled (alpha 1.0)
      final nextStepText = find.text('NEXT STEP');
      final textWidget = tester.widget<Text>(nextStepText);
      expect(textWidget.style?.color?.a, equals(1.0));
    });
  });
}
