-- Knowledge Notes: Client-Side UUIDv4 as Absolute PK
-- Change id from server-generated default to client-supplied.

-- 1. Remove the default so the server accepts client-supplied UUIDs
ALTER TABLE public.knowledge_notes ALTER COLUMN id DROP DEFAULT;

-- 2. Upsert function for idempotent sync (ON CONFLICT DO UPDATE)
CREATE OR REPLACE FUNCTION public.upsert_knowledge_note(payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result jsonb;
BEGIN
  INSERT INTO public.knowledge_notes (
    id, user_id, title, description, tags, photo_url, cover_image_url,
    service_type, media_type, attachments, is_archived, is_pinned,
    created_at, updated_at
  )
  SELECT
    (payload->>'id')::uuid,
    (payload->>'user_id')::uuid,
    payload->>'title',
    payload->>'description',
    COALESCE((payload->>'tags')::jsonb, '[]'::jsonb),
    payload->>'photo_url',
    payload->>'cover_image_url',
    payload->>'service_type',
    COALESCE(payload->>'media_type', 'image'),
    COALESCE((payload->>'attachments')::jsonb, '[]'::jsonb),
    COALESCE((payload->>'is_archived')::boolean, false),
    COALESCE((payload->>'is_pinned')::boolean, false),
    COALESCE((payload->>'created_at')::timestamptz, now()),
    COALESCE((payload->>'updated_at')::timestamptz, now())
  ON CONFLICT (id) DO UPDATE SET
    title           = EXCLUDED.title,
    description     = EXCLUDED.description,
    tags            = EXCLUDED.tags,
    photo_url       = EXCLUDED.photo_url,
    cover_image_url = EXCLUDED.cover_image_url,
    service_type    = EXCLUDED.service_type,
    media_type      = EXCLUDED.media_type,
    attachments     = EXCLUDED.attachments,
    is_archived     = EXCLUDED.is_archived,
    is_pinned       = EXCLUDED.is_pinned,
    updated_at      = EXCLUDED.updated_at
  RETURNING row_to_json(public.knowledge_notes.*)::jsonb INTO result;

  RETURN result;
END;
$$;

-- 3. Optional BEFORE INSERT trigger for UUIDv4 format validation
CREATE OR REPLACE FUNCTION public.validate_note_uuid()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.id IS NULL THEN
    RAISE EXCEPTION 'knowledge_notes.id must be provided by the client (UUIDv4)';
  END IF;
  -- UUIDv4 has a specific version nibble (0x4 in position 15)
  IF substring(NEW.id::text FROM 15 FOR 1) != '4' THEN
    RAISE WARNING 'knowledge_notes.id % is not a UUIDv4 (version nibble != 4)', NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_note_uuid ON public.knowledge_notes;
CREATE TRIGGER trg_validate_note_uuid
  BEFORE INSERT ON public.knowledge_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_note_uuid();
