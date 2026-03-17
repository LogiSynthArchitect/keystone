# UI COMPLIANCE CHECK
### Project: Keystone
### Purpose: Screen by screen verification that every UI element complies with the design system
### Reference: docs/v1/design/UI_UX_SYSTEM.md and docs/v1/design/14_design_system.md
### Run as part of: Every Domain Conceptual Review

---

## What This Check Does

This check verifies that every screen in Keystone visually complies with the documented design system. It finds screens that have drifted from the industrial aesthetic, components that are generic, typography that is wrong, colors that are not from the defined palette.

It is the visual layer of the domain review. It uses the rules from the design system as its standard. Every rule in the design system maps to a check here.

---

## The Keystone Visual Identity Rules

Before checking screens, internalize these non-negotiable rules:

THEME: Dark industrial. Primary background is AppColors.primary900 — deep navy #0A1628.
ACCENT: Gold — AppColors.accent500 #F9A825. Used sparingly for active states and CTAs.
FONT: Barlow Semi Condensed. Weight 600 minimum throughout the app.
BORDERS: Sharp corners — border radius 4px maximum on dark surfaces.
INPUTS: Dark field on dark background. fillColor transparent. White text on dark.
BUTTONS: Full width bottom bar with InkWell. Not elevated buttons in forms.
ICONS: Line Awesome Flutter. Consistent family throughout.
EMPTY STATES: Dark background with low opacity icon and white text.
NAVIGATION: Dark navy bottom nav with gold active circuit line at top.
APP BAR: Dark navy. Title uppercase with letter spacing.

---

## Screen Compliance Checklist

Run this checklist for every screen. Mark PASS or FAIL for each item.

### For Every Screen
[ ] Background color is AppColors.primary900 — not neutral050 or white
[ ] All text fields use dark field style — fillColor transparent, no white background
[ ] All text is visible against dark background — no white-out bug
[ ] Font family is Barlow Semi Condensed — not Inter or Roboto
[ ] Font weight is 600 or higher — no thin text
[ ] Border radius on containers is 4px — not 8px or 12px or 16px
[ ] Icons are from Line Awesome Flutter — not Material Icons unless unavoidable
[ ] Bottom action bar follows the dark navy with InkWell pattern
[ ] Empty states use dark background with subtle icon
[ ] Error messages use KsBanner not AlertDialog
[ ] Loading states use CircularProgressIndicator with AppColors.accent500

### For List Screens
[ ] List items are dark containers with white text
[ ] Separator is SizedBox with height not KsDivider
[ ] Pull to refresh uses accent500 color
[ ] FAB uses accent500 background with primary900 foreground
[ ] Search bar follows dark field pattern

### For Form Screens
[ ] All input fields use dark field builder pattern
[ ] Labels are uppercase with letter spacing using caption style
[ ] Save button uses bottom bar InkWell pattern not KsButton
[ ] Keyboard aware — bottom bar hides when keyboard is visible
[ ] PopScope handles unsaved changes with dark dialog

### For Detail Screens
[ ] Section headers use caption style with neutral500 color
[ ] Modules use primary800 background not white cards
[ ] Data rows use consistent spacing
[ ] Back button uses angle_left_solid icon

---

## The 15 Screens Status

| Screen | Theme Applied | Compliance Status |
|---|---|---|
| Landing | Dark industrial | PASS |
| Phone Entry | Dark industrial | PASS |
| OTP Verify | Dark industrial | PASS |
| Onboarding | Dark industrial | PASS |
| Job List | Dark industrial | PASS |
| Log Job | Dark industrial | PASS |
| Job Detail | Dark industrial | PASS |
| Customer List | Dark industrial | PASS |
| Customer Detail | Dark industrial | PASS |
| Add Customer | Dark industrial | PASS |
| Notes List | Dark industrial | PASS |
| Note Detail | Dark industrial | PASS |
| Add Note | Dark industrial | PASS |
| Profile | Dark industrial | PASS |
| Edit Profile | Dark industrial | PASS |
| Public Profile | Light theme — acceptable | Public facing only |

---

## Known Non-Compliance Issues

None identified. All internal screens have been migrated to the Dark Industrial design system.


---

## How To Report Findings

For every non-compliant item found, document it as:

SCREEN: [screen name]
FILE: [lib/features/.../screen_name.dart]
RULE VIOLATED: [which rule from the design system]
WHAT IS WRONG: [description of the violation]
WHAT IT SHOULD BE: [correct implementation]
SEVERITY: [HIGH if major visual inconsistency / MEDIUM if minor]
