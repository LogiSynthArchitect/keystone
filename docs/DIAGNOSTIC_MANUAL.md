# KEYSTONE DIAGNOSTIC MANUAL
*Version 1.1 - Post-Onboarding Modularization*

## I. ROOT ARCHITECTURE
... (entries 1-58) ...

### 59. lib/features/auth/presentation/screens/onboarding_screen.dart
- **Objective:** The "Technician Birthplace" coordinator.
- **Core Logic:** Manages step-based state (Name vs Services) and delegates UI to modular widgets.
- **Failure Mode:** Navigation fails if `authNotifierProvider.completeOnboarding` returns false.

## III. FEATURE WIDGETS
... (entries 60-128) ...

### 129. lib/features/auth/presentation/widgets/name_step_view.dart
- **Objective:** UI for identity collection.

### 130. lib/features/auth/presentation/widgets/services_step_view.dart
- **Objective:** UI for service category selection.

### 131. lib/features/auth/presentation/widgets/onboarding_bottom_bar.dart
- **Objective:** Persistent action anchor for onboarding steps.

### 132. lib/features/auth/presentation/widgets/onboarding_step_indicator.dart
- **Objective:** Visual progress for the 2-step flow.
