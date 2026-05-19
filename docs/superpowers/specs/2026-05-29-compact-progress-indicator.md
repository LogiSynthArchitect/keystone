# Compact Progress Indicator

**Date:** 2026-05-29
**Project:** Keystone
**Feature:** Replace `KsStepIndicator` with `KsCompactProgress`

---

## Overview

Replace the horizontal step label bar (SERVICE — CUSTOMER — DETAILS — EXTRAS + progress bar) with an ultra-compact progress bar + floating step name badge. Reduces indicator height from ~58px to ~28px and scales to any number of steps without visual clutter.

---

## New Widget: `KsCompactProgress`

```
┌──────────────────────────────────────────┐
│  ━━━━━━━━━━━━━░░░░░░░░░░░░░░░░░░░░░░░░  │  4px progress bar
│  ● Step 3 · DETAILS             3 of 4  │  16px info row
└──────────────────────────────────────────┘
               ~28px total
```

| Element | Style |
|---------|-------|
| Progress bar (filled) | 4px height, `accent500`, rounded corners |
| Progress bar (unfilled) | 4px height, `neutral700`, rounded corners |
| Step dot | `accent500` circle, 6px diameter, inline with text |
| Step name | `caption` / `neutral500`, **bold**, letter-spacing 0.8 |
| "N of M" counter | `caption` / `neutral500`, right-aligned |
| Container | `primary800` background, bottom border `primary700` |

---

## Behavior

- **Current step** — dot filled with `accent500`, step name in `neutral500` bold
- **Progress segments** — all steps up to current are filled. Uses same wrapping as current (index <= currentStep → accent)
- **Next/Back** — unchanged. Bottom bar stays identical.
- `currentStep`, `totalSteps`, `labels` — same parameters as old indicator

---

## Files Changed

| File | Action |
|------|--------|
| `lib/core/widgets/ks_step_indicator.dart` | Replace content with new `KsCompactProgress` widget (or create new file) |
| `lib/features/job_logging/presentation/screens/log_job_screen.dart` | Replace `KsStepIndicator` with `KsCompactProgress` |

---

## Non-Goals

- No changes to `_buildBottomAction()` or navigation logic
- No changes to any other step content
- No behavioral change — purely visual replacement
