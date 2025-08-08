## Relevant Files

- `lib/features/chat/chat_screen.dart` - Chat UI with streaming and attachments.
- `lib/features/chat/data/chat_repository.dart` - Chat persistence and API calls.
- `supabase/functions/chat-proxy/index.ts` - Edge Function proxy to Vertex AI with streaming.
- `supabase/schema.sql` - `chat_messages` and optional `message_embeddings` tables.

### Notes

- Moderation: layered guardrails with Google Safety + server heuristics and blocklists.

## Tasks

- [ ] 1.0 Implement Edge Function proxy to Vertex AI with SSE/WebSocket streaming
  - [ ] 1.1 Define API contract (request includes messages, attachments, settings; response streams chunks)
  - [ ] 1.2 Add pre-moderation check and safe response path
  - [ ] 1.3 Implement SSE/WebSocket streaming with heartbeats and cancellation
  - [ ] 1.4 Handle errors/timeouts with retries and backoff
  - [ ] 1.5 Secure environment variables; auth check; CORS

- [ ] 2.0 Build chat UI with streaming, quick prompts, and image attachments
  - [ ] 2.1 Text input with send; disable during streaming
  - [ ] 2.2 Virtualized message list with role styling
  - [ ] 2.3 Attachment picker (photos) with preview and size checks
  - [ ] 2.4 Streaming cursor/typing indicator and auto-scroll
  - [ ] 2.5 Restore last conversation on open

- [ ] 3.0 Implement moderation guardrails and user-facing safe responses
  - [ ] 3.1 Central moderation utility with categories per PRD
  - [ ] 3.2 UX for blocked messages with supportive copy and resources link
  - [ ] 3.3 Track `chat_blocked_moderation` with category

- [ ] 4.0 Add personalization context (recent logs/insights) per settings
  - [ ] 4.1 Fetch recent logs (14–30 days) and latest insights summary
  - [ ] 4.2 Summarize profile to brief context; trim to token budget
  - [ ] 4.3 Respect settings toggle; exclude sensitive/PII

- [ ] 5.0 Persist conversation (90‑day retention) and instrument analytics/rate limits
  - [ ] 5.1 Define `chat_messages` schema; insert user and assistant segments
  - [ ] 5.2 Finalize assistant message on stream end; handle abort
  - [ ] 5.3 Retention job to soft-delete >90 days; hard delete via cleanup
  - [ ] 5.4 Per-user rate limit (e.g., X/min) and backoff UX
  - [ ] 5.5 Track `chat_open`, `chat_send`, `chat_stream_start/end`, `chat_thumbsup/thumbsdown`
