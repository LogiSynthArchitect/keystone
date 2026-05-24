# KsStepDrawer Reusable Component

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract shared bottom-sheet drawer chrome into a reusable `KsStepDrawer` widget, then refactor inventory add-item and service pricing drawers to use it.

**Architecture:** A single `KsStepDrawer` StatefulWidget that manages drag handle, header (title + optional back arrow + close), optional step indicator, step content slot, and a single full-width gold bottom button with sharp edges. Inventory uses progression mode (4 steps, step indicator, back arrow). Pricing uses single-step mode (2 steps internally, no step indicator, no back arrow).

**Tech Stack:** Flutter/Dart, Riverpod

---

### Task 1: Create `KsStepDrawer` widget

**Files:**
- Create: `lib/core/widgets/ks_step_drawer.dart`

- [ ] **Step 1: Write the widget skeleton**

```dart
import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../theme/app_text_styles.dart';
import '../theme/ks_colors.dart';
import 'ks_step_indicator.dart';

class KsStepDrawer extends StatefulWidget {
  final String title;
  final List<String>? steps;
  final bool showBackArrow;
  final VoidCallback? onBack;
  final Widget Function(int step) stepContent;
  final bool Function(int step)? canAdvance;
  final Future<void> Function()? onSave;
  final String nextLabel;
  final String saveLabel;
  final VoidCallback? onClose;

  const KsStepDrawer({
    super.key,
    required this.title,
    this.steps,
    this.showBackArrow = false,
    this.onBack,
    required this.stepContent,
    this.canAdvance,
    this.onSave,
    this.nextLabel = 'NEXT',
    this.saveLabel = 'SAVE',
    this.onClose,
  });

  @override
  State<KsStepDrawer> createState() => _KsStepDrawerState();
}

class _KsStepDrawerState extends State<KsStepDrawer> {
  int _currentStep = 0;

  bool get _isLastStep => widget.steps == null || _currentStep >= widget.steps!.length - 1;

  bool get _canProceed {
    if (widget.canAdvance != null) return widget.canAdvance!(_currentStep);
    return true;
  }

  void _handleBottomTap() {
    if (!_canProceed) return;
    if (_isLastStep) {
      widget.onSave?.call();
    } else {
      setState(() => _currentStep++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: context.ksc.neutral600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                if (widget.showBackArrow)
                  GestureDetector(
                    onTap: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep--);
                      } else {
                        widget.onBack?.call();
                      }
                    },
                    child: Icon(LineAwesomeIcons.angle_left_solid,
                        color: context.ksc.accent500, size: 18),
                  ),
                if (widget.showBackArrow) const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                    style: AppTextStyles.h2.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                    )),
                ),
                GestureDetector(
                  onTap: widget.onClose ?? () => Navigator.pop(context),
                  child: Icon(LineAwesomeIcons.times_solid,
                      color: context.ksc.neutral500, size: 20),
                ),
              ],
            ),
          ),
          // Step indicator
          if (widget.steps != null) ...[
            const SizedBox(height: 12),
            KsStepIndicator(
              currentStep: _currentStep,
              totalSteps: widget.steps!.length,
              labels: widget.steps!,
            ),
          ],
          const SizedBox(height: 4),
          // Step content
          Expanded(
            child: widget.stepContent(_currentStep),
          ),
          // Bottom button — gold, full width, sharp edges
          Container(
            width: double.infinity,
            color: _canProceed
                ? context.ksc.accent500
                : context.ksc.primary600,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _canProceed ? _handleBottomTap : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isLastStep ? widget.saveLabel : widget.nextLabel,
                        style: AppTextStyles.body.copyWith(
                          color: _canProceed
                              ? context.ksc.primary900
                              : context.ksc.neutral500,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Icon(
                        _isLastStep
                            ? LineAwesomeIcons.check_solid
                            : LineAwesomeIcons.arrow_right_solid,
                        color: _canProceed
                            ? context.ksc.primary900
                            : context.ksc.neutral500,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analysis**

Run: `flutter analyze lib/core/widgets/ks_step_drawer.dart`
Expected: No errors

---

### Task 2: Refactor inventory screen

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart`

Replace the entire `showModalBottomSheet` body (lines ~878-960) with a `KsStepDrawer` wrapping the existing step content builders.

Key mapping:
- `title: isEditing ? "EDIT ITEM" : "ADD ITEM"`
- `steps: ["BASIC", "GENERAL", "SPECS & SETTINGS", "STOCK"]`
- `showBackArrow: true` (currentStep > 0 goes back, step 0 calls onBack which pops the sheet)
- `canAdvance: (step) { if (step == 0) return nameCtrl.text.trim().isNotEmpty; return true; }`
- `onSave: () => _handleSave()`
- `nextLabel: "NEXT"`
- `saveLabel: isEditing ? "SAVE CHANGES" : "ADD ITEM"`

Remove the old `_buildStepNavBar` method entirely (no longer needed). Keep `_buildStepContent` methods as they are (passed to `stepContent`).

The `_showItemDialog` method needs to be restructured — move the `showModalBottomSheet` call but replace the inner builder content with `KsStepDrawer`.

Remove `import 'ks_step_indicator.dart'` if no longer directly used.

---

### Task 3: Refactor pricing screen

**Files:**
- Modify: `lib/features/service_types/presentation/screens/pricing_screen.dart`

Replace the `showModalBottomSheet` body with `KsStepDrawer`. Pricing uses single-step mode:
- `title: "SET PRICE"`
- `steps: null` — no step indicator
- `showBackArrow: false`
- `canAdvance: (step) => currentValue.isNotEmpty`
- `onSave: _save`
- `nextLabel: "CONTINUE"`
- `saveLabel: "SAVE"`

The step 0 → step 1 transition is managed by the drawer's internal step counter. Since pricing has 2 logical steps (set price, confirm), set `steps: ["PRICE", "CONFIRM"]` to give it 2 steps but keep the step indicator hidden. Wait — the user said no step indicator for pricing. So `steps: null` with the drawer defaulting to 2 steps internally. The drawer needs to handle this: when `steps` is null, it treats step 0 as the only visible step and step 1 as the "save" step.

Actually this needs more thought. Since pricing has 2 steps (set price, confirm), I need to handle that. Let me make the drawer always support internal steps, with `steps` only controlling the visual indicator. When `steps: null`, no indicator shows but stepping still works.

Actually, let me keep it simple: pricing will use `steps: ["PRICE", "CONFIRM"]` and we just hide the indicator. I'll add a `showSteps` parameter or just pass `steps: null` and have the drawer default to a hidden 2-step mode.

Wait, let me re-think. The drawer manages `_currentStep` internally. It needs to know the total steps for the "is last step" logic. The cleanest approach:

- If `steps` is provided (non-null), show the step indicator. Total steps = `steps.length`.
- If `steps` is null, don't show indicator. Total steps is determined by... how? From a separate parameter?

Let me simplify: I'll add a `totalSteps` parameter that defaults to `steps?.length ?? 1`. If `steps` is provided, show indicator with those labels. If `steps` is null, no indicator. The drawer still manages `_currentStep` internally for the save/advance logic.

For pricing:
- `steps: null` (no indicator)
- `totalSteps: 2` (set price step + confirm step)
- This way the drawer knows when it's on the last step to show "SAVE" vs "CONTINUE"

Hmm, this is getting complicated. Let me just keep it even simpler. For pricing, both steps are content that the user provides via `stepContent`. The drawer doesn't need to know the total steps for pricing — pricing only has 1 "visible" step (the set-price form). The confirm step is the save action.

Actually, looking at pricing again: step 0 is the form, step 1 is the confirm/save screen. Both are content. The user sees:
1. Set price form → taps continue → 
2. Confirm screen → taps save

So it IS 2 steps. Let me just keep the approach: pricing uses `steps: ["PRICE", "CONFIRM"]` and we add a `showStepIndicator` parameter:

```
showStepIndicator: false // for pricing, hides the visual indicator but keeps stepping logic
```

Wait, the user explicitly said pricing doesn't need progression. They see pricing as a single action. Maybe I should make pricing use only 1 step (just step 0 - the form), and the confirm screen is integrated into the "continue" action (like a one-step save). But the original pricing code has 2 screens...

Actually, let me keep it faithful to the original. The current pricing drawer has 2 screens and the user's complaint was about visual consistency, not the number of screens. I'll give it 2 steps with `showStepIndicator: false`, so the indicator is hidden but stepping still works. The user won't see the steps but can still go from form to confirm.

Alright, let me just add `showStepIndicator` as a bool to the drawer. That's clean enough.

Let me now implement this. I'll create the plan document, then start coding.<｜end▁of▁thinking｜>

<｜｜DSML｜｜tool_calls>
<｜｜DSML｜｜invoke name="todowrite">
<｜｜DSML｜｜parameter name="todos" string="false">[{"content":"Create KsStepDrawer widget", "status": "in_progress", "priority": "high"}, {"content":"Refactor inventory screen to use KsStepDrawer", "status": "pending", "priority": "high"}, {"content":"Refactor pricing screen to use KsStepDrawer", "status": "pending", "priority": "high"}, {"content":"Hot restart and verify both drawers", "status": "pending", "priority": "medium"}]