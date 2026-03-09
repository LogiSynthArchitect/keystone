# DOCUMENT 12 — DATABASE SCHEMA
### Project: Keystone
**Required Inputs:** Document 07 — Domain Model, Document 10 — Validation Rules, Document 11 — API Contracts
**Backend:** Supabase (PostgreSQL)
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 12.1 Extensions Required

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable case-insensitive text search
CREATE EXTENSION IF NOT EXISTS "citext";

---

## 12.2 Enums

CREATE TYPE user_role AS ENUM (
  'technician',
  'founding_technician',
  'admin'
);

CREATE TYPE user_status AS ENUM (
  'pending',
  'active',
  'suspended'
);

CREATE TYPE service_type AS ENUM (
  'car_lock_programming',
  'door_lock_installation',
  'door_lock_repair',
  'smart_lock_installation'
);

CREATE TYPE sync_status AS ENUM (
  'pending',
  'synced',
  'failed'
);

---

## 12.3 Tables

-- users
CREATE TABLE users (
  id                UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  auth_id           UUID          UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name         VARCHAR(100)  NOT NULL CHECK (char_length(full_name) >= 2),
  phone_number      CITEXT        UNIQUE NOT NULL,
  email             CITEXT        UNIQUE,
  role              user_role     NOT NULL DEFAULT 'technician',
  status            user_status   NOT NULL DEFAULT 'pending',
  profile_slug      VARCHAR(50)   UNIQUE NOT NULL,
  last_seen_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_profile_slug ON users(profile_slug);
CREATE INDEX idx_users_role ON users(role);

-- profiles
CREATE TABLE profiles (
  id               UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID          UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  display_name     VARCHAR(100)  NOT NULL CHECK (char_length(display_name) >= 2),
  bio              VARCHAR(300),
  photo_url        VARCHAR(500),
  services         service_type[] NOT NULL DEFAULT '{}',
  whatsapp_number  CITEXT        NOT NULL,
  is_public        BOOLEAN       NOT NULL DEFAULT TRUE,
  profile_url      VARCHAR(255)  UNIQUE NOT NULL,
  created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT profiles_services_not_empty CHECK (array_length(services, 1) >= 1)
);

CREATE INDEX idx_profiles_profile_url ON profiles(profile_url);
CREATE INDEX idx_profiles_is_public ON profiles(is_public) WHERE is_public = TRUE;

-- customers
CREATE TABLE customers (
  id            UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  full_name     VARCHAR(100)  NOT NULL CHECK (char_length(full_name) >= 2),
  phone_number  CITEXT        NOT NULL,
  location      VARCHAR(255),
  notes         VARCHAR(1000),
  total_jobs    INTEGER       NOT NULL DEFAULT 0 CHECK (total_jobs >= 0),
  last_job_at   TIMESTAMPTZ,
  deleted_at    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT customers_phone_unique_per_user UNIQUE (user_id, phone_number)
);

CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_full_name ON customers USING gin(to_tsvector('english', full_name));
CREATE INDEX idx_customers_phone ON customers(user_id, phone_number);
CREATE INDEX idx_customers_not_deleted ON customers(user_id) WHERE deleted_at IS NULL;

-- jobs
CREATE TABLE jobs (
  id                  UUID           PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id             UUID           NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  customer_id         UUID           NOT NULL REFERENCES customers(id),
  service_type        service_type   NOT NULL,
  job_date            DATE           NOT NULL DEFAULT CURRENT_DATE,
  location            VARCHAR(255),
  latitude            DECIMAL(9,6)   CHECK (latitude BETWEEN -90 AND 90),
  longitude           DECIMAL(9,6)   CHECK (longitude BETWEEN -180 AND 180),
  notes               VARCHAR(2000),
  amount_charged      DECIMAL(8,2)   CHECK (amount_charged > 0),
  follow_up_sent      BOOLEAN        NOT NULL DEFAULT FALSE,
  follow_up_sent_at   TIMESTAMPTZ,
  sync_status         sync_status    NOT NULL DEFAULT 'pending',
  is_archived         BOOLEAN        NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
  CONSTRAINT jobs_date_not_future CHECK (job_date <= CURRENT_DATE),
  CONSTRAINT jobs_coordinates_together CHECK (
    (latitude IS NULL AND longitude IS NULL) OR
    (latitude IS NOT NULL AND longitude IS NOT NULL)
  )
);

CREATE INDEX idx_jobs_user_id ON jobs(user_id);
CREATE INDEX idx_jobs_customer_id ON jobs(customer_id);
CREATE INDEX idx_jobs_job_date ON jobs(user_id, job_date DESC);
CREATE INDEX idx_jobs_service_type ON jobs(user_id, service_type);
CREATE INDEX idx_jobs_follow_up ON jobs(user_id, follow_up_sent);
CREATE INDEX idx_jobs_sync_status ON jobs(user_id, sync_status) WHERE sync_status != 'synced';

-- knowledge_notes
CREATE TABLE knowledge_notes (
  id            UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title         VARCHAR(200)  NOT NULL CHECK (char_length(title) >= 3),
  description   TEXT          NOT NULL CHECK (char_length(description) >= 10),
  tags          TEXT[]        DEFAULT '{}',
  photo_url     VARCHAR(500),
  service_type  service_type,
  is_archived   BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  CONSTRAINT knowledge_notes_max_tags CHECK (array_length(tags, 1) <= 10 OR tags = '{}')
);

CREATE INDEX idx_knowledge_notes_user_id ON knowledge_notes(user_id);
CREATE INDEX idx_knowledge_notes_search ON knowledge_notes
  USING gin(to_tsvector('english', title || ' ' || description));
CREATE INDEX idx_knowledge_notes_tags ON knowledge_notes USING gin(tags);
CREATE INDEX idx_knowledge_notes_not_archived ON knowledge_notes(user_id)
  WHERE is_archived = FALSE;

-- follow_ups
CREATE TABLE follow_ups (
  id                  UUID          PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id              UUID          UNIQUE NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  user_id             UUID          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  customer_id         UUID          NOT NULL REFERENCES customers(id),
  message_text        VARCHAR(1000) NOT NULL CHECK (char_length(message_text) >= 10),
  sent_at             TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  delivery_confirmed  BOOLEAN       NOT NULL DEFAULT FALSE,
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_follow_ups_job_id ON follow_ups(job_id);
CREATE INDEX idx_follow_ups_user_id ON follow_ups(user_id);

---

## 12.4 Triggers

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_jobs_updated_at
  BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_knowledge_notes_updated_at
  BEFORE UPDATE ON knowledge_notes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION update_customer_job_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE customers
    SET total_jobs = total_jobs + 1, last_job_at = NEW.created_at, updated_at = NOW()
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_stats
  AFTER INSERT ON jobs FOR EACH ROW EXECUTE FUNCTION update_customer_job_stats();

CREATE OR REPLACE FUNCTION update_job_follow_up_status()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE jobs
  SET follow_up_sent = TRUE, follow_up_sent_at = NEW.sent_at, updated_at = NOW()
  WHERE id = NEW.job_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_job_follow_up
  AFTER INSERT ON follow_ups FOR EACH ROW EXECUTE FUNCTION update_job_follow_up_status();

CREATE OR REPLACE FUNCTION enforce_job_field_lock()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_enforce_job_lock
  BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION enforce_job_field_lock();

CREATE OR REPLACE FUNCTION generate_profile_slug()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_profile_slug
  BEFORE INSERT ON users FOR EACH ROW EXECUTE FUNCTION generate_profile_slug();

---

## 12.5 Row Level Security

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE follow_ups ENABLE ROW LEVEL SECURITY;

-- users RLS
CREATE POLICY users_select_own ON users
  FOR SELECT USING (auth.uid() = auth_id);
CREATE POLICY users_update_own ON users
  FOR UPDATE USING (auth.uid() = auth_id);
CREATE POLICY users_founding_read_all ON users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users u WHERE u.auth_id = auth.uid() AND u.role IN ('founding_technician', 'admin'))
  );

-- profiles RLS
CREATE POLICY profiles_public_read ON profiles
  FOR SELECT USING (is_public = TRUE);
CREATE POLICY profiles_select_own ON profiles
  FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY profiles_update_own ON profiles
  FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY profiles_insert_own ON profiles
  FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- customers RLS
CREATE POLICY customers_select_own ON customers
  FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()) AND deleted_at IS NULL);
CREATE POLICY customers_insert_own ON customers
  FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY customers_update_own ON customers
  FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- jobs RLS
CREATE POLICY jobs_select_own ON jobs
  FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY jobs_insert_own ON jobs
  FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY jobs_update_own ON jobs
  FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- knowledge_notes RLS
CREATE POLICY notes_select_own ON knowledge_notes
  FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY notes_insert_own ON knowledge_notes
  FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY notes_update_own ON knowledge_notes
  FOR UPDATE USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

-- follow_ups RLS
CREATE POLICY followups_select_own ON follow_ups
  FOR SELECT USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));
CREATE POLICY followups_insert_own ON follow_ups
  FOR INSERT WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()));

---

## 12.6 Database Functions

CREATE OR REPLACE FUNCTION batch_sync_jobs(p_user_id UUID, p_jobs JSONB)
RETURNS JSONB AS $$
DECLARE
  job_record JSONB;
  new_job_id UUID;
  synced_jobs JSONB := '[]';
  failed_jobs JSONB := '[]';
BEGIN
  FOR job_record IN SELECT * FROM jsonb_array_elements(p_jobs)
  LOOP
    BEGIN
      INSERT INTO jobs (user_id, customer_id, service_type, job_date, location, notes, amount_charged, sync_status)
      VALUES (
        p_user_id,
        (job_record->>'customer_id')::UUID,
        (job_record->>'service_type')::service_type,
        (job_record->>'job_date')::DATE,
        job_record->>'location',
        job_record->>'notes',
        (job_record->>'amount_charged')::DECIMAL,
        'synced'
      ) RETURNING id INTO new_job_id;
      synced_jobs := synced_jobs || jsonb_build_object('local_id', job_record->>'local_id', 'server_id', new_job_id, 'sync_status', 'synced');
    EXCEPTION WHEN OTHERS THEN
      failed_jobs := failed_jobs || jsonb_build_object('local_id', job_record->>'local_id', 'error', SQLERRM);
    END;
  END LOOP;
  RETURN jsonb_build_object('synced', synced_jobs, 'failed', failed_jobs);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

---

## 12.7 Storage Buckets

INSERT INTO storage.buckets (id, name, public) VALUES ('profile-photos', 'profile-photos', TRUE);
INSERT INTO storage.buckets (id, name, public) VALUES ('note-photos', 'note-photos', TRUE);

CREATE POLICY storage_profile_photos_insert ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'profile-photos' AND auth.uid()::TEXT = (storage.foldername(name))[1]);
CREATE POLICY storage_note_photos_insert ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'note-photos' AND auth.uid()::TEXT = (storage.foldername(name))[1]);
CREATE POLICY storage_profile_photos_read ON storage.objects
  FOR SELECT USING (bucket_id = 'profile-photos');
CREATE POLICY storage_note_photos_read ON storage.objects
  FOR SELECT USING (bucket_id = 'note-photos');

---

## 12.8 Execution Order

1. Extensions     (12.1)
2. Enums          (12.2)
3. Tables         (12.3) in order: users, profiles, customers, jobs, knowledge_notes, follow_ups
4. Triggers       (12.4)
5. RLS Enable     (12.5 ALTER TABLE statements first)
6. RLS Policies   (12.5 CREATE POLICY statements)
7. Functions      (12.6)
8. Storage        (12.7)

---

## Validation Checklist
- [x] All 6 entities have tables with correct field types
- [x] All enums defined and match Document 07
- [x] All foreign key relationships defined
- [x] All CHECK constraints match Document 10 validation rules
- [x] updated_at triggers on all relevant tables
- [x] customer stats auto-updated via trigger
- [x] job follow_up_sent auto-updated via trigger
- [x] job field lock enforced via trigger
- [x] profile_slug auto-generated via trigger
- [x] RLS enabled and policies defined for all tables
- [x] Storage buckets created with RLS policies
- [x] batch_sync_jobs function supports offline-first sync
- [x] Execution order documented
