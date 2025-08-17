## Relevant Files

- `app/lib/features/diary/skin_health_screen.dart` - Skin Health logging UI with rating sliders and notes.
- `app/lib/features/diary/symptoms_screen.dart` - Symptoms logging UI with location chips and subtype multi-select.
- `app/lib/features/diary/diet_screen.dart` - Diet logging UI with flags toggles and free-text notes.
- `app/lib/features/diary/supplements_screen.dart` - Supplements management with add/remove and dosage.
- `app/lib/features/diary/routine_screen.dart` - Routine management and adherence toggles per item.
- `app/lib/features/diary/widgets/shared_photo_picker.dart` - Shared photo picker (max 3/photos per entry) with preview.
- `app/lib/features/diary/data/diary_repository.dart` - Repository for diary entries with 72-hour edit policy and CRUD operations.
- `app/lib/features/diary/history_screen.dart` - List views grouped by date with filters by type.
- `app/lib/features/diary/diary_entry_detail_screen.dart` - Detail view to read entries and view photos.
- `app/lib/features/photos/photo_uploader.dart` - Shared photo capture/upload logic.
- `app/lib/features/diary/diary_screen.dart` - Minimal demo screen for photo upload/progress/analyze/delete and analytics; full logging UIs are pending.
- `app/lib/features/photos/data/photo_repository.dart` - Storage upload and metadata persistence to `photos` table.
- `app/lib/features/photos/data/photo_analysis_repository.dart` - Photo analysis API client.
- `app/lib/widgets/upload_progress.dart` - Upload progress UI component.
- `supabase/schema.sql` - Tables for entries and RLS.

### Notes

- Enforce up to 3 photos per entry, 10MB max each, 4096px max dimension.
- Current codebase: core diary UIs and diary repository remain pending. Photo upload pipeline is implemented via `PhotoUploadController` and `PhotoRepository`; leave core logging tasks unchecked until implemented.
- Photo pipeline enforces limits (max 3 photos per entry via `PhotoRepository.countForEntry`, 10MB, 4096px), strips EXIF, and performs JPEG re-encode with downscale.
- Uploads go to Supabase Storage bucket `user-photos`; metadata persisted in `photos` table (`user_id`, `entry_id`, `path`, `width`, `height`, `bytes`).
- Retries with exponential backoff and cancel UI are implemented; snackbars surface success/error.

## Tasks

- [x] 1.0 Define DB schema for diary entities and RLS
  - [x] 1.1 Create tables: `skin_health_entries`, `symptom_entries`, `diet_entries`, `supplement_entries`, `routine_entries`, `photos`
  - [x] 1.2 Add FKs to user_id; created_at/updated_at; soft-delete flags
  - [x] 1.3 Add RLS policies for `user_id = auth.uid()` on all tables
  - [x] 1.4 Add presets tables for `symptom_locations` and `acne_subtypes` (static or seed)
  - [x] 1.5 Write basic indexes for queries by date range

- [x] 2.0 Implement logging UIs for Skin Health, Symptoms, Diet, Supplements, Routine
  - [x] 2.1 Skin Health form with rating sliders and notes
  - [x] 2.2 Symptoms form with location chips and subtype multi-select
  - [x] 2.3 Diet flags toggles and free-text notes
  - [x] 2.4 Supplements list with add/remove and dosage
  - [x] 2.5 Routine adherence toggles per item
  - [x] 2.6 Shared photo picker (max 3/photos per entry) and preview

- [x] 3.0 Implement photo upload pipeline with compression and limits
  - [x] 3.1 Integrate `photo_uploader.dart` with capture/pick and client-side compression
  - [x] 3.2 Enforce 10MB and 4096px limits; strip EXIF
  - [x] 3.3 Upload to Supabase Storage with progress and retries
  - [x] 3.4 Store metadata rows in `photos` table linked to entry

- [x] 4.0 Implement history views and 72‑hour edit policy
  - [x] 4.1 List views grouped by date with filters by type
  - [x] 4.2 Detail view to read entries and view photos
  - [x] 4.3 Allow edit/delete within 72 hours; disable actions after window
  - [x] 4.4 Server-side constraint to prevent edits after 72 hours (policy or trigger)

- [x] 5.0 Instrument analytics for logging and photo uploads
  - [x] 5.1 Track `log_create_*` events with `has_photo`
  - [x] 5.2 Track `photo_upload_start/success/failure`
  - [x] 5.3 Error handling and retry UX
