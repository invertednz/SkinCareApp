# AI Chat PRD

## Overview
Implement an AI assistant powered by Google (Vertex AI Gemini) with streaming responses, personalization based on user logs, support for photo attachments, and clear medical disclaimers. Architecture should allow swapping the model/provider later.

## Goals
- Helpful, context-aware chat with low latency and streaming.
- Safe responses with clear boundaries (not medical advice).

## User Stories
- As a user, I can ask questions and receive streaming replies.
- As a user, I can attach a photo and ask about it.
- As a user, I get answers that reference my recent logs where relevant.

## Functional Requirements
1. Chat UI: per mockup (inspired), supports text input, quick prompts, image attachments, and streaming display.
2. Personalization: when allowed by user settings, include recent logs (last 14–30 days) in context.
3. Disclaimers: persistent banner or first-message notice stating it is not medical advice; show link to safety info.
4. Moderation: apply layered safety checks and guardrails; block or reframe unsafe queries.
   - Provider safety filters (Google Safety) enabled.
   - Server-side heuristics and blocklists for: medical diagnosis/treatment requests, self-harm, violence, hate/harassment, adult/NSFW, illegal activities, dangerous advice.
   - If blocked, return a safe, empathetic message and offer general wellness guidance or suggest consulting a professional.
5. Rate limiting to prevent abuse (per-user quotas).
6. Conversation persistence in `chat_messages` table (role, content, attachments, created_at).
7. Retention: retain chat history for 90 days by default; older messages are soft-deleted (visibility off) and eligible for hard delete via retention job.

## Non-Goals
- Human handoff.

## Technical Considerations
- Edge Function proxy to Google Vertex AI (text + vision) for API key security.
- Use Google Embeddings by default for retrieval; store in `message_embeddings` table (optional in MVP; architecture must be provider-swappable).
- Model suggestions: `gemini-1.5-pro` (vision+text) for attachments; `gemini-1.5-flash` for faster text.
- Streaming via server-sent events or web sockets from Edge Function to client.
- Prompting: system prompt with safety rules; user profile summary; recent insights summary injected when small.

## Success Metrics
- Median time to first token < 1.5s (network dependent).
- User satisfaction thumbs-up rate on answers (>60%).

## Open Questions
- None.
