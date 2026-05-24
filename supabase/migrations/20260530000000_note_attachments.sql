-- Knowledge Notes: add attachments JSONB column
ALTER TABLE public.knowledge_notes
ADD COLUMN IF NOT EXISTS attachments jsonb DEFAULT '[]'::jsonb;

-- Storage bucket for note attachments (PDFs, audio recordings, etc.)
INSERT INTO storage.buckets (id, name, public)
VALUES ('note-attachments', 'note-attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload files to note-attachments
CREATE POLICY "note_attachments_insert_own"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'note-attachments'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to select their own files
CREATE POLICY "note_attachments_select_own"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'note-attachments');

-- Allow anyone to download public files
CREATE POLICY "note_attachments_select_public"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'note-attachments');
