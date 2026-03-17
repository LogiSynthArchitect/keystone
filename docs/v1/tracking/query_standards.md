# WHATSAPP QUERY STANDARDS
### Project: Keystone
### Purpose: Standardized SQL patterns for querying WhatsApp follow-up data

---

## 1. Context: Sent vs. Delivered
In the Keystone database, the `follow_ups` table tracks technician interactions. It is critical to distinguish between a technician **triggering** the intent and the system **confirming** delivery.

- **`follow_up_sent`**: This indicates the technician tapped the "Send WhatsApp" button in the app. This is an **intent** marker.
- **`delivery_confirmed`**: This indicates that the message has been confirmed as delivered (Note: In V1, this is always `FALSE` as we use the `wa.me` deep link without a callback API).

---

## 2. Standard Query Patterns

### A. Count All Triggered Follow-ups
Use this to measure technician engagement.
```sql
SELECT count(*) 
FROM public.follow_ups 
WHERE created_at >= '2026-03-01';
```

### B. Identify Jobs WITHOUT Follow-ups
Use this to find missed opportunities.
```sql
SELECT j.id, j.job_date, u.full_name as technician
FROM public.jobs j
JOIN public.users u ON j.user_id = u.auth_id
LEFT JOIN public.follow_ups f ON j.id = f.job_id
WHERE f.id IS NULL
AND j.is_archived = false;
```

### C. Confirmed Delivery (V2+ Readiness)
In V1, this will return 0 rows. Use this only for future platform monitoring.
```sql
SELECT * 
FROM public.follow_ups 
WHERE follow_up_sent = true 
AND delivery_confirmed = true;
```

---

## 3. Data Integrity Warnings
- **DO NOT** use `follow_up_sent` alone to claim a customer received a message.
- **ALWAYS** join with the `users` table to identify which technician triggered the intent.
- **NEVER** assume a `TRUE` value in `follow_up_sent` means the message was actually sent *inside* the WhatsApp app (as the user could have cancelled at the last second).
