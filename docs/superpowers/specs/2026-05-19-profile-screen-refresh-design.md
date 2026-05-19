# Profile Screen Refresh — Design Spec

## Scope
Targeted improvements to Profile screen (view mode) and Edit Profile screen. Not a full redesign — addresses specific visual and UX concerns identified during review.

## View Mode Changes

### 1. Badge Readability (profile_screen.dart, `_buildBadge`)
- fontSize: 8 → **11**
- Keep existing colors, border radius, letter spacing
- Slightly increase horizontal padding to match

### 2. Info Rows Visual Hierarchy (`_buildInfoRow`)
- **Phone row**: Add 3px accent500 left border strip (vertical) so the phone number stands out as the primary action item
- **Bio row** (when present): Render with italic style + increased vertical padding to feel like a descriptive section
- **Joined date row**: Keep as-is (lowest priority info)
- Add small accent-colored section headers above phone ("CONTACT") and above bio ("ABOUT"), matching edit mode's accent label pattern

### 3. Section Headers
- "CONTACT" label before the phone row
- "ABOUT" label before the bio row (only when bio is present)

## Edit Mode Changes

### 4. Avatar Consistency
- Edit mode avatar container: 88×88 → **80×80** to match view mode
- Camera overlay: padding 6, icon 14 → padding 8, icon **18** for easier tapping

### 5. Save Button (edit_profile_screen.dart, `_buildBottomBar`)
- Replace custom InkWell + Row with `KsButton(variant: KsButtonVariant.primary, label: "SAVE CHANGES", ...)`
- Button stays at bottom of screen

### 6. Loading State
- If `state.profile == null` AND not loading, show spinner centered on screen instead of empty form fields
- Prevents the "fields appear empty" flash

## Files Affected
- `lib/features/technician_profile/presentation/screens/profile_screen.dart` (view mode)
- `lib/features/technician_profile/presentation/screens/edit_profile_screen.dart` (edit mode)

## Acceptance Criteria
- When user goes to My Profile, badges are readable at normal phone viewing distance
- Info rows have visual separation — phone is visually distinct from join date
- Editing profile shows centered spinner until data loads
- Avatar stays same size between view and edit mode (80×80)
- Save button looks and feels like a primary button, not an InkWell
