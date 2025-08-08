# Insights PRD

## Overview
Provide LLM-assisted insights summarizing recent logs, with actionable recommendations grouped into Continue, Start, and Consider Stopping, plus an optional 2-week action plan. Generate insights after diary entries and on-demand.

## Goals
- Deliver personalized, safe, and comprehensible guidance.
- Enable users to add recommended steps to their routine easily.

## User Stories
- As a user, I see a concise summary of my recent trends after I log entries.
- As a user, I receive categorized recommendations with rationale.
- As a user, I can add recommended steps to my AM/PM routine.

## Functional Requirements
1. Triggers: generate after a new Skin Health or Symptoms entry and on-demand refresh.
2. Inputs considered: sleep, water, diet flags (dairy/spicy/etc.), stress, routine adherence, supplements, recent photos (optional).
3. Output sections:
   - Summary of last N days (N=14).
   - Recommendations: Continue, Start, Consider Stopping (each item includes rationale and expected time-to-effect).
   - Optional: 2-week action plan (checklist items with schedule) with CTA “Add to Routine”.
4. Safety: include medical disclaimer; avoid diagnosing; suggest consulting a professional for severe/persistent issues.
5. Logging: store last generated insights with timestamp for quick reload.
 6. Rate Limiting: cooldown of 1 generation per hour per user; on-demand requests respect cooldown; system may bypass cooldown after significant new data (e.g., multiple new logs in 1 hour).

## Non-Goals
- Clinical diagnosis; advanced statistical causality.

## Technical Considerations
- Run an Edge Function to fetch user data (RLS via service role) and call Google Vertex AI (Gemini) for summarization.
- Prompting: structured system prompt with JSON schema output for sections.
- Caching: store generated JSON in `insights` table keyed by user_id and window start.
- “Add to Routine” writes to `routines` with minimal fields; user can edit later.

## Success Metrics
- % of users who open insights after logging.
- CTR on “Add to Routine”.
- Qualitative feedback rating >4/5.

## Open Questions
- None.
