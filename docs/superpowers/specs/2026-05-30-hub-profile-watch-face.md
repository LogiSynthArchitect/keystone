# Hub Profile Hero — Watch Face Redesign

**Date:** 2026-05-30  
**Design Direction:** Option A — "Watch Face" (DFII: 14/15)

## Purpose
Elevate the Hub (MORE) tab profile hero from a flat avatar + stats card into a premium command-center identity hub that feels like a luxury watch dial.

## Design Thinking

| Dimension | Decision |
|---|---|
| Purpose | Identity + data glance — show who you are and how you're performing |
| Tone | Industrial luxury (NoirLuxe with Swiss watch precision) |
| Differentiation Anchor | Watch face structure: avatar as crown, metrics as complications, progress arc |

## Changes

### Avatar
- Size: 56 → 64px
- Border: 2 → 2.5px gold
- Position: left-aligned → centered (crown position)
- Added `BoxShadow` gold glow: `color: gold.withAlpha(77)`, `blurRadius: 12`, `spreadRadius: 2`

### Subtitle
- Static `"Tap to view full profile"` → dynamic: `"N pending"` (gold) or `"All caught up"` (neutral)
- Pending count from `jobState.pendingCount`

### Stats
- 3 cramped `_statCard` boxes (Jobs, Revenue, Pending) → 2 large bento-style cards (Jobs, Revenue)
- Each has a 3px gradient accent bar matching the tools bento language: blue for Jobs, gold for Revenue
- Pending moved from stat card to header subtitle

### Progress Arc
- Added bento-style gold→purple gradient progress bar showing monthly target attainment
- Bottom of hero, similar style to the existing `_progressBar` in tools bento

### Container
- Added 3px gold gradient top accent bar (matches bento card language)
- Art deco ornament: `✦ ✦ ✦` text → 4 positioned corner angle icons at 15% opacity

### Removed
- `_statCard` (replaced by `_heroStatCard` with accent bar)
- `Text('✦ ✦ ✦')` ornament (replaced by positioned icons)
- `Icon(LineAwesomeIcons.angle_right_solid)` from name row (row restructured)
- Progress bar barrowed from bento tools but placed inside hero

## Files Changed
- `lib/features/hub/presentation/screens/hub_screen.dart` — `_buildProfileHero` rewrite, `_statCard` → `_heroStatCard`
