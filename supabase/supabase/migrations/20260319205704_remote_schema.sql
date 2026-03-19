drop extension if exists "pg_net";

create extension if not exists "citext" with schema "public";

create type "public"."service_type" as enum ('car_lock_programming', 'door_lock_installation', 'door_lock_repair', 'smart_lock_installation');

create type "public"."sync_status" as enum ('pending', 'synced', 'failed');

create type "public"."user_role" as enum ('technician', 'founding_technician', 'admin');

create type "public"."user_status" as enum ('pending', 'active', 'suspended');


  create table "public"."app_events" (
    "id" uuid not null default gen_random_uuid(),
    "user_id" uuid,
    "event_name" text not null,
    "properties" jsonb default '{}'::jsonb,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."app_events" enable row level security;


  create table "public"."correction_requests" (
    "id" uuid not null default gen_random_uuid(),
    "job_id" uuid not null,
    "user_id" uuid not null,
    "reason" text not null,
    "status" text not null default 'pending'::text,
    "admin_notes" text,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."correction_requests" enable row level security;


  create table "public"."customers" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "user_id" uuid not null,
    "full_name" character varying(100) not null,
    "phone_number" public.citext not null,
    "location" character varying(255),
    "notes" character varying(1000),
    "total_jobs" integer not null default 0,
    "last_job_at" timestamp with time zone,
    "deleted_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."customers" enable row level security;


  create table "public"."follow_ups" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "job_id" uuid not null,
    "user_id" uuid not null,
    "customer_id" uuid not null,
    "message_text" character varying(1000) not null,
    "sent_at" timestamp with time zone not null default now(),
    "delivery_confirmed" boolean not null default false,
    "created_at" timestamp with time zone not null default now()
      );


alter table "public"."follow_ups" enable row level security;


  create table "public"."jobs" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "user_id" uuid not null,
    "customer_id" uuid not null,
    "service_type" public.service_type not null,
    "job_date" date not null default CURRENT_DATE,
    "location" character varying(255),
    "latitude" numeric(9,6),
    "longitude" numeric(9,6),
    "notes" character varying(2000),
    "amount_charged" numeric(8,2),
    "follow_up_sent" boolean not null default false,
    "follow_up_sent_at" timestamp with time zone,
    "sync_status" public.sync_status not null default 'pending'::public.sync_status,
    "is_archived" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."jobs" enable row level security;


  create table "public"."knowledge_notes" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "user_id" uuid not null,
    "title" character varying(200) not null,
    "description" text not null,
    "tags" text[] default '{}'::text[],
    "photo_url" character varying(500),
    "service_type" public.service_type,
    "is_archived" boolean not null default false,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."knowledge_notes" enable row level security;


  create table "public"."profiles" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "user_id" uuid not null,
    "display_name" character varying(100) not null,
    "bio" character varying(300),
    "photo_url" character varying(500),
    "services" public.service_type[] not null default '{}'::public.service_type[],
    "whatsapp_number" public.citext not null,
    "is_public" boolean not null default true,
    "profile_url" character varying(255) not null,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."profiles" enable row level security;


  create table "public"."users" (
    "id" uuid not null default extensions.uuid_generate_v4(),
    "auth_id" uuid,
    "full_name" character varying(100) not null,
    "phone_number" public.citext not null,
    "email" public.citext,
    "role" public.user_role not null default 'technician'::public.user_role,
    "status" public.user_status not null default 'pending'::public.user_status,
    "profile_slug" character varying(50) not null,
    "last_seen_at" timestamp with time zone,
    "created_at" timestamp with time zone not null default now(),
    "updated_at" timestamp with time zone not null default now()
      );


alter table "public"."users" enable row level security;

CREATE UNIQUE INDEX app_events_pkey ON public.app_events USING btree (id);

CREATE UNIQUE INDEX correction_requests_pkey ON public.correction_requests USING btree (id);

CREATE UNIQUE INDEX customers_phone_unique_per_user ON public.customers USING btree (user_id, phone_number);

CREATE UNIQUE INDEX customers_pkey ON public.customers USING btree (id);

CREATE UNIQUE INDEX follow_ups_job_id_key ON public.follow_ups USING btree (job_id);

CREATE UNIQUE INDEX follow_ups_pkey ON public.follow_ups USING btree (id);

CREATE INDEX idx_customers_full_name ON public.customers USING gin (to_tsvector('english'::regconfig, (full_name)::text));

CREATE INDEX idx_customers_not_deleted ON public.customers USING btree (user_id) WHERE (deleted_at IS NULL);

CREATE INDEX idx_customers_phone ON public.customers USING btree (user_id, phone_number);

CREATE INDEX idx_customers_user_id ON public.customers USING btree (user_id);

CREATE INDEX idx_follow_ups_job_id ON public.follow_ups USING btree (job_id);

CREATE INDEX idx_follow_ups_user_id ON public.follow_ups USING btree (user_id);

CREATE INDEX idx_jobs_customer_id ON public.jobs USING btree (customer_id);

CREATE INDEX idx_jobs_follow_up ON public.jobs USING btree (user_id, follow_up_sent);

CREATE INDEX idx_jobs_job_date ON public.jobs USING btree (user_id, job_date DESC);

CREATE INDEX idx_jobs_service_type ON public.jobs USING btree (user_id, service_type);

CREATE INDEX idx_jobs_sync_status ON public.jobs USING btree (user_id, sync_status) WHERE (sync_status <> 'synced'::public.sync_status);

CREATE INDEX idx_jobs_user_id ON public.jobs USING btree (user_id);

CREATE INDEX idx_knowledge_notes_not_archived ON public.knowledge_notes USING btree (user_id) WHERE (is_archived = false);

CREATE INDEX idx_knowledge_notes_search ON public.knowledge_notes USING gin (to_tsvector('english'::regconfig, (((title)::text || ' '::text) || description)));

CREATE INDEX idx_knowledge_notes_tags ON public.knowledge_notes USING gin (tags);

CREATE INDEX idx_knowledge_notes_user_id ON public.knowledge_notes USING btree (user_id);

CREATE INDEX idx_profiles_is_public ON public.profiles USING btree (is_public) WHERE (is_public = true);

CREATE INDEX idx_profiles_profile_url ON public.profiles USING btree (profile_url);

CREATE INDEX idx_users_phone ON public.users USING btree (phone_number);

CREATE INDEX idx_users_profile_slug ON public.users USING btree (profile_slug);

CREATE INDEX idx_users_role ON public.users USING btree (role);

CREATE UNIQUE INDEX jobs_pkey ON public.jobs USING btree (id);

CREATE UNIQUE INDEX knowledge_notes_pkey ON public.knowledge_notes USING btree (id);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

CREATE UNIQUE INDEX profiles_profile_url_key ON public.profiles USING btree (profile_url);

CREATE UNIQUE INDEX profiles_user_id_key ON public.profiles USING btree (user_id);

CREATE UNIQUE INDEX users_auth_id_key ON public.users USING btree (auth_id);

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

CREATE UNIQUE INDEX users_phone_number_key ON public.users USING btree (phone_number);

CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);

CREATE UNIQUE INDEX users_profile_slug_key ON public.users USING btree (profile_slug);

alter table "public"."app_events" add constraint "app_events_pkey" PRIMARY KEY using index "app_events_pkey";

alter table "public"."correction_requests" add constraint "correction_requests_pkey" PRIMARY KEY using index "correction_requests_pkey";

alter table "public"."customers" add constraint "customers_pkey" PRIMARY KEY using index "customers_pkey";

alter table "public"."follow_ups" add constraint "follow_ups_pkey" PRIMARY KEY using index "follow_ups_pkey";

alter table "public"."jobs" add constraint "jobs_pkey" PRIMARY KEY using index "jobs_pkey";

alter table "public"."knowledge_notes" add constraint "knowledge_notes_pkey" PRIMARY KEY using index "knowledge_notes_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."users" add constraint "users_pkey" PRIMARY KEY using index "users_pkey";

alter table "public"."app_events" add constraint "app_events_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."app_events" validate constraint "app_events_user_id_fkey";

alter table "public"."correction_requests" add constraint "correction_requests_job_id_fkey" FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE not valid;

alter table "public"."correction_requests" validate constraint "correction_requests_job_id_fkey";

alter table "public"."correction_requests" add constraint "correction_requests_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'rejected'::text]))) not valid;

alter table "public"."correction_requests" validate constraint "correction_requests_status_check";

alter table "public"."correction_requests" add constraint "correction_requests_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(auth_id) ON DELETE CASCADE not valid;

alter table "public"."correction_requests" validate constraint "correction_requests_user_id_fkey";

alter table "public"."customers" add constraint "customers_full_name_check" CHECK ((char_length((full_name)::text) >= 2)) not valid;

alter table "public"."customers" validate constraint "customers_full_name_check";

alter table "public"."customers" add constraint "customers_phone_unique_per_user" UNIQUE using index "customers_phone_unique_per_user";

alter table "public"."customers" add constraint "customers_total_jobs_check" CHECK ((total_jobs >= 0)) not valid;

alter table "public"."customers" validate constraint "customers_total_jobs_check";

alter table "public"."customers" add constraint "customers_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."customers" validate constraint "customers_user_id_fkey";

alter table "public"."follow_ups" add constraint "follow_ups_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES public.customers(id) not valid;

alter table "public"."follow_ups" validate constraint "follow_ups_customer_id_fkey";

alter table "public"."follow_ups" add constraint "follow_ups_job_id_fkey" FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE not valid;

alter table "public"."follow_ups" validate constraint "follow_ups_job_id_fkey";

alter table "public"."follow_ups" add constraint "follow_ups_job_id_key" UNIQUE using index "follow_ups_job_id_key";

alter table "public"."follow_ups" add constraint "follow_ups_message_text_check" CHECK ((char_length((message_text)::text) >= 10)) not valid;

alter table "public"."follow_ups" validate constraint "follow_ups_message_text_check";

alter table "public"."follow_ups" add constraint "follow_ups_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."follow_ups" validate constraint "follow_ups_user_id_fkey";

alter table "public"."jobs" add constraint "jobs_amount_charged_check" CHECK ((amount_charged >= (0)::numeric)) not valid;

alter table "public"."jobs" validate constraint "jobs_amount_charged_check";

alter table "public"."jobs" add constraint "jobs_coordinates_together" CHECK ((((latitude IS NULL) AND (longitude IS NULL)) OR ((latitude IS NOT NULL) AND (longitude IS NOT NULL)))) not valid;

alter table "public"."jobs" validate constraint "jobs_coordinates_together";

alter table "public"."jobs" add constraint "jobs_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES public.customers(id) not valid;

alter table "public"."jobs" validate constraint "jobs_customer_id_fkey";

alter table "public"."jobs" add constraint "jobs_date_not_future" CHECK ((job_date <= CURRENT_DATE)) not valid;

alter table "public"."jobs" validate constraint "jobs_date_not_future";

alter table "public"."jobs" add constraint "jobs_latitude_check" CHECK (((latitude >= ('-90'::integer)::numeric) AND (latitude <= (90)::numeric))) not valid;

alter table "public"."jobs" validate constraint "jobs_latitude_check";

alter table "public"."jobs" add constraint "jobs_longitude_check" CHECK (((longitude >= ('-180'::integer)::numeric) AND (longitude <= (180)::numeric))) not valid;

alter table "public"."jobs" validate constraint "jobs_longitude_check";

alter table "public"."jobs" add constraint "jobs_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE not valid;

alter table "public"."jobs" validate constraint "jobs_user_id_fkey";

alter table "public"."knowledge_notes" add constraint "knowledge_notes_description_check" CHECK ((char_length(description) >= 10)) not valid;

alter table "public"."knowledge_notes" validate constraint "knowledge_notes_description_check";

alter table "public"."knowledge_notes" add constraint "knowledge_notes_max_tags" CHECK (((array_length(tags, 1) <= 10) OR (tags = '{}'::text[]))) not valid;

alter table "public"."knowledge_notes" validate constraint "knowledge_notes_max_tags";

alter table "public"."knowledge_notes" add constraint "knowledge_notes_title_check" CHECK ((char_length((title)::text) >= 3)) not valid;

alter table "public"."knowledge_notes" validate constraint "knowledge_notes_title_check";

alter table "public"."knowledge_notes" add constraint "knowledge_notes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."knowledge_notes" validate constraint "knowledge_notes_user_id_fkey";

alter table "public"."profiles" add constraint "profiles_display_name_check" CHECK ((char_length((display_name)::text) >= 2)) not valid;

alter table "public"."profiles" validate constraint "profiles_display_name_check";

alter table "public"."profiles" add constraint "profiles_profile_url_key" UNIQUE using index "profiles_profile_url_key";

alter table "public"."profiles" add constraint "profiles_services_not_empty" CHECK ((array_length(services, 1) >= 1)) not valid;

alter table "public"."profiles" validate constraint "profiles_services_not_empty";

alter table "public"."profiles" add constraint "profiles_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "profiles_user_id_fkey";

alter table "public"."profiles" add constraint "profiles_user_id_key" UNIQUE using index "profiles_user_id_key";

alter table "public"."users" add constraint "users_auth_id_fkey" FOREIGN KEY (auth_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."users" validate constraint "users_auth_id_fkey";

alter table "public"."users" add constraint "users_auth_id_key" UNIQUE using index "users_auth_id_key";

alter table "public"."users" add constraint "users_email_key" UNIQUE using index "users_email_key";

alter table "public"."users" add constraint "users_full_name_check" CHECK ((char_length((full_name)::text) >= 2)) not valid;

alter table "public"."users" validate constraint "users_full_name_check";

alter table "public"."users" add constraint "users_phone_number_key" UNIQUE using index "users_phone_number_key";

alter table "public"."users" add constraint "users_profile_slug_key" UNIQUE using index "users_profile_slug_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.batch_sync_customers(p_user_id uuid, p_customers jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  customer_record JSONB;
  new_customer_id UUID;
  synced_customers JSONB := '[]'::jsonb;
  failed_customers JSONB := '[]'::jsonb;
BEGIN
  FOR customer_record IN SELECT * FROM jsonb_array_elements(p_customers)
  LOOP
    BEGIN
      INSERT INTO customers (id, user_id, full_name, phone_number, location, notes, deleted_at)
      VALUES (
        (customer_record->>'id')::UUID,
        p_user_id,
        customer_record->>'full_name',
        customer_record->>'phone_number',
        customer_record->>'location',
        customer_record->>'notes',
        (customer_record->>'deleted_at')::TIMESTAMPTZ
      )
      ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        location = COALESCE(EXCLUDED.location, customers.location),
        notes = COALESCE(EXCLUDED.notes, customers.notes),
        deleted_at = EXCLUDED.deleted_at,
        updated_at = NOW()
      RETURNING id INTO new_customer_id;

      synced_customers := synced_customers || jsonb_build_object(
        'local_id', customer_record->>'id',
        'server_id', new_customer_id,
        'sync_status', 'synced'
      );
    EXCEPTION WHEN OTHERS THEN
      failed_customers := failed_customers || jsonb_build_object(
        'local_id', customer_record->>'id',
        'error', SQLERRM
      );
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_customers, 'failed', failed_customers);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.batch_sync_jobs(p_user_id uuid, p_jobs jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := '[]'::jsonb;
  failed_jobs JSONB := '[]'::jsonb;
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      -- UPSERT: Insert or Update if the job already exists
      INSERT INTO jobs (id, user_id, customer_id, service_type, job_date, location, notes, amount_charged, sync_status)
      VALUES (
        (job_record->>'id')::UUID,
        p_user_id,
        (job_record->>'customer_id')::UUID,
        (job_record->>'service_type')::service_type,
        (job_record->>'job_date')::DATE,
        job_record->>'location',
        job_record->>'notes',
        (job_record->>'amount_charged')::DECIMAL,
        'synced'
      )
      ON CONFLICT (id) DO UPDATE SET
        location = EXCLUDED.location,
        notes = EXCLUDED.notes,
        amount_charged = EXCLUDED.amount_charged,
        sync_status = EXCLUDED.sync_status,
        updated_at = NOW()
      RETURNING id INTO new_job_id;

      -- Use 'id' from the record to satisfy the Dart lookup
      synced_jobs := synced_jobs || jsonb_build_object(
        'local_id', job_record->>'id',
        'server_id', new_job_id,
        'sync_status', 'synced'
      );
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object(
        'local_id', job_record->>'id',
        'error', SQLERRM
      );
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'synced', synced_jobs,
    'failed', failed_jobs
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.enforce_job_field_lock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NOW() > OLD.created_at + INTERVAL '24 hours' THEN
    IF NEW.service_type IS DISTINCT FROM OLD.service_type THEN
      RAISE EXCEPTION 'Service type cannot be changed after 24 hours.'
        USING ERRCODE = 'check_violation';
    END IF;
    IF NEW.job_date IS DISTINCT FROM OLD.job_date THEN
      RAISE EXCEPTION 'Job date cannot be changed after 24 hours.'
        USING ERRCODE = 'check_violation';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_profile_slug()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
  base_slug TEXT;
  final_slug TEXT;
  counter INTEGER := 1;
BEGIN
  base_slug := lower(regexp_replace(NEW.full_name, '[^a-zA-Z0-9\s]', '', 'g'));
  base_slug := regexp_replace(base_slug, '\s+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  final_slug := base_slug;
  WHILE EXISTS (SELECT 1 FROM users WHERE profile_slug = final_slug AND id != NEW.id) LOOP
    final_slug := base_slug || '-' || counter;
    counter := counter + 1;
  END LOOP;
  NEW.profile_slug := final_slug;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_customer_job_stats()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE customers
    SET total_jobs = total_jobs + 1, last_job_at = NEW.created_at, updated_at = NOW()
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_job_follow_up_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE jobs
  SET follow_up_sent = TRUE, follow_up_sent_at = NEW.sent_at, updated_at = NOW()
  WHERE id = NEW.job_id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."app_events" to "anon";

grant insert on table "public"."app_events" to "anon";

grant references on table "public"."app_events" to "anon";

grant select on table "public"."app_events" to "anon";

grant trigger on table "public"."app_events" to "anon";

grant truncate on table "public"."app_events" to "anon";

grant update on table "public"."app_events" to "anon";

grant delete on table "public"."app_events" to "authenticated";

grant insert on table "public"."app_events" to "authenticated";

grant references on table "public"."app_events" to "authenticated";

grant select on table "public"."app_events" to "authenticated";

grant trigger on table "public"."app_events" to "authenticated";

grant truncate on table "public"."app_events" to "authenticated";

grant update on table "public"."app_events" to "authenticated";

grant delete on table "public"."app_events" to "service_role";

grant insert on table "public"."app_events" to "service_role";

grant references on table "public"."app_events" to "service_role";

grant select on table "public"."app_events" to "service_role";

grant trigger on table "public"."app_events" to "service_role";

grant truncate on table "public"."app_events" to "service_role";

grant update on table "public"."app_events" to "service_role";

grant delete on table "public"."correction_requests" to "anon";

grant insert on table "public"."correction_requests" to "anon";

grant references on table "public"."correction_requests" to "anon";

grant select on table "public"."correction_requests" to "anon";

grant trigger on table "public"."correction_requests" to "anon";

grant truncate on table "public"."correction_requests" to "anon";

grant update on table "public"."correction_requests" to "anon";

grant delete on table "public"."correction_requests" to "authenticated";

grant insert on table "public"."correction_requests" to "authenticated";

grant references on table "public"."correction_requests" to "authenticated";

grant select on table "public"."correction_requests" to "authenticated";

grant trigger on table "public"."correction_requests" to "authenticated";

grant truncate on table "public"."correction_requests" to "authenticated";

grant update on table "public"."correction_requests" to "authenticated";

grant delete on table "public"."correction_requests" to "service_role";

grant insert on table "public"."correction_requests" to "service_role";

grant references on table "public"."correction_requests" to "service_role";

grant select on table "public"."correction_requests" to "service_role";

grant trigger on table "public"."correction_requests" to "service_role";

grant truncate on table "public"."correction_requests" to "service_role";

grant update on table "public"."correction_requests" to "service_role";

grant delete on table "public"."customers" to "anon";

grant insert on table "public"."customers" to "anon";

grant references on table "public"."customers" to "anon";

grant select on table "public"."customers" to "anon";

grant trigger on table "public"."customers" to "anon";

grant truncate on table "public"."customers" to "anon";

grant update on table "public"."customers" to "anon";

grant delete on table "public"."customers" to "authenticated";

grant insert on table "public"."customers" to "authenticated";

grant references on table "public"."customers" to "authenticated";

grant select on table "public"."customers" to "authenticated";

grant trigger on table "public"."customers" to "authenticated";

grant truncate on table "public"."customers" to "authenticated";

grant update on table "public"."customers" to "authenticated";

grant delete on table "public"."customers" to "service_role";

grant insert on table "public"."customers" to "service_role";

grant references on table "public"."customers" to "service_role";

grant select on table "public"."customers" to "service_role";

grant trigger on table "public"."customers" to "service_role";

grant truncate on table "public"."customers" to "service_role";

grant update on table "public"."customers" to "service_role";

grant delete on table "public"."follow_ups" to "anon";

grant insert on table "public"."follow_ups" to "anon";

grant references on table "public"."follow_ups" to "anon";

grant select on table "public"."follow_ups" to "anon";

grant trigger on table "public"."follow_ups" to "anon";

grant truncate on table "public"."follow_ups" to "anon";

grant update on table "public"."follow_ups" to "anon";

grant delete on table "public"."follow_ups" to "authenticated";

grant insert on table "public"."follow_ups" to "authenticated";

grant references on table "public"."follow_ups" to "authenticated";

grant select on table "public"."follow_ups" to "authenticated";

grant trigger on table "public"."follow_ups" to "authenticated";

grant truncate on table "public"."follow_ups" to "authenticated";

grant update on table "public"."follow_ups" to "authenticated";

grant delete on table "public"."follow_ups" to "service_role";

grant insert on table "public"."follow_ups" to "service_role";

grant references on table "public"."follow_ups" to "service_role";

grant select on table "public"."follow_ups" to "service_role";

grant trigger on table "public"."follow_ups" to "service_role";

grant truncate on table "public"."follow_ups" to "service_role";

grant update on table "public"."follow_ups" to "service_role";

grant delete on table "public"."jobs" to "anon";

grant insert on table "public"."jobs" to "anon";

grant references on table "public"."jobs" to "anon";

grant select on table "public"."jobs" to "anon";

grant trigger on table "public"."jobs" to "anon";

grant truncate on table "public"."jobs" to "anon";

grant update on table "public"."jobs" to "anon";

grant delete on table "public"."jobs" to "authenticated";

grant insert on table "public"."jobs" to "authenticated";

grant references on table "public"."jobs" to "authenticated";

grant select on table "public"."jobs" to "authenticated";

grant trigger on table "public"."jobs" to "authenticated";

grant truncate on table "public"."jobs" to "authenticated";

grant update on table "public"."jobs" to "authenticated";

grant delete on table "public"."jobs" to "service_role";

grant insert on table "public"."jobs" to "service_role";

grant references on table "public"."jobs" to "service_role";

grant select on table "public"."jobs" to "service_role";

grant trigger on table "public"."jobs" to "service_role";

grant truncate on table "public"."jobs" to "service_role";

grant update on table "public"."jobs" to "service_role";

grant delete on table "public"."knowledge_notes" to "anon";

grant insert on table "public"."knowledge_notes" to "anon";

grant references on table "public"."knowledge_notes" to "anon";

grant select on table "public"."knowledge_notes" to "anon";

grant trigger on table "public"."knowledge_notes" to "anon";

grant truncate on table "public"."knowledge_notes" to "anon";

grant update on table "public"."knowledge_notes" to "anon";

grant delete on table "public"."knowledge_notes" to "authenticated";

grant insert on table "public"."knowledge_notes" to "authenticated";

grant references on table "public"."knowledge_notes" to "authenticated";

grant select on table "public"."knowledge_notes" to "authenticated";

grant trigger on table "public"."knowledge_notes" to "authenticated";

grant truncate on table "public"."knowledge_notes" to "authenticated";

grant update on table "public"."knowledge_notes" to "authenticated";

grant delete on table "public"."knowledge_notes" to "service_role";

grant insert on table "public"."knowledge_notes" to "service_role";

grant references on table "public"."knowledge_notes" to "service_role";

grant select on table "public"."knowledge_notes" to "service_role";

grant trigger on table "public"."knowledge_notes" to "service_role";

grant truncate on table "public"."knowledge_notes" to "service_role";

grant update on table "public"."knowledge_notes" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";

grant delete on table "public"."users" to "anon";

grant insert on table "public"."users" to "anon";

grant references on table "public"."users" to "anon";

grant select on table "public"."users" to "anon";

grant trigger on table "public"."users" to "anon";

grant truncate on table "public"."users" to "anon";

grant update on table "public"."users" to "anon";

grant delete on table "public"."users" to "authenticated";

grant insert on table "public"."users" to "authenticated";

grant references on table "public"."users" to "authenticated";

grant select on table "public"."users" to "authenticated";

grant trigger on table "public"."users" to "authenticated";

grant truncate on table "public"."users" to "authenticated";

grant update on table "public"."users" to "authenticated";

grant delete on table "public"."users" to "service_role";

grant insert on table "public"."users" to "service_role";

grant references on table "public"."users" to "service_role";

grant select on table "public"."users" to "service_role";

grant trigger on table "public"."users" to "service_role";

grant truncate on table "public"."users" to "service_role";

grant update on table "public"."users" to "service_role";


  create policy "app_events_insert_own"
  on "public"."app_events"
  as permissive
  for insert
  to authenticated
with check (((auth.uid() = user_id) OR (user_id IS NULL)));



  create policy "app_events_select_own"
  on "public"."app_events"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "Admins can update correction requests"
  on "public"."correction_requests"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))))
with check ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))));



  create policy "Admins can view all correction requests"
  on "public"."correction_requests"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))));



  create policy "Users can create their own correction requests"
  on "public"."correction_requests"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = user_id));



  create policy "Users can view their own correction requests"
  on "public"."correction_requests"
  as permissive
  for select
  to authenticated
using ((auth.uid() = user_id));



  create policy "Admins can update all customers"
  on "public"."customers"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))))
with check ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))));



  create policy "Admins can view all customers"
  on "public"."customers"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))));



  create policy "customers_delete_own"
  on "public"."customers"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "customers_insert_own"
  on "public"."customers"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "customers_select_own"
  on "public"."customers"
  as permissive
  for select
  to public
using (((auth.uid() = user_id) AND (deleted_at IS NULL)));



  create policy "customers_update_own"
  on "public"."customers"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "followups_insert_own"
  on "public"."follow_ups"
  as permissive
  for insert
  to public
with check ((user_id IN ( SELECT users.id
   FROM public.users
  WHERE (users.auth_id = auth.uid()))));



  create policy "followups_select_own"
  on "public"."follow_ups"
  as permissive
  for select
  to public
using ((user_id IN ( SELECT users.id
   FROM public.users
  WHERE (users.auth_id = auth.uid()))));



  create policy "Admins can update all jobs"
  on "public"."jobs"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))))
with check ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))));



  create policy "Admins can view all jobs"
  on "public"."jobs"
  as permissive
  for select
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.users
  WHERE ((users.auth_id = auth.uid()) AND (users.role = 'admin'::public.user_role)))));



  create policy "jobs_insert_own"
  on "public"."jobs"
  as permissive
  for insert
  to public
with check ((user_id IN ( SELECT users.id
   FROM public.users
  WHERE (users.auth_id = auth.uid()))));



  create policy "jobs_select_own"
  on "public"."jobs"
  as permissive
  for select
  to public
using ((user_id IN ( SELECT users.id
   FROM public.users
  WHERE (users.auth_id = auth.uid()))));



  create policy "jobs_update_own"
  on "public"."jobs"
  as permissive
  for update
  to public
using ((user_id IN ( SELECT users.id
   FROM public.users
  WHERE (users.auth_id = auth.uid()))));



  create policy "notes_delete_own"
  on "public"."knowledge_notes"
  as permissive
  for delete
  to public
using ((auth.uid() = user_id));



  create policy "notes_insert_own"
  on "public"."knowledge_notes"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "notes_select_own"
  on "public"."knowledge_notes"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "notes_update_own"
  on "public"."knowledge_notes"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "profiles_insert_own"
  on "public"."profiles"
  as permissive
  for insert
  to public
with check ((auth.uid() = user_id));



  create policy "profiles_public_read"
  on "public"."profiles"
  as permissive
  for select
  to public
using ((is_public = true));



  create policy "profiles_select_own"
  on "public"."profiles"
  as permissive
  for select
  to public
using ((auth.uid() = user_id));



  create policy "profiles_update_own"
  on "public"."profiles"
  as permissive
  for update
  to public
using ((auth.uid() = user_id));



  create policy "users_founding_read_all"
  on "public"."users"
  as permissive
  for select
  to public
using (((auth.jwt() ->> 'role'::text) = ANY (ARRAY['founding_technician'::text, 'admin'::text])));



  create policy "users_insert_own"
  on "public"."users"
  as permissive
  for insert
  to public
with check ((auth.uid() = auth_id));



  create policy "users_select_own"
  on "public"."users"
  as permissive
  for select
  to public
using ((auth.uid() = auth_id));



  create policy "users_update_own"
  on "public"."users"
  as permissive
  for update
  to public
using ((auth.uid() = auth_id));


CREATE TRIGGER update_correction_requests_updated_at BEFORE UPDATE ON public.correction_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_update_job_follow_up AFTER INSERT ON public.follow_ups FOR EACH ROW EXECUTE FUNCTION public.update_job_follow_up_status();

CREATE TRIGGER trigger_enforce_job_lock BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.enforce_job_field_lock();

CREATE TRIGGER trigger_update_customer_stats AFTER INSERT ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.update_customer_job_stats();

CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_knowledge_notes_updated_at BEFORE UPDATE ON public.knowledge_notes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trigger_generate_profile_slug BEFORE INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.generate_profile_slug();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


  create policy "storage_note_photos_insert"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'note-photos'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "storage_note_photos_read"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'note-photos'::text));



  create policy "storage_profile_photos_insert"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'profile-photos'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



  create policy "storage_profile_photos_read"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'profile-photos'::text));



  create policy "storage_profile_photos_update"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'profile-photos'::text) AND ((auth.uid())::text = (storage.foldername(name))[1])));



