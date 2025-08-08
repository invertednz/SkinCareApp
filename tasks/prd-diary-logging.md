# Diary & Logging PRD

## Overview
Implement daily logging across Skin Health, Symptoms, Diet, Supplements, and Routine. Use mockups as guidance; prioritize reliable data entry, photo uploads, and history views. Online-only MVP.

## Goals
- Fast, structured logging with minimal friction.
- Photos stored securely; entries available for insights and chat personalization.

## User Stories
- As a user, I can log daily skin health with mood/skin ratings, hydration, sensitivity, notes, and photos.
- As a user, I can log symptoms with types, severity, location, notes, and photos.
- As a user, I can log diet by meals with categories and photos, and track water.
- As a user, I can manage supplements and mark intake.
- As a user, I can manage AM/PM routines and mark adherence.

## Functional Requirements
1. Skin Health entry (daily): mood (1–5), skin score (1–5), hydration (slider 0–100), sensitivity (slider 0–100), notes, photo(s) up to 3.
2. Symptoms entry: severity (0–10), types (acne, redness, dryness, other), acne subtypes, location (face map presets), notes, photo(s) up to 3.
3. Diet: meals (breakfast, lunch, dinner, snacks) with free text, categories (dairy, gluten, spicy, sugar, processed, alcohol, caffeine), photo(s) up to 3, daily water intake.
4. Supplements: catalog (name, category, dosage, frequency, time of day, with food, purpose, notes, photo), intake toggles/history.
5. Routine: AM/PM steps (ordered list: product name, description, duration/approx time), reminders toggle, adherence mark per day.
6. History views: recent entries per section with date/time and thumbnails.
7. Editing policy: allow edits within 72 hours of entry; after that, entries are read‑only. Admin override not required in MVP.
8. Validation: secure input sizes; image size limit (e.g., 10 MB) and resolution cap (e.g., max dimension 4096px) before upload; max 3 photos per entry across all sections.
9. Online‑only: show clear messages when offline.

### Presets
- Symptom locations (checklist): forehead, temples, cheeks, nose, chin, jawline, perioral (around mouth), hairline, neck, back, chest, T‑zone (forehead/nose), U‑zone (cheeks/jaw).
- Acne subtypes: whiteheads (closed comedones), blackheads (open comedones), papules, pustules, nodules, cysts, hormonal jawline acne.

## Data Model (Supabase)
- `skin_health_entries` (id, user_id, date, mood, skin_score, hydration, sensitivity, notes, photos[])
- `symptom_entries` (id, user_id, ts, severity, types[], acne_subtypes[], locations[], notes, photos[])
- `diet_entries` (id, user_id, date, meal, text, categories[], photos[])
- `water_intake` (id, user_id, date, ml)
- `supplements` (id, user_id, name, category, dosage, frequency, time_of_day, with_food, purpose, notes, photo)
- `supplement_intake` (id, user_id, supplement_id, ts, taken boolean)
- `routines` (id, user_id, period ENUM('AM','PM'), order_index, product_name, description, duration_min)
- `routine_adherence` (id, user_id, date, period, completed boolean)
- All tables: RLS user_id = auth.uid().

## Non-Goals
- Barcode scanning or food database integrations.
- Complex face mapping; use preset areas checklist.

## Technical Considerations
- Supabase Storage for images; signed URLs.
- Client-side compression before upload.
- Batched writes where possible.

## Success Metrics
- Daily active log rate (any section) baseline >30% of new users.
- Median time to log a Skin Health entry < 45 seconds.

## Open Questions
- None.
