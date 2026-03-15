# DOCUMENT 23 — PRODUCT ROADMAP
### Project: Keystone
**Required Inputs:** Document 01 — Problem Brief, Document 03 — Core Hypothesis, Document 04 — Core Scope
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 23.1 Philosophy

Each phase must prove something before the next phase is built.

V1 proves: Jeremie and Jean will use a digital tool daily.
V2 proves: Other technicians will pay to join their network.
V3 proves: The franchise model scales beyond personal relationships.
V4 proves: Keystone is infrastructure for the informal trade economy.

No phase begins until the previous phase's proof is in hand.

---

## 23.2 Phase Timeline

V1 — Personal Tool       Now → Month 3
V2 — Team Platform       Month 4 → Month 12
V3 — Franchise Network   Month 13 → Month 24
V4 — Industry Platform   Month 25+

---

## 23.3 V1 — Personal Tool

Users: Jeremie and Jean only
Platform: Android only
Distribution: Direct APK

Features:
- Job Logging (under 60 seconds)
- Customer History (instant search)
- Knowledge Base (save and search solutions)
- WhatsApp Follow-up (one-tap deep link)
- Technician Profile (shareable public link)

Success criteria (Document 03):
- Both open app ≥5 days/week for 8 consecutive weeks
- ≥20 jobs logged total
- ≥1 repeat customer from a follow-up
- ≥5 knowledge notes saved
- Both say unprompted the app made a difference

V1 → V2 trigger (all required):
1. All success criteria above met
2. ≥1 inbound request from another technician wanting to join
3. Jeremie and Jean agree to brand ambassador role

Explicitly excluded from V1:
Payments, team management, marketplace, iOS, web, customer interface,
notifications, calendar, invoicing, analytics dashboard.

---

## 23.4 V2 — Team Platform

Users: Jeremie, Jean + up to 10 technicians
Platform: Android + iOS
Distribution: Google Play Store + Apple App Store

New features:
- Invite system — Jeremie/Jean generate invite codes
- Technicians join under Keystone brand (role: technician)
- WhatsApp Business API via 360dialog (~$11/month)
  delivery_confirmed becomes meaningful
- WhatsApp OTP (replaces Africa's Talking SMS)
- Push notifications via FCM
  (job reminders 24h after job with no follow-up, sync alerts)
- Basic analytics dashboard for founding technicians
  (platform-wide counts only — no personal data)
- iOS support (Apple Developer account $99/year)

Pricing:
Free for Jeremie and Jean — forever
GHS 50/month per additional technician (~$4 USD)
At 10 technicians: GHS 400/month revenue
Covers infrastructure costs with ~GHS 200 margin

V2 → V3 trigger:
1. ≥8 active paying technicians for 3 consecutive months
2. ≥3 technicians recruited through referral (not direct outreach)
3. Jeremie and Jean spending ≤2 hours/week on onboarding

---

## 23.5 V3 — Franchise Network

Users: Unlimited technicians
Platform: Android + iOS + Web (public directory)
Model: Digital franchise — technicians join a branded network

New features:
- Self-service signup (no invite code required)
- Franchise standards shown at onboarding
- 30-day probation before full access
- Public directory: "Find a Keystone locksmith near me"
  (SEO-optimised, customers contact via WhatsApp)
- Reputation system: job count badge, member since, founding member badge
- Revenue sharing model (decision at V3 launch):
  Option A: flat GHS 50/month
  Option B: GHS 30/month + GHS 5 per job logged
- Founding technician dashboard (platform overview, activity counts, controls)
- Knowledge base sharing (founding technicians share curated notes with network)

V3 success targets:
- ≥50 active technicians
- ≥70% monthly retention
- ≥10 customer contacts from directory per month
- Jeremie and Jean earning more from Keystone than direct jobs

V3 → V4 trigger:
1. Inbound interest from outside Ghana (Ivory Coast, Nigeria, Senegal)
2. ≥100 active technicians
3. Customers actively searching "Keystone locksmith"

---

## 23.6 V4 — Industry Platform

Users: Multi-trade, multi-country
Timeframe: Month 25+

New features:
- Booking engine with mobile money payments (MTN MoMo, Vodafone Cash)
- Multi-trade expansion (electricians, plumbers, AC technicians)
- West Africa expansion: Ivory Coast, Nigeria, Senegal
  (each market needs local founding technicians — V1 model repeated)
- Enterprise tier: GHS 500+/month for security companies and property managers
- SLA tracking, bulk dispatch, team assignment

Revenue at V4 scale:
GHS 20,000+/month across tiers and markets
Comparable to Workiz/Jobber but Africa-native

---

## 23.7 Feature Gate Summary

Feature                          V1   V2   V3   V4
Job logging                      ✅   ✅   ✅   ✅
Customer history                 ✅   ✅   ✅   ✅
Knowledge base                   ✅   ✅   ✅   ✅
WhatsApp follow-up (deep link)   ✅   →API →API →API
Technician profile               ✅   ✅   ✅   ✅
iOS support                      ❌   ✅   ✅   ✅
Push notifications               ❌   ✅   ✅   ✅
Team management                  ❌   ✅   ✅   ✅
WhatsApp Business API            ❌   ✅   ✅   ✅
Analytics dashboard              ❌   ✅   ✅   ✅
Public directory                 ❌   ❌   ✅   ✅
Reputation system                ❌   ❌   ✅   ✅
Knowledge sharing                ❌   ❌   ✅   ✅
Booking engine                   ❌   ❌   ❌   ✅
Mobile money payments            ❌   ❌   ❌   ✅
Multi-trade                      ❌   ❌   ❌   ✅
West Africa expansion            ❌   ❌   ❌   ✅

---

## 23.8 Revenue by Phase

V1: GHS 0         (free — proving the tool)
V2: GHS 400–500   (10 technicians × GHS 50)
V3: GHS 2,000–5,000 (50 technicians, revenue share)
V4: GHS 20,000+   (tiered SaaS + booking commission + enterprise)

---

## 23.9 The Jeremie and Jean Founding Principle

Jeremie and Jean are not just early users. They are founding partners.

Their permanent rights:
- Free access to Keystone forever
- Founding technician badge on all profiles
- Revenue share from technicians they directly recruited
- Veto on brand standards changes
- Named in the app's About section

The developer's commitment:
- Build only what makes Jeremie and Jean's work better first
- Never build a feature that competes with or undermines their business
- Advance notice of any pricing changes
- Formal equity conversation if the platform reaches V4 scale

This is not a legal agreement. It is a founding principle.
The product succeeds if Jeremie and Jean succeed. That alignment is the strategy.

---

## Validation Checklist
- [x] V1 scope exactly matches Document 04 — no feature creep
- [x] V1 success criteria match Document 03 hypothesis
- [x] Phase triggers are specific and measurable
- [x] V2 pricing covers infrastructure costs with margin
- [x] Feature gate table covers all 4 phases
- [x] Revenue model shows path to sustainability
- [x] Jeremie and Jean founding principle documented
- [x] V4 vision grounded in V1 foundations
- [x] Each phase proves something before next phase begins
- [x] West Africa expansion anchored in V1 model repeated
