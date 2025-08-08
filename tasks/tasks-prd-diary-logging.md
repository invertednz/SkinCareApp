## Relevant Files

- `lib/features/diary/skin_health_screen.dart` - Skin Health logging UI.
- `lib/features/diary/symptoms_screen.dart` - Symptoms logging UI.
- `lib/features/diary/diet_screen.dart` - Diet logging UI.
- `lib/features/diary/supplements_screen.dart` - Supplements management.
- `lib/features/diary/routine_screen.dart` - Routine management and adherence.
- `lib/features/photos/photo_uploader.dart` - Shared photo capture/upload logic.
- `lib/features/diary/data/diary_repository.dart` - Persistence to Supabase.
- `supabase/schema.sql` - Tables for entries and RLS.

### Notes

- Enforce up to 3 photos per entry, 10MB max each, 4096px max dimension.

## Tasks

- [ ] 1.0 Define DB schema for diary entities and RLS
  - [ ] 1.1 Create tables: `skin_health_entries`, `symptom_entries`, `diet_entries`, `supplement_entries`, `routine_entries`, `photos`
  - [ ] 1.2 Add FKs to user_id; created_at/updated_at; soft-delete flags
  - [ ] 1.3 Add RLS policies for `user_id = auth.uid()` on all tables
  - [ ] 1.4 Add presets tables for `symptom_locations` and `acne_subtypes` (static or seed)
  - [ ] 1.5 Write basic indexes for queries by date range

- [ ] 2.0 Implement logging UIs for Skin Health, Symptoms, Diet, Supplements, Routine
  - [ ] 2.1 Skin Health form with rating sliders and notes
  - [ ] 2.2 Symptoms form with location chips and subtype multi-select
  - [ ] 2.3 Diet flags toggles and free-text notes
  - [ ] 2.4 Supplements list with add/remove and dosage
  - [ ] 2.5 Routine adherence toggles per item
  - [ ] 2.6 Shared photo picker (max 3/photos per entry) and preview

- [ ] 3.0 Implement photo upload pipeline with compression and limits
  - [ ] 3.1 Integrate `photo_uploader.dart` with capture/pick and client-side compression
  - [ ] 3.2 Enforce 10MB and 4096px limits; strip EXIF
  - [ ] 3.3 Upload to Supabase Storage with progress and retries
  - [ ] 3.4 Store metadata rows in `photos` table linked to entry

- [ ] 4.0 Implement history views and 72‑hour edit policy
  - [ ] 4.1 List views grouped by date with filters by type
  - [ ] 4.2 Detail view to read entries and view photos
  - [ ] 4.3 Allow edit/delete within 72 hours; disable actions after window
  - [ ] 4.4 Server-side constraint to prevent edits after 72 hours (policy or trigger)

- [ ] 5.0 Instrument analytics for logging and photo uploads
  - [ ] 5.1 Track `log_create_*` events with `has_photo`
  - [ ] 5.2 Track `photo_upload_start/success/failure`
  - [ ] 5.3 Error handling and retry UX
