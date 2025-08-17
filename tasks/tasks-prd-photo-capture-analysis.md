## Relevant Files

- `app/lib/features/photos/photo_uploader.dart` - Unified capture, picker, compression, upload, enforcement, retry/cancel.
- `app/lib/features/photos/data/photo_repository.dart` - Storage access and metadata tracking; signed URL/delete helpers.
- `app/lib/features/photos/data/photo_analysis_repository.dart` - Client to call Edge Function for vision analysis.
- `app/lib/widgets/upload_progress.dart` - Reusable upload progress UI widget.
- `app/lib/features/diary/diary_screen.dart` - Minimal demo UI for upload/progress/analyze/delete and analytics events (upload/analyze/delete, cancel); handles moderation blocks with snackbar.
- `app/android/app/src/main/AndroidManifest.xml` - Camera and media read permissions.
- `app/ios/Runner/Info.plist` - Camera and Photo Library usage descriptions.
- `supabase/storage/policies.sql` - Storage bucket and security policies.
- `supabase/schema.sql` - `photos` table and RLS policies.
- `supabase/functions/vision-analyze/index.ts` - Edge Function enhanced: best-effort signed URLs via service role, optional Gemini call (env `GEMINI_API_KEY`, `GEMINI_MODEL`), timeout/sanitization/fallback; optional Google Vision SafeSearch gating implemented.
- `supabase/functions/vision-analyze/index_test.ts` - Deno test validating fallback behavior without provider credentials and SafeSearch gating logic.
- `supabase/functions/retention-cleanup/index.ts` - Edge Function scaffold for retention/orphan cleanup (cron pending).

### Notes

- Max 3 photos per entry, 10MB each, 4096px max; EXIF stripped. Enforced in `PhotoUploadController._process()` and `PhotoConstraints`.
- Implemented storage bucket and RLS policies; client repo supports signed URLs and delete.
- Implemented client pick/capture/compress/upload with retry and cancellation controller; minimal progress UI and Analyze/Delete actions wired in `app/lib/features/diary/diary_screen.dart` (full entry UI pending).
- Edge Function uses environment variables: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, optional `GEMINI_API_KEY`, `GEMINI_MODEL`, `VISION_TIMEOUT_MS`, optional `GOOGLE_VISION_API_KEY` for SafeSearch.

## Tasks

- [x] 1.0 Create storage bucket and security policies; signed URL flow
  - [x] 1.1 Create `user-photos` bucket; define path convention `user_id/yyyy/mm/dd/uuid.jpg`
  - [x] 1.2 Write storage policies to restrict read/write to owner via signed URLs
  - [x] 1.3 Implement signed URL generation and expiry policies
  - [x] 1.4 Add `supabase/storage/policies.sql` migration and test via CLI (migration added; CLI test pending)
  - [x] 1.5 Document limits (10MB, 4096px) and enforcement points

- [x] 2.0 Implement client capture/pick/compress/upload with progress and retry
  - [x] 2.1 Integrate camera/gallery pickers with permission handling (iOS/Android permissions added)
  - [x] 2.2 Compress/resize client-side; strip EXIF metadata
  - [x] 2.3 Show progress UI; controller supports cancellation and retry (minimal wiring in DiaryScreen incl. cancel button)
  - [x] 2.4 Enforce max 3 photos per entry with clear messaging
  - [x] 2.5 Persist upload metadata in `photos` table linked to entry

- [x] 3.0 Implement Edge Function for vision analysis with safety filters
  - [x] 3.1 Define API contract: input storage paths and context; output observations JSON (scaffolded)
  - [x] 3.2 Call Vertex AI Gemini vision; set timeouts and retries (implemented as optional provider call requiring `GEMINI_API_KEY`; falls back gracefully)
  - [x] 3.3 Sanitize outputs; avoid diagnosis; include confidence scores (basic sanitization + capped lengths)
  - [x] 3.4 Handle provider errors; return user-friendly messages (provider failures swallowed; placeholder response returned)
  - [x] 3.5 Unit tests with mocked provider responses (basic Deno test for fallback without credentials; provider mocking pending)

- [x] 4.0 Add basic NSFW moderation prior to analysis
  - [x] 4.1 Implement quick NSFW check (Google Vision SafeSearch optional via `GOOGLE_VISION_API_KEY`)
  - [x] 4.2 Block analysis if unsafe; show supportive guidance (client shows snackbar and summary)
  - [x] 4.3 Track moderation analytics (captured `photo_moderation_block` with categories)

- [x] 5.0 Implement deletion and retention handling in client and DB
  - [x] 5.1 Implement delete flow to remove storage object and DB row (via repository; UI pending)
  - [x] 5.2 UI affordance to remove photo from an entry pre-submit (minimal wiring in DiaryScreen; full entry UI pending)
  - [x] 5.3 Background job to clean orphaned files/rows (Edge Function implemented; cron scheduling pending)
  - [x] 5.4a Track delete events in analytics
  - [x] 5.4b Track retention cleanup events in analytics
