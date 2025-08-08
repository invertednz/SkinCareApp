## Relevant Files

- `lib/features/photos/photo_uploader.dart` - Unified capture, picker, and upload logic.
- `lib/features/photos/data/photo_repository.dart` - Storage access and metadata tracking.
- `supabase/functions/vision-analyze/index.ts` - Vision analysis via Vertex AI.
- `supabase/storage/policies.sql` - Storage bucket and security policies.

### Notes

- Max 3 photos per entry, 10MB each, 4096px max; EXIF stripped.

## Tasks

- [ ] 1.0 Create storage bucket and security policies; signed URL flow
  - [ ] 1.1 Create `user-photos` bucket; define path convention `user_id/yyyy/mm/dd/uuid.jpg`
  - [ ] 1.2 Write storage policies to restrict read/write to owner via signed URLs
  - [ ] 1.3 Implement signed URL generation and expiry policies
  - [ ] 1.4 Add `supabase/storage/policies.sql` migration and test via CLI
  - [ ] 1.5 Document limits (10MB, 4096px) and enforcement points

- [ ] 2.0 Implement client capture/pick/compress/upload with progress and retry
  - [ ] 2.1 Integrate camera/gallery pickers with permission handling
  - [ ] 2.2 Compress/resize client-side; strip EXIF metadata
  - [ ] 2.3 Show progress UI, cancellation, and retry with exponential backoff
  - [ ] 2.4 Enforce max 3 photos per entry with clear messaging
  - [ ] 2.5 Persist upload metadata in `photos` table linked to entry

- [ ] 3.0 Implement Edge Function for vision analysis with safety filters
  - [ ] 3.1 Define API contract: input photo URLs and context; output observations JSON
  - [ ] 3.2 Call Vertex AI Gemini vision; set timeouts and retries
  - [ ] 3.3 Sanitize outputs; avoid diagnosis; include confidence scores
  - [ ] 3.4 Handle provider errors; return user-friendly messages
  - [ ] 3.5 Unit tests with mocked provider responses

- [ ] 4.0 Add basic NSFW moderation prior to analysis
  - [ ] 4.1 Implement quick NSFW check (provider or lightweight model)
  - [ ] 4.2 Block upload/analysis if unsafe; show supportive guidance
  - [ ] 4.3 Track `photo_upload_failure` with category nsfw

- [ ] 5.0 Implement deletion and retention handling in client and DB
  - [ ] 5.1 Implement delete flow to remove storage object and DB row
  - [ ] 5.2 UI affordance to remove photo from an entry pre-submit
  - [ ] 5.3 Background job to clean orphaned files/rows
  - [ ] 5.4 Track delete and retention events in analytics
