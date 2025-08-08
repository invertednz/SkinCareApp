# Supabase Auth Settings (MVP)

This document lists the exact dashboard steps to configure authentication for the Skincare App MVP.

Status: Implements Auth Task 1.3

## Overview
- Provider: Email/Password ONLY (Google/Apple deferred for MVP)
- Email verification: OFF (auto-confirm new users)
- Password reset: Configure redirect URL(s)

## Steps (Supabase Dashboard)
1) Open your project → Authentication → Providers → Email
   - Enable Email provider: ON
   - Confirm email: OFF (auto-confirm new users)
   - Save

2) (Optional) SMTP Configuration (Authentication → Email Templates / SMTP)
   - If you plan to send password reset emails, configure SMTP. Otherwise, for local/staging, you can use the built-in Supabase email sandbox.
   - For production, set a real SMTP provider (e.g., Postmark, SendGrid) and verify domains.

3) URL Configuration (Project Settings → Authentication → URL Configuration)
   - Site URL: set to your app base URL
     - Dev (web): http://localhost:5173
     - Staging/Prod (web): https://app.example.com (placeholder)
   - Redirect URLs: add your allowed redirect targets, e.g.:
     - http://localhost:5173/reset
     - https://app.example.com/reset
   - Notes:
     - If using mobile deep links, add your app scheme deep link (e.g., skincareapp://reset). This is optional for MVP if reset is handled on web.

4) Auth Settings (Project Settings → Authentication → Settings)
   - Disable "Enable email confirmations": ON (i.e., confirmations are disabled)
   - "Allow new users" = ON
   - Token expiration: defaults OK for MVP
   - Save

## Security Notes
- Disabling email confirmations reduces friction but also reduces account verification assurance. For production, consider enabling confirmations and/or adding identity verification in a later milestone.
- Use distinct environments (dev/staging/prod) and do not reuse secrets across them.

## Staging vs Production
- Dev/Staging: may use sandbox email or test SMTP; localhost Site/Redirect URLs.
- Production: use your real domain for Site URL and Redirect URLs; configure SMTP and email sending domain.

## Related
- PRD: `tasks/prd-auth.md`
- Task: `tasks/tasks-prd-auth.md` (1.3)
