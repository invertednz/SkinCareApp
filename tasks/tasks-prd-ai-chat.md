## Relevant Files

- `app/lib/features/chat/chat_screen.dart` - Chat UI with streaming and attachments.
- `app/lib/features/chat/data/chat_repository.dart` - Chat persistence and API calls.
- `supabase/functions/chat-proxy/index.ts` - Edge Function proxy to Vertex AI with streaming.
- `supabase/schema.sql` - `chat_messages` and optional `message_embeddings` tables.

### Notes

- Moderation: layered guardrails with Google Safety + server heuristics and blocklists.
- Current codebase: no chat UI/repository or Edge Function implementation found yet; leaving tasks unchecked until implemented.

## Tasks

- [x] 1.0 Implement Edge Function proxy to Vertex AI with SSE/WebSocket streaming
  - [x] 1.1 Define API contract (request includes messages, attachments, settings; response streams chunks)
  - [x] 1.2 Add pre-moderation check and safe response path
  - [x] 1.3 Implement SSE/WebSocket streaming with heartbeats and cancellation
  - [x] 1.4 Handle errors/timeouts with retries and backoff
  - [x] 1.5 Secure environment variables; auth check; CORS

- [x] 2.0 Build chat UI with streaming, quick prompts, and image attachments
  - [x] 2.1 Text input with send; disable during streaming
  - [x] 2.2 Virtualized message list with role styling
  - [x] 2.3 Attachment picker (photos) with preview and size checks
  - [x] 2.4 Streaming cursor/typing indicator and auto-scroll
  - [x] 2.5 Restore last conversation on open

- [x] 3.0 Implement moderation guardrails and user-facing safe responses
  - [x] 3.1 Central moderation utility with categories per PRD
  - [x] 3.2 UX for blocked messages with supportive copy and resources link
  - [x] 3.3 Track `chat_blocked_moderation` with category

- [x] 4.0 Add personalization context (recent logs/insights) per settings
  - [x] 4.1 Fetch recent logs (14–30 days) and latest insights summary
  - [x] 4.2 Summarize profile to brief context; trim to token budget
  - [x] 4.3 Respect settings toggle; exclude sensitive/PII

- [x] 5.0 Persist conversation (90‑day retention) and instrument analytics/rate limits
  - [x] 5.1 Define `chat_messages` schema; insert user and assistant segments
  - [x] 5.2 Save messages after streaming completes; restore on app open
  - [x] 5.3 Auto-cleanup expired messages (90‑day retention)
  - [x] 5.4 Per-user rate limit with backoff UX
  - [x] 5.5 Track `chat_message_sent`, `chat_response_completed`, `chat_error`, `chat_stream_start/end`, `chat_thumbsup/thumbsdown`
