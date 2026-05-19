ALTER TABLE public.job_photos
  ADD COLUMN media_type text NOT NULL DEFAULT 'image'
  CHECK (media_type IN ('image', 'video', 'audio'));

ALTER TABLE public.knowledge_notes
  ADD COLUMN media_type text NOT NULL DEFAULT 'image'
  CHECK (media_type IN ('image', 'video', 'audio'));
