# Photo Capture & Analysis PRD

## Overview
Enable photo capture/upload across relevant flows (chat, skin health, symptoms, diet, supplements, routine) and analyze images using a vision LLM model. Use Supabase Storage for files.

## Goals
- Reliable photo capture and uploads with size constraints.
- Vision analysis available in chat and insights as needed.

## User Stories
- As a user, I can attach photos when I log entries.
- As a user, I can upload a photo in chat and ask questions about it.

## Functional Requirements
1. Storage: Supabase Storage bucket `user-photos`; organize paths by user_id/date; signed URLs for access.
2. Limits: max 10 MB per photo; max dimension 4096px; client-side compression before upload; up to 3 photos per entry across all sections.
3. Retention: photos retained until deleted by user; deletion removes from storage and references in DB.
4. Consent: uploading photos constitutes consent; onboarding also informs users (no opt-out separate toggle).
5. Analysis: use Google Vertex AI Gemini vision models via Edge Function; return safe, high-level observations; avoid diagnosis.
6. Metadata: store EXIF-stripped by default; record created_at, section, and optional notes.

## Non-Goals
- Dermatology-grade classification.

## Technical Considerations
- Background uploads with progress UI; retry on transient failures.
- Image moderation before analysis (basic NSFW filter).
- Cost control: cap number of vision calls per day per user.

## Success Metrics
- Upload success rate >98% under normal network conditions.
- <1% analysis errors per day after retries.

## Open Questions
 - None.
