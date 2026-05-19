# Plan: DB-Driven Service Selection in Onboarding

## Goal
Replace 4 hardcoded service cards in onboarding with a categorized, DB-seeded list of 30 services using `serviceTypeProvider`. Remove dead PNG assets. Do not connect SetupScreen.

---

## Step 1 — Create `lib/core/utils/icon_helpers.dart`

```dart
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

IconData getLineAwesomeIcon(String iconName) {
  switch (iconName) {
    case 'car':         return LineAwesomeIcons.car_solid;
    case 'key':         return LineAwesomeIcons.key_solid;
    case 'tools':       return LineAwesomeIcons.tools_solid;
    case 'lock':        return LineAwesomeIcons.lock_solid;
    case 'unlock':      return LineAwesomeIcons.unlock_solid;
    case 'wrench':      return LineAwesomeIcons.wrench_solid;
    case 'mobile-alt':  return LineAwesomeIcons.mobile_alt_solid;
    case 'door-open':   return LineAwesomeIcons.door_open_solid;
    case 'door-closed': return LineAwesomeIcons.door_closed_solid;
    case 'shield-alt':  return LineAwesomeIcons.shield_alt_solid;
    case 'building':    return LineAwesomeIcons.building_solid;
    case 'network-wired': return LineAwesomeIcons.network_wired_solid;
    case 'id-card':     return LineAwesomeIcons.id_card_solid;
    case 'video':       return LineAwesomeIcons.video_solid;
    case 'bell':        return LineAwesomeIcons.bell_solid;
    case 'envelope':    return LineAwesomeIcons.envelope_solid;
    case 'archive':     return LineAwesomeIcons.archive_solid;
    case 'store':       return LineAwesomeIcons.store_solid;
    case 'gavel':       return LineAwesomeIcons.gavel_solid;
    case 'motorcycle':  return LineAwesomeIcons.motorcycle_solid;
    case 'wifi':        return LineAwesomeIcons.wifi_solid;
    default:            return LineAwesomeIcons.tools_solid;
  }
}
```

---

## Step 2 — Update `ServiceTypeEntity`

**File:** `lib/features/service_types/domain/entities/service_type_entity.dart`

Add 2 fields:

```dart
class ServiceTypeEntity {
  // ... existing fields
  final String category;
  final String iconName;

  const ServiceTypeEntity({
    // ...
    this.category = 'General',
    this.iconName = 'tools',
    // ...
  });

  ServiceTypeEntity copyWith({
    // ...
    String? category,
    String? iconName,
  }) {
    return ServiceTypeEntity(
      // ...
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
    );
  }
}
```

---

## Step 3 — Update `ServiceTypeModel`

**File:** `lib/features/service_types/data/models/service_type_model.dart`

Add 2 fields to model + `fromJson`/`toJson`/`toEntity`/`fromEntity`:

```dart
class ServiceTypeModel {
  final String category;
  final String iconName;

  // fromJson — CRITICAL: null-safe defaults for existing Hive data
  factory ServiceTypeModel.fromJson(Map<String, dynamic> json) => ServiceTypeModel(
    // ... existing
    category: json['category'] as String? ?? 'General',
    iconName: json['icon_name'] as String? ?? 'tools',
  );

  Map<String, dynamic> toJson() => {
    // ... existing
    'category': category,
    'icon_name': iconName,
  };

  ServiceTypeEntity toEntity() => ServiceTypeEntity(
    // ... existing
    category: category,
    iconName: iconName,
  );

  factory ServiceTypeModel.fromEntity(ServiceTypeEntity entity) => ServiceTypeModel(
    // ... existing
    category: entity.category,
    iconName: entity.iconName,
  );
}
```

---

## Step 4 — Rewrite `SeedDefaultServiceTypesUseCase`

**File:** `lib/features/service_types/domain/usecases/seed_default_service_types_usecase.dart`

Replace 4 entries with 30, grouped by category:

```dart
class SeedDefaultServiceTypesUseCase implements UseCase<void, String> {
  final ServiceTypeRepository _repository;
  SeedDefaultServiceTypesUseCase(this._repository);

  @override
  Future<void> call(String userId) async {
    final now = DateTime.now();
    final defaults = [
      // AUTOMOTIVE
      _type(uuid, userId, 'Car Key Replacement',       'Automotive', 'car', now),
      _type(uuid, userId, 'Car Lockout',                'Automotive', 'unlock', now),
      _type(uuid, userId, 'Key Fob Programming',        'Automotive', 'wifi', now),
      _type(uuid, userId, 'Ignition Repair',            'Automotive', 'key', now),
      _type(uuid, userId, 'Broken Key Extraction',      'Automotive', 'tools', now),
      _type(uuid, userId, 'Motorcycle Keys',            'Automotive', 'motorcycle', now),
      // RESIDENTIAL
      _type(uuid, userId, 'House Lockout',              'Residential', 'door-open', now),
      _type(uuid, userId, 'Lock Installation',          'Residential', 'lock', now),
      _type(uuid, userId, 'Lock Rekeying',              'Residential', 'key', now),
      _type(uuid, userId, 'Lock Repair',                'Residential', 'wrench', now),
      _type(uuid, userId, 'Smart Lock Install',         'Residential', 'mobile-alt', now),
      _type(uuid, userId, 'Mailbox Locks',              'Residential', 'envelope', now),
      _type(uuid, userId, 'Window Locks',               'Residential', 'lock', now),
      // COMMERCIAL
      _type(uuid, userId, 'Commercial Lockout',         'Commercial', 'building', now),
      _type(uuid, userId, 'Master Key Systems',         'Commercial', 'network-wired', now),
      _type(uuid, userId, 'Panic Bar Installation',     'Commercial', 'door-closed', now),
      _type(uuid, userId, 'Door Closer Install',        'Commercial', 'tools', now),
      _type(uuid, userId, 'High-Security Locks',        'Commercial', 'shield-alt', now),
      _type(uuid, userId, 'File Cabinet Locks',         'Commercial', 'archive', now),
      _type(uuid, userId, 'Storefront Locks',           'Commercial', 'store', now),
      // SECURITY SYSTEMS
      _type(uuid, userId, 'CCTV Installation',          'Security Systems', 'video', now),
      _type(uuid, userId, 'Access Control',             'Security Systems', 'id-card', now),
      _type(uuid, userId, 'Burglar Alarms',             'Security Systems', 'bell', now),
      _type(uuid, userId, 'Intercom Systems',           'Security Systems', 'id-card', now),
      // SPECIALTY
      _type(uuid, userId, 'Safe Opening',               'Specialty', 'unlock', now),
      _type(uuid, userId, 'Safe Installation',          'Specialty', 'lock', now),
      _type(uuid, userId, 'Gate Automation',            'Specialty', 'tools', now),
      _type(uuid, userId, 'Eviction Services',          'Specialty', 'gavel', now),
    ];

    for (final service in defaults) {
      await _repository.createServiceType(service);
    }
  }

  ServiceTypeEntity _type(String id, String userId, String name, String category, String iconName, DateTime now) {
    return ServiceTypeEntity(
      id: id, userId: userId, name: name,
      category: category, iconName: iconName,
      isDefault: true, createdAt: now, updatedAt: now,
    );
  }
}
```

---

## Step 5 — Replace Onboarding Service Step

**File:** `lib/features/auth/presentation/screens/onboarding_screen.dart`

Changes:

1. **Remove:** `_ServiceData` class (lines 13-18), `_services` list (lines 34-39), `Image.asset` usage in `_buildServicesStep`, import for `serviceTypeProvider`

2. **Add imports:**
```dart
import '../../../../core/utils/icon_helpers.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import '../../../service_types/domain/entities/service_type_entity.dart';
```

3. **Add** `List<ServiceTypeEntity>? _serviceTypes` field and load inside `initState` or directly from provider in build

4. **Rewrite `_buildServicesStep`** — replace GridView with categorized ListView:

```dart
Widget _buildServicesStep(BuildContext context, {Key? key}) {
  final serviceTypesAsync = ref.watch(serviceTypeProvider);

  return Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ... industrial eyebrow + title + step indicator (unchanged)

      serviceTypesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Failed to load services',
            style: AppTextStyles.caption.copyWith(color: context.ksc.error500)),
        ),
        data: (types) {
          final grouped = _groupByCategory(types);
          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...entry.value.map((type) => _serviceTile(type)),
                ],
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

Map<String, List<ServiceTypeEntity>> _groupByCategory(List<ServiceTypeEntity> types) {
  final map = <String, List<ServiceTypeEntity>>{};
  for (final t in types) {
    map.putIfAbsent(t.category, () => []).add(t);
  }
  return map;
}

Widget _serviceTile(ServiceTypeEntity type) {
  final isSelected = _selectedServices.contains(type.name);
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GestureDetector(
      onTap: () => _toggleService(type.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? context.ksc.accent500.withValues(alpha: 0.1)
              : context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? context.ksc.accent500 : context.ksc.primary700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              getLineAwesomeIcon(type.iconName),
              size: 20,
              color: isSelected ? context.ksc.accent500 : context.ksc.neutral500,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.name.toUpperCase(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? context.ksc.white : context.ksc.neutral400,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isSelected)
              Icon(LineAwesomeIcons.check_circle_solid, size: 20, color: context.ksc.accent500),
          ],
        ),
      ),
    ),
  );
}
```

5. **Update `_toggleService`** — currently takes `type` (the old `_ServiceData.type` string). Since we now use `type.name`, unify: `_toggleService(type.name)`. The `_selectedServices` is `List<String>` of service names — unchanged contract with `completeOnboarding()`.

---

## Step 6 — Add exports to `shared_feature_providers.dart`

Add at bottom of the file:
```dart
// Service Types
export 'package:keystone/features/service_types/presentation/providers/service_type_provider.dart'
    show serviceTypeProvider;
```

---

## Step 7 — Remove dead PNG assets

```
rm assets/services/car_key.png
rm assets/services/door_install.png
rm assets/services/door_repair.png
rm assets/services/smart_lock.png
```

Also remove `flutter_image_compress` leftover if still in pubspec (already removed in earlier session).

---

## Step 8 — Run flutter analyze

Expected: 0 new errors. The pre-existing `mock_data_generator` int→double error persists.

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| `SeedDefaultServiceTypesUseCase` creates 30 DB rows per new user | Acceptable — service_type table is tiny (<1KB), user signs up once |
| Old Hive data lacks `category`/`iconName` | `fromJson` has `?? 'General'` / `?? 'tools'` defaults |
| `completeOnboarding` sends service names to `profileEntity.services` | Names match seeded DB names (we control both sides) |
| `serviceTypeProvider.loadServiceTypes` is async | Onboarding shows loader spinner while types load |
