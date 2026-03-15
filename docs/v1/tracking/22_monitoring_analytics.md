# DOCUMENT 22 — MONITORING AND ANALYTICS
### Project: Keystone
**Required Inputs:** Document 02 — Market Research, Document 03 — Core Hypothesis, Document 20 — Error Handling
**Privacy law:** Ghana Data Protection Act 2012 (Act 843)
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 22.1 Philosophy

Three goals only:
1. Know if the app is broken — crashes, sync failures, OTP failures
2. Know if V1 is working — are Jeremie and Jean using it daily?
3. Know when to build V2 — what signals mean the franchise model is ready?

No session recordings. No ad tracking. No selling data.
Collect the minimum necessary to run a reliable service.

---

## 22.2 Ghana Data Protection Act 2012 Compliance

Consent before collection:  onboarding disclosure on Screen 03
Purpose limitation:         data collected only for stated app functions
Data minimisation:          collect only what is needed
Right to access:            user data export (V2 feature)
Right to deletion:          account deletion removes all data (V2 feature)
Security:                   Supabase RLS + HTTPS
DPC registration:           required if processing >1000 records — V1 exempt (2 users)

Onboarding disclosure text (Screen 03):
"Keystone stores your job records, customer details, and notes to help you
manage your locksmith business. Your data is stored securely and never sold
or shared with third parties."

---

## 22.3 What to Track

Crash and Error Monitoring (always on — no personal data):
app crash     → error type, stack trace, Flutter version, Android version
sync failure  → error code, retry count, job count (no content)
OTP failure   → error code, phone region prefix only (not full number)
storage error → error code, available storage

Usage Signals (product — lightweight):
app_opened     → event count per day    → daily active usage
job_logged     → count per day          → core loop engagement
follow_up_sent → count per day          → core value delivered
note_saved     → count per week         → knowledge retention
profile_shared → count                  → franchise growth signal

NOT tracked:
Job content, customer names/phones, note content, individual session data,
advertising identifiers, data from other apps

---

## 22.4 app_events Table

CREATE TABLE app_events (
  id         UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_name VARCHAR(50) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE app_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY events_insert_own ON app_events
  FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth_id = auth.uid())
  );

CREATE INDEX idx_app_events_user_date ON app_events(user_id, created_at DESC);

No SELECT policy for users — only admin (developer) can read events.

---

## 22.5 Event Names

class AnalyticsEvents:
  appOpened      = 'app_opened'
  jobLogged      = 'job_logged'
  followUpSent   = 'follow_up_sent'
  noteSaved      = 'note_saved'
  profileShared  = 'profile_shared'
  customerAdded  = 'customer_added'
  syncCompleted  = 'sync_completed'
  syncFailed     = 'sync_failed'

---

## 22.6 Analytics Service

class AnalyticsService:
  Future<void> track(String eventName) async {
    try {
      await _supabase.from('app_events').insert({
        'user_id': _userId,
        'event_name': eventName,
      });
    } catch (_) {
      // Analytics failure NEVER affects app behaviour
      // Silently swallow — never rethrow
    }
  }

Rule: analytics calls are always fire-and-forget. Never block the user. Never throw.

Usage:
  After job saved:        await _analytics.track(AnalyticsEvents.jobLogged)
  After follow-up sent:   await _analytics.track(AnalyticsEvents.followUpSent)
  On app resume:          await _analytics.track(AnalyticsEvents.appOpened)

---

## 22.7 Crash Monitoring

V1: Flutter built-in — developer has physical device access

FlutterError.onError:          debugPrint error + stack trace
PlatformDispatcher.instance.onError: debugPrint + return true (prevents crash)

V2 upgrade: sentry_flutter ^7.19.0
SentryFlutter.init → dsn from --dart-define, tracesSampleRate: 0.1, environment from AppConstants

---

## 22.8 Weekly SQL Dashboard

-- Daily active usage (last 14 days)
SELECT
  DATE(created_at) as date,
  COUNT(DISTINCT user_id) as active_users,
  COUNT(CASE WHEN event_name = 'job_logged' THEN 1 END) as jobs_logged,
  COUNT(CASE WHEN event_name = 'follow_up_sent' THEN 1 END) as followups_sent,
  COUNT(CASE WHEN event_name = 'note_saved' THEN 1 END) as notes_saved
FROM app_events
WHERE created_at > NOW() - INTERVAL '14 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Last seen per user
SELECT
  u.full_name,
  MAX(e.created_at) as last_active,
  NOW() - MAX(e.created_at) as time_since_active
FROM app_events e
JOIN users u ON e.user_id = u.id
GROUP BY u.id, u.full_name;

---

## 22.9 V1 Success Criteria (from Document 03)

App opens ≥5 days/week per user   → active_users in daily query
Jobs logged ≥20 in 8 weeks        → SUM job_logged events
Follow-ups sent ≥1                 → COUNT follow_up_sent events
Notes saved ≥5                     → SUM note_saved events

All targets met at 8 weeks → begin V2 development
Not met → interview Jeremie and Jean, identify friction, fix

---

## 22.10 Alerts — Act Immediately

Zero app_opened for 3+ days   → call Jeremie/Jean directly
OTP failures spiking           → check Africa's Talking dashboard
Sync failures not resolving    → check Supabase logs
App crash on startup           → check Flutter error logs

---

## 22.11 Privacy Summary (Settings Screen)

What Keystone collects:
✓ Your job records, customers, and notes (to run the app)
✓ When you open the app and log jobs (to improve the app)

What Keystone does NOT collect:
✗ Your location (unless you add it to a job)
✗ Your contacts or messages
✗ Advertising identifiers
✗ Data from other apps

Your data is stored securely on Supabase servers in London
and is never sold or shared with third parties.

---

## Validation Checklist
- [x] Ghana DPA 2012 compliance with specific implementations
- [x] Onboarding disclosure text specified
- [x] Event list exhaustive and contains no personal data
- [x] Analytics service is fire-and-forget — never throws
- [x] app_events table with RLS — users insert own only
- [x] V1 success metrics map to Document 03 hypothesis targets
- [x] Weekly SQL dashboard for manual monitoring
- [x] Alert conditions for immediate action
- [x] V2 Sentry upgrade path documented
- [x] Privacy summary for settings screen
