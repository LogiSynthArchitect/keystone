import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/features/job_logging/presentation/widgets/service_picker_dropdown.dart';
import 'package:keystone/features/service_types/presentation/providers/service_type_provider.dart';
import 'package:keystone/features/service_types/domain/entities/service_type_entity.dart';
import 'package:keystone/core/providers/supabase_provider.dart';
import 'package:keystone/core/theme/app_theme.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class _TestServiceTypeNotifier extends ServiceTypeNotifier {
  _TestServiceTypeNotifier(super.ref) {
    state = AsyncValue.data([
      ServiceTypeEntity(
        id: 'st1',
        userId: 'u1',
        name: 'Safe Opening',
        iconName: 'lock',
        category: 'Opening',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      ),
      ServiceTypeEntity(
        id: 'st2',
        userId: 'u1',
        name: 'Deadbolt Replacement',
        iconName: 'tools',
        category: 'Hardware',
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

Widget createTestWidget({
  String? selected,
  required ValueChanged<String> onSelected,
}) {
  return ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
      serviceTypeProvider.overrideWith((ref) => _TestServiceTypeNotifier(ref)),
    ],
    child: MaterialApp(
      theme: buildDarkAppTheme(),
      home: Scaffold(
        body: ServicePickerDropdown(
          selected: selected,
          onSelected: onSelected,
        ),
      ),
    ),
  );
}

void main() {
  group('ServicePickerDropdown', () {
    testWidgets('shows placeholder when nothing selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selected: null,
        onSelected: (_) {},
      ));
      await tester.pump();

      expect(find.text('SELECT SERVICE TYPE'), findsOneWidget);
    });

    testWidgets('shows chip when service is selected', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selected: 'Safe Opening',
        onSelected: (_) {},
      ));
      await tester.pump();

      expect(find.text('SAFE OPENING'), findsOneWidget);
    });

    testWidgets('opens bottom sheet on tap', (tester) async {
      await tester.pumpWidget(createTestWidget(
        selected: null,
        onSelected: (_) {},
      ));
      await tester.pump();

      await tester.tap(find.text('SELECT SERVICE TYPE'));
      await tester.pumpAndSettle();

      // Sheet header should be visible
      expect(find.text('SELECT SERVICE'), findsOneWidget);
      // Service options in sheet should be visible
      expect(find.text('SAFE OPENING'), findsOneWidget);
      expect(find.text('DEADBOLT REPLACEMENT'), findsOneWidget);
    });

    testWidgets('selecting a service type calls onSelected', (tester) async {
      String? selected;
      await tester.pumpWidget(createTestWidget(
        selected: null,
        onSelected: (t) => selected = t,
      ));
      await tester.pump();

      await tester.tap(find.text('SELECT SERVICE TYPE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SAFE OPENING'));
      await tester.pumpAndSettle();

      expect(selected, equals('Safe Opening'));
    });

    testWidgets('X button clears selection', (tester) async {
      String? clearedValue;
      await tester.pumpWidget(createTestWidget(
        selected: 'Safe Opening',
        onSelected: (t) => clearedValue = t,
      ));
      await tester.pump();

      // Find the X icon inside the chip
      final xIcon = find.byIcon(LineAwesomeIcons.times_solid);
      expect(xIcon, findsOneWidget);

      await tester.tap(xIcon);
      await tester.pump();

      expect(clearedValue, equals(''));
    });

    testWidgets('re-opens sheet when already selected field is tapped',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        selected: 'Safe Opening',
        onSelected: (_) {},
      ));
      await tester.pump();

      // Tap the chip area
      await tester.tap(find.text('SAFE OPENING'));
      await tester.pumpAndSettle();

      // Sheet should open
      expect(find.text('SELECT SERVICE'), findsOneWidget);
    });
  });
}
