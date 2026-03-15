# DOCUMENT 14 — DESIGN SYSTEM
### Project: Keystone
**Required Inputs:** Document 04 — Core Scope, Document 05 — User Personas, Document 13 — Flutter Architecture
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 14.1 Design Direction

Character: Clean, professional, credible. A tool serious technicians trust daily.
Feeling: Premium service business — not a startup toy, not a corporate enterprise app.
Influence: The confidence of West African service culture. Direct. Capable. No fuss.

Three principles:
1. Speed over decoration — every screen has one job, nothing competes for attention
2. Legible in sunlight — Jeremie and Jean work outdoors; contrast is non-negotiable
3. Shareable credibility — the public profile must make a customer feel they hired a professional

---

## 14.2 Color Palette

Primary — Deep Navy
primary900: #0A1628  Darkest — text on light
primary800: #0F2144  Dark navy
primary700: #163060  Brand navy — main buttons, headers
primary600: #1E3F7A  Interactive states
primary500: #2952A3  Links, active indicators
primary400: #4A6EC4  Disabled states
primary100: #E8EDF7  Light tint — backgrounds, cards
primary050: #F3F6FC  Faintest tint — page backgrounds

Accent — Warm Gold
accent600: #B8860B  Dark gold — text on light
accent500: #D4A017  Brand gold — primary CTA
accent400: #E8B84B  Hover/pressed state
accent100: #FDF3D0  Gold tint background

Neutrals — Warm Grey
neutral900: #1A1A1A  Primary text
neutral800: #2D2D2D  Strong text
neutral700: #404040  Body text
neutral600: #5C5C5C  Secondary text
neutral500: #737373  Placeholder text
neutral400: #9E9E9E  Disabled text
neutral300: #BDBDBD  Borders, dividers
neutral200: #E0E0E0  Subtle borders
neutral100: #F5F5F5  Input backgrounds
neutral050: #FAFAFA  Page background
white:      #FFFFFF

Semantic — Success
success600: #1B6B3A  success500: #2E7D32  success100: #E8F5E9

Semantic — Warning
warning600: #E65100  warning500: #F57C00  warning100: #FFF3E0

Semantic — Error
error600: #B71C1C  error500: #C62828  error100: #FFEBEE

Offline
offline: #9E9E9E  offlineBg: #F5F5F5

Color Usage Rules:
App bar background:       primary700
App bar text/icons:       white
Bottom nav background:    white
Bottom nav active:        primary700
Bottom nav inactive:      neutral400
Page background:          neutral050
Card background:          white
Card border:              neutral200
Primary button fill:      primary700
Primary button text:      white
CTA button (Follow-up):   accent500
CTA button text:          primary900
Input background:         neutral100
Input border default:     neutral300
Input border focused:     primary600
Input border error:       error500
Primary text:             neutral900
Secondary text:           neutral600
Placeholder text:         neutral500
Offline banner bg:        offlineBg
Offline banner text:      neutral600

---

## 14.3 Typography

Typeface: Inter (Google Fonts)

display:       32sp  w700  ls:-0.5  lh:1.2  — large numbers, empty state headings
h1:            24sp  w700  ls:-0.3  lh:1.3  — screen titles
h2:            20sp  w600  ls:-0.2  lh:1.3  — section headers, card titles
h3:            17sp  w600  ls:0     lh:1.4  — subsection labels
bodyLarge:     16sp  w400  ls:0     lh:1.5  — primary reading text, job notes
body:          14sp  w400  ls:0     lh:1.5  — standard body text
bodyMedium:    14sp  w500  ls:0     lh:1.5  — slightly emphasized body
caption:       12sp  w400  ls:0.1   lh:1.4  — metadata, timestamps
captionMedium: 12sp  w500  ls:0.1   lh:1.4  — emphasized metadata
label:         14sp  w600  ls:0.1   lh:1.2  — button text, tab labels
labelSmall:    12sp  w600  ls:0.2   lh:1.2  — chip text, badge text
amount:        20sp  w700  ls:-0.2  lh:1.2  — GHS values large
amountSmall:   16sp  w600  ls:0     lh:1.2  — inline currency amounts

Typography Usage:
Screen title in app bar:   h2, white
Card title:                h3
Job service type:          bodyMedium
Job notes:                 body
Customer name in list:     bodyMedium
Date and timestamp:        caption
GHS amount large:          amount
GHS amount in list:        amountSmall
Button text:               label
Input label:               captionMedium
Input placeholder:         body, neutral500
Error message:             caption, error600
Empty state heading:       h2
Empty state body:          body, neutral600

---

## 14.4 Spacing System (8-point grid)

xs:    4dp   Icon padding, tight gaps
sm:    8dp   Internal component padding
md:   12dp   Between related elements
lg:   16dp   Standard content padding
xl:   20dp   Section spacing
xxl:  24dp   Card padding, large gaps
xxxl: 32dp   Screen section separation
huge: 48dp   Empty state vertical spacing

pagePadding:       16dp
cardPadding:       16dp
bottomNavHeight:   64dp
appBarHeight:      56dp
fabOffset:         80dp
inputHeight:       52dp
buttonHeight:      52dp
buttonSmallHeight: 40dp
listItemHeight:    72dp
avatarSm:  32dp  avatarMd: 48dp  avatarLg: 80dp  avatarXl: 120dp

---

## 14.5 Border Radius

radiusSm:   4dp   Chips, badges, tags
radiusMd:   8dp   Inputs, small cards
radiusLg:  12dp   Standard cards
radiusXl:  16dp   Bottom sheets, modals
radiusFull: 999dp  Pills, avatars, FAB

---

## 14.6 Shadows

cardShadow:   color 0x0D000000  blur 8  offset (0,2)
modalShadow:  color 0x1A000000  blur 24  offset (0,-4)
fabShadow:    color 0x33163060  blur 12  offset (0,4)

---

## 14.7 Iconography

Icon library: Material Icons (built-in Flutter)
Sizes: 24dp standard, 20dp inline/dense, 16dp badges

Jobs:              work_outline
Log new job:       add_circle_outline
Customer:          person_outline
Add customer:      person_add_outlined
Knowledge note:    lightbulb_outline
Add note:          edit_outlined
Profile:           badge_outlined
WhatsApp follow-up: send_outlined
Follow-up sent:    check_circle_outline
Search:            search
Filter:            tune
Settings:          settings_outlined
Back:              arrow_back_ios_new
Close:             close
More options:      more_vert
Share:             ios_share
Phone:             phone_outlined
Location:          location_on_outlined
Date:              calendar_today_outlined
Amount/Money:      payments_outlined
Archive:           archive_outlined
Restore:           unarchive_outlined
Offline:           wifi_off
Sync pending:      sync
Sync failed:       sync_problem
Photo:             photo_camera_outlined
Tag:               label_outline
Car lock:          car_repair
Door lock:         door_front_outlined
Smart lock:        lock_outlined

---

## 14.8 Component Specifications

Primary Button:
  Height: 52dp  Radius: radiusFull  Bg: primary700  Text: label white
  Pressed: primary800  Disabled: neutral200 bg + neutral400 text

CTA Button (WhatsApp Follow-up):
  Height: 52dp  Radius: radiusFull  Bg: accent500  Text: label primary900
  Icon: send_outlined 20dp left of text
  Pressed: accent400
  Sent state: success100 bg + success600 text + check_circle_outline icon

Secondary Button:
  Height: 52dp  Radius: radiusFull  Bg: transparent
  Border: 1.5dp primary700  Text: label primary700
  Pressed: primary050 bg

Text Input:
  Height: 52dp  Radius: radiusMd  Bg: neutral100
  Border default: 1dp neutral300
  Border focused: 1.5dp primary600
  Border error: 1.5dp error500
  Label: captionMedium neutral700 above field
  Placeholder: body neutral500
  Error: caption error600 below field

Job Card:
  Bg: white  Radius: radiusLg  Shadow: cardShadow  Padding: cardPadding
  Row 1: service icon (primary500 20dp) + service name (bodyMedium) + date (caption right)
  Row 2: customer name (body neutral700)
  Row 3: location (caption neutral500) + amount (amountSmall right)
  Row 4: follow-up badge if sent (success chip)

Customer Card:
  Bg: white  Radius: radiusLg  Shadow: cardShadow  Padding: cardPadding
  Left: avatar circle (avatarMd, primary100 bg, primary700 initial)
  Right Row 1: customer name (bodyMedium)
  Right Row 2: phone (caption neutral500)
  Right Row 3: total_jobs (caption) + last job date (caption right)

Knowledge Note Card:
  Bg: white  Radius: radiusLg  Shadow: cardShadow  Padding: cardPadding
  Row 1: title (h3)
  Row 2: tags (labelSmall chips, primary100 bg, primary600 text)
  Row 3: service type (caption) + date (caption right)

Tag Chip:
  Height: 28dp  Radius: radiusFull  Bg: primary100
  Text: labelSmall primary600  Padding: horizontal sm

Status Badge:
  Height: 22dp  Radius: radiusFull  Padding: horizontal xs
  Synced:  success100 bg + success600 text
  Pending: warning100 bg + warning600 text
  Failed:  error100 bg + error600 text
  Sent:    success100 bg + success600 text + check icon

Offline Banner:
  Position: below app bar, full width  Height: 36dp
  Bg: offlineBg  Border bottom: 1dp neutral200
  Content: wifi_off icon (neutral500 16dp) + caption text (neutral600)
  Behavior: slides in from top when offline, slides out when reconnected

Empty State:
  Layout: centered vertically and horizontally
  Icon: 48dp neutral300
  Heading: h2 neutral700 centered
  Body: body neutral500 centered max-width 260dp
  CTA: optional primary button below body
  Spacing: huge between elements

Bottom Navigation:
  Height: 64dp  Bg: white  Border top: 1dp neutral200
  Items: 4 — Jobs, Customers, Notes, Profile
  Active: primary700 icon + labelSmall
  Inactive: neutral400 icon + labelSmall

---

## 14.9 Motion

Page transitions:   slide from right (push), fade (modal/bottom sheet)
Duration standard:  200ms
Duration quick:     150ms
Duration slow:      300ms (bottom sheet open only)
Easing:             Curves.easeInOut
Loading indicator:  CircularProgressIndicator primary500 strokeWidth 2.5
Skeleton loader:    neutral100 → neutral200 shimmer for loading lists

---

## 14.10 app_colors.dart (paste-ready)

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary900 = Color(0xFF0A1628);
  static const Color primary800 = Color(0xFF0F2144);
  static const Color primary700 = Color(0xFF163060);
  static const Color primary600 = Color(0xFF1E3F7A);
  static const Color primary500 = Color(0xFF2952A3);
  static const Color primary400 = Color(0xFF4A6EC4);
  static const Color primary100 = Color(0xFFE8EDF7);
  static const Color primary050 = Color(0xFFF3F6FC);

  static const Color accent600 = Color(0xFFB8860B);
  static const Color accent500 = Color(0xFFD4A017);
  static const Color accent400 = Color(0xFFE8B84B);
  static const Color accent100 = Color(0xFFFDF3D0);

  static const Color neutral900 = Color(0xFF1A1A1A);
  static const Color neutral800 = Color(0xFF2D2D2D);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral600 = Color(0xFF5C5C5C);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral400 = Color(0xFF9E9E9E);
  static const Color neutral300 = Color(0xFFBDBDBD);
  static const Color neutral200 = Color(0xFFE0E0E0);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral050 = Color(0xFFFAFAFA);
  static const Color white      = Color(0xFFFFFFFF);

  static const Color success600 = Color(0xFF1B6B3A);
  static const Color success500 = Color(0xFF2E7D32);
  static const Color success100 = Color(0xFFE8F5E9);

  static const Color warning600 = Color(0xFFE65100);
  static const Color warning500 = Color(0xFFF57C00);
  static const Color warning100 = Color(0xFFFFF3E0);

  static const Color error600   = Color(0xFFB71C1C);
  static const Color error500   = Color(0xFFC62828);
  static const Color error100   = Color(0xFFFFEBEE);

  static const Color offline    = Color(0xFF9E9E9E);
  static const Color offlineBg  = Color(0xFFF5F5F5);
}

---

## 14.11 app_spacing.dart (paste-ready)

class AppSpacing {
  AppSpacing._();

  static const double xs    =  4.0;
  static const double sm    =  8.0;
  static const double md    = 12.0;
  static const double lg    = 16.0;
  static const double xl    = 20.0;
  static const double xxl   = 24.0;
  static const double xxxl  = 32.0;
  static const double huge  = 48.0;

  static const double pagePadding       = 16.0;
  static const double cardPadding       = 16.0;
  static const double bottomNavHeight   = 64.0;
  static const double appBarHeight      = 56.0;
  static const double fabOffset         = 80.0;
  static const double inputHeight       = 52.0;
  static const double buttonHeight      = 52.0;
  static const double buttonSmallHeight = 40.0;
  static const double listItemHeight    = 72.0;

  static const double avatarSm  =  32.0;
  static const double avatarMd  =  48.0;
  static const double avatarLg  =  80.0;
  static const double avatarXl  = 120.0;

  static const double radiusSm   =   4.0;
  static const double radiusMd   =   8.0;
  static const double radiusLg   =  12.0;
  static const double radiusXl   =  16.0;
  static const double radiusFull = 999.0;
}

---

## Validation Checklist
- [x] Full color palette with hex values ready to paste into Flutter
- [x] All colors have semantic names — no magic hex in widgets
- [x] Typography scale defined for every text context in the app
- [x] 8-point spacing system with named tokens
- [x] Border radius tokens defined
- [x] Shadow definitions ready to use
- [x] Icon assignments for every feature and action
- [x] Component specs for every UI element in V1
- [x] Offline banner specified
- [x] app_colors.dart and app_spacing.dart paste-ready
