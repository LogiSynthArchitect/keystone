# Developer Guide: Supabase Integration & ID Usage

## ID Selection Matrix
Always check this matrix before writing a new Repository or UseCase.

| Data Category | Target Table | Required ID | Why? |
| --- | --- | --- | --- |
| **Identity** | `profiles` | `auth_id` | Linked to Auth.users for security. |
| **Business** | `jobs` | `id` | Matches the `user_id` FK in the schema. |
| **Business** | `customers` | `id` | Matches the `user_id` FK in the schema. |
| **Tracking** | `app_events`| `auth_id` | Uses RLS `auth.uid() = user_id`. |

## The "Invisible Data" Trap
If a technician says "I can't see my jobs," check these three things in order:
1. Does the technician have a record in `auth.users`?
2. Does the technician have a record in `public.users` where `auth_id` matches?
3. In the `jobs` table, does the `user_id` match the `id` from `public.users` (NOT the Auth UID)?

## Adding New Tables
1. **Always** enable RLS.
2. **Always** use `uuid_generate_v4()` for the primary key.
3. If the data is private to the user, add a `user_id` column and link it to `public.users(id)`.
