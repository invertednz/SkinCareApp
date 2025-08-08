## Relevant Files

- `lib/features/insights/insights_screen.dart` - Insights UI and refresh.
- `lib/features/insights/data/insights_repository.dart` - Fetch/caching layer.
- `supabase/functions/insights-generate/index.ts` - Edge Function to fetch data, call Vertex AI, return JSON.
- `supabase/schema.sql` - `insights` cache table, minimal routine write integration.

### Notes

- Look-back window is 14 days; cooldown 1/hour; allow bypass on significant new data.

## Tasks

- [ ] 1.0 Implement Edge Function: data fetch + prompt + Vertex AI call + JSON schema
  - [ ] 1.1 Define output JSON schema for sections (summary, recommendations, action plan)
  - [ ] 1.2 Query last 14 days of logs/photos from Supabase with proper RLS
  - [ ] 1.3 Engineer prompt with guardrails and disclaimers; include user profile summary
  - [ ] 1.4 Call Vertex AI (model selection per PRD), handle timeouts/retries
  - [ ] 1.5 Map model response to JSON schema with validation and safe defaults
  - [ ] 1.6 Return structured response + debug trace flag in dev

- [ ] 2.0 Implement client UI to render sections and “Add to Routine”
  - [ ] 2.1 Render Summary, Continue/Start/Consider Stopping lists with rationales
  - [ ] 2.2 CTA to add items to Routine; navigate and pre-fill
  - [ ] 2.3 Loading, empty, and error states
  - [ ] 2.4 Pull-to-refresh and last generated timestamp

- [ ] 3.0 Implement trigger logic (post-log + on-demand) with cooldown handling
  - [ ] 3.1 Trigger insights generation after successful log creation
  - [ ] 3.2 Implement manual refresh with cooldown guard (1/hour)
  - [ ] 3.3 Allow bypass when significant new data is present
  - [ ] 3.4 Track `insights_generate_request/success/rate_limited`

- [ ] 4.0 Implement caching in Supabase and offline-friendly reload
  - [ ] 4.1 Create `insights` cache table with user_id, payload, generated_at
  - [ ] 4.2 Cache last response client-side for fast display
  - [ ] 4.3 Invalidate cache when new relevant data arrives

- [ ] 5.0 Add safety copy and analytics instrumentation
  - [ ] 5.1 Display medical disclaimer consistently
  - [ ] 5.2 Track `insights_view` and CTA clicks
