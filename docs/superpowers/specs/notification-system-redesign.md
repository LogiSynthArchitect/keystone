# Notification & Reminder System Redesign

## Problem Summary

The current reminder system has 9 critical gaps:

1. **No background execution** — reminders only fire while app is open
2. **ReminderRepositoryImpl is all TODO stubs** — no Supabase persistence (5 methods)
3. **Notification tap does nothing** — `main.dart` handler is empty `if (jobId != null) { }`
4. **`_notifiedKeys` static set never cleaned up** — dismissed-then-recreated reminders won't re-fire
5. **RESEND button is `() {}`** — WhatsApp resend from reminder card does nothing
6. **Threshold save doesn't trigger `refresh()`** — user must wait for next job list change
7. **`recurring_job_overdue` missing from Supabase CHECK constraint** — would crash on INSERT
8. **Notification content is bare** — just service type, no customer name or location
9. **Reminder computation tied to Notifier lifecycle** — can't run in background without duplication

## Architecture

```
┌──────────────────┐     periodic check (workmanager)  ┌──────────────────────┐
│   Workmanager    │ ────────────────────────────────→  │  ReminderEngine      │
│  (headless iso)  │                                    │  (standalone)        │
└──────────────────┘                                    │                      │
                                                        │  1. Build input:     │
┌──────────────────┐     same code path                 │     jobs, thresholds │
│  RemindersScreen │ ←─────────────────────────────    │     followUps, etc.  │
│  (in-app)        │                                    │  2. Compute reminders│
└──────────────────┘                                    │  3. Persist to       │
                                                        │     Supabase table   │
┌──────────────────┐                                    │  4. Fire local       │
│  ReminderRepo    │ ←───────────────────────────────  │     notifications    │
│  (Supabase)      │                                    └──────────────────────┘
└──────────────────┘
```

Key principle: **One computation engine, two call sites** (in-app + background).

## Design Decisions

1. **No FCM/push** — Periodic polling via workmanager (15-min Android minimum) is sufficient for this use case. Reminders are not urgent alerts. FCM is a future upgrade that layers on top of the same Supabase data.

2. **ReminderEntity in Supabase** — The `reminder_entity.dart` already defines the DB schema. We need to implement the CRUD and ensure all 5 reminder types have matching CHECK constraints.

3. **Notification tap → job detail** — The payload already carries `jobId`. We need to wire GoRouter navigation to `/jobs/:id` (or equivalent route).

4. **RESEND from reminder card** — Reuses existing WhatsApp follow-up infrastructure. The card already has the `onResend` slot — just needs the actual send call.

5. **`_notifiedKeys` cleanup** — Remove keys from the static set when: (a) reminder is dismissed, (b) reminder no longer matches conditions (job paid, status changed, etc.)

6. **No cross-device sync in v1** — Supabase persistence makes it possible, but we only read/write from the current device. Background worker runs on each device independently.

## Files Changed

| # | File | Action |
|---|------|--------|
| 1 | `lib/features/reminders/engine/reminder_engine.dart` | **Create** — standalone computation |
| 2 | `lib/features/reminders/engine/reminder_worker.dart` | **Create** — workmanager callback |
| 3 | `lib/features/reminders/data/repositories/reminder_repository_impl.dart` | **Modify** — implement all 5 methods |
| 4 | `lib/features/reminders/presentation/providers/reminders_provider.dart` | **Modify** — delegate to engine, fix `_notifiedKeys`, fix threshold refresh |
| 5 | `lib/features/reminders/presentation/screens/reminder_settings_screen.dart` | **Modify** — trigger refresh on save |
| 6 | `lib/core/widgets/ks_reminder_card.dart` | **Modify** — wire RESEND |
| 7 | `lib/core/services/local_notification_service.dart` | **Modify** — enrich content, add jobId payload |
| 8 | `lib/main.dart` | **Modify** — wire notification tap, register workmanager |
| 9 | `pubspec.yaml` | **Modify** — add `workmanager` |
| 10 | Supabase migration | **Create** — fix CHECK constraint |
