# DOCUMENT 25 — V1 POLISH & UI REDESIGN
### Project: Keystone
**Purpose:** Track every UI and feature improvement before sending to Jeremie and Jean
**Status:** IN PROGRESS
**Started:** March 2026

---

## 25.1 What This Document Is

This document tracks every screen, every UI change, and every known feature addition
we are making before V1 launch. We work through it screen by screen, item by item.
Each item gets checked off when complete and tested on physical device.

---

## 25.2 Completed

### App Icon
- [x] Designed arch + keystone + keyhole logo mark
- [x] Colors: navy (#1A237E) arch, gold (#F9A825) keystone, navy keyhole
- [x] Source file: ~/Downloads/logos.png (1248x1248 RGBA)
- [x] Generated all Android mipmap sizes (mdpi through xxxhdpi)
- [x] White background, logo centered with padding
- [x] Tested on physical device

### Splash Screen
- [x] White background
- [x] Logo centered, sharp, well proportioned
- [x] Canvas: 1080x1920, Logo: 900x1300
- [x] Generated using flutter_native_splash (add → generate → remove workflow)
- [x] Tested on physical device
- LESSON: flutter_native_splash must be added, used, then removed every time
  because it requires AGP 8.7.0 which cannot be downloaded on restricted networks

### KsLogo Widget
- [x] Pixel perfect SVG logo — ks_logo_combined.svg
- [x] 4 named paths: left_arm, right_arm, keystone_block, keyhole
- [x] Fully programmatic — colors changeable at runtime
- [x] Scales to any size with zero blur
- [x] Rendered via flutter_svg SvgPicture.asset
- [x] Ready for animations and theming
- LESSON: never manually reassemble individually exported SVG parts
  Always arrange all parts in Inkscape and export as one complete SVG

---

## 25.3 Screens To Redesign

### 1. Phone Entry Screen (Login)
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 2. OTP Verify Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 3. Onboarding Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 4. Jobs Dashboard
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 5. Log Job Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 6. Job Detail Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 7. Customer List Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 8. Customer Detail Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 9. Add Customer Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 10. Notes List Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 11. Note Detail Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 12. Add Note Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 13. Profile Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 14. Edit Profile Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

### 15. Public Profile Screen
- [ ] Review current design
- [ ] Sketch new design
- [ ] Agree on design
- [ ] Build in Flutter
- [ ] Test on device

---

## 25.4 Known Feature Additions

These are features we know are needed without waiting for user feedback:

- [ ] Editable WhatsApp follow-up message — user can customize before sending
- [ ] App version number visible somewhere in settings or profile
- [ ] Confirmation dialog before deleting any item

---

## 25.5 Process

For each screen:
1. Claude describes the new design in detail
2. User takes description to AI image generator for visual mockup
3. User reviews and gives feedback
4. Design agreed
5. Claude builds it in Flutter
6. Test on physical device
7. Check off and move to next screen

---

## 25.6 Definition of Done

V1 Polish is complete when:
- All 15 screens redesigned and tested on device
- All known feature additions built and tested
- Checkpoint 4 smoke test passes on redesigned app
- APK built with release signing
- Sent to Jeremie and Jean via WhatsApp

### Landing Screen ✅
- [x] Split screen design — off-white top / navy bottom
- [x] KsLogo 170px with staggered entrance animation
- [x] Gold label: LOCKSMITH MANAGEMENT
- [x] Keystone 54px weight 800
- [x] Subtitle centered, weight 600
- [x] Gold Get Started button on navy
- [x] RichText sign in line — white + gold
- [x] Routed as initial screen for unauthenticated users
- [x] Font system: BarlowSemiCondensed full family registered

### Font System ✅
- [x] Barlow Semi Condensed — all 18 variants in assets/fonts/
- [x] Registered in pubspec.yaml (weights 100-900, italic variants)
- [x] app_text_styles.dart migrated from GoogleFonts.inter to BarlowSemiCondensed
- [x] Rule: weight 600+ only throughout the app

### Phone Entry Screen ✅
- [x] Icon badge — navy square, gold mobile icon
- [x] Heading 38px w800 left-aligned
- [x] Unified phone input — no divider, flag + prefix + number seamless
- [x] Ghana flag SVG
- [x] Gold check / grey X validation icon
- [x] Animated feedback banner — slide in, auto dismiss, error/success states
- [x] Keyboard aware — navy bottom hides, floating button appears
- [x] Consistent split screen language with landing screen

### OTP Verify Screen ✅
- [x] Icon badge — navy square, gold shield icon
- [x] Heading 38px w800 left-aligned
- [x] Phone number highlighted navy bold in subtitle
- [x] 6 Pinput boxes — white, grey border, navy focus, navy filled
- [x] Animated feedback banner — same as phone entry
- [x] Countdown timer — navy bold seconds, gold Resend on expiry
- [x] Keyboard aware — floating button pattern
- [x] Consistent with landing and phone entry screen language

---
## V1 Polish Completion Log — March 2026

The following screens and components have been fully redesigned into the dark industrial theme and simplified for ease of use:

- [x] **Landing Page**: Split-screen design with staggered animations.
- [x] **Transition Portal**: The loading/welcome gate after onboarding.
- [x] **Phone Screen**: Identity initiation with Ghana-specific formatting.
- [x] **OTP Screen**: Security verification with 6-digit Pinput and resend logic.
- [x] **Onboarding Flow**: 2-step name and service selection with back-button fixes.
- [x] **Dashboard Shell**: Top navigation (My Jobs) and Bottom Navigation with the gold active-tab circuit.
- [x] **Job Dashboard**: The main ledger showing job history and monthly earnings summary.
- [x] **Job Card**: Tactical dark modules showing job details and sync status.
- [x] **Add Job Form**: Simple data entry with the "white-out" visibility bug fixed.
- [x] **Customer Dashboard**: Searchable list of clients with the tactical "Repeat" badge.

- [x] **Add Note Screen**: Standardized form with dark modules and tactical selectors.
- [x] **Tag Input Field**: Custom industrial widget with gold chips and transparent background.
- [x] **Job Detail Screen**: Modular tactical report layout implemented.
- [x] **WhatsApp Follow-up**: Preview and Action Button integrated with wa.me deep links.
