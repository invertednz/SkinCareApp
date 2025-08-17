## Relevant Files

- `app/lib/features/insights/insights_screen.dart` - Insights UI and refresh.
- `app/lib/features/insights/data/insights_repository.dart` - Fetch/caching layer.
- `supabase/functions/insights-generate/index.ts` - Edge Function for insights generation
- `supabase/schema.sql` - Database schema including insights cache table
- `app/lib/features/insights/data/insights_repository.dart` - Repository for insights data management
- `app/lib/features/insights/presentation/insights_widgets.dart` - UI widgets for insights display
- `app/lib/features/insights/insights_screen.dart` - Main insights screen with complete UI
- `app/lib/features/insights/services/insights_trigger_service.dart` - Trigger service with cooldown logic, minimal routine write integration.

### Notes

- Look-back window is 14 days; cooldown 1/hour; allow bypass on significant new data.
- Current codebase: no insights UI/repository or Edge Function implementation found yet; leaving tasks unchecked until implemented.

## Tasks

- [x] 1.0 Implement Edge Function: data fetch + prompt + Vertex AI call + JSON schema
  - [x] 1.1 Define output JSON schema for sections (summary, recommendations, action plan)
  - [x] 1.2 Query last 14 days of logs/photos from Supabase with proper RLS
  - [x] 1.3 Engineer prompt with guardrails and disclaimers; include user profile summary
  - [x] 1.4 Call Vertex AI (model selection per PRD), handle timeouts/retries
  - [x] 1.5 Map model response to JSON schema with validation and safe defaults
  - [x] 1.6 Return structured response + debug trace flag in dev

- [x] 2.0 Implement client UI to render sections and “Add to Routine”
  - [x] 2.1 Render Summary, Continue/Start/Consider Stopping lists with rationales
  - [x] 2.2 CTA to add items to Routine; navigate and pre-fill
  - [x] 2.3 Loading, empty, and error states
  - [x] 2.4 Pull-to-refresh and last generated timestamp

- [x] 3.0 Implement trigger logic (post-log + on-demand) with cooldown handling
  - [x] 3.1 Trigger insights generation after successful log creation
  - [x] 3.2 Implement manual refresh with cooldown guard (1/hour)
  - [x] 3.3 Allow bypass when significant new data is present
  - [x] 3.4 Track `insights_generate_request/success/rate_limited`

- [x] 4.0 Implement caching in Supabase and offline-friendly reload
  - [x] 4.1 Create `insights` cache table with user_id, payload, generated_at
  - [x] 4.2 Cache last response client-side for fast display
  - [x] 4.3 Invalidate cache when new relevant data arrives

- [x] 5.0 Add safety copy and analytics instrumentation
  - [x] 5.1 Display medical disclaimer consistently
  - [x] 5.2 Track `insights_view` and CTA clicks
