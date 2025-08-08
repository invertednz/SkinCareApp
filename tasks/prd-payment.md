# Payment & Paywall PRD

## Overview
Monetization via subscriptions: Monthly (with free trial) and Annual. Payments are native only: Apple App Store (iOS) and Google Play Billing (Android). On Web, show a mocked paywall (no purchase). Paywall is shown immediately after onboarding and before accessing the main app.

## Goals
- Offer Monthly (trial) and Annual subscriptions.
- Enforce access control so only active subscribers enter main app.
- Keep web build usable for testing with a non-functional paywall screen.

## User Stories
- As a user, I can choose Monthly or Annual subscription after onboarding.
- As a user, I can start a free trial on the Monthly plan.
- As a user on Web, I see pricing and am informed to purchase on mobile.
- As a subscriber, my access is reflected quickly in the app after purchase.

## Functional Requirements
1. Plans:
   - Monthly: $7/month with 7‑day free trial.
   - Annual: $47/year (no trial).
2. Platforms:
   - iOS: Apple In‑App Purchases (StoreKit); Monthly and Annual products.
   - Android: Google Play Billing; Monthly and Annual products.
   - Web: read-only paywall screen; purchase disabled.
3. Paywall placement: show immediately after onboarding completion; block main app until subscribed.
4. Entitlement:
   - On successful purchase, unlock access immediately.
   - Store entitlement in Supabase `subscriptions` table with fields: user_id, product_id, platform, status, trial_end, current_period_end, updated_at.
   - On app start, refresh entitlement from Supabase before gating.
5. Trials:
   - Trial applies to Monthly only; 7 days; show countdown and management info.
 6. Price Display:
   - Localized price strings (e.g., "$7.00/month", "$47.00/year").
   - Show per‑month equivalent for annual on paywall (e.g., “$3.92/mo billed annually”).
7. Restore purchases: supported on iOS and Android.
8. Cancellation and renewal handled by stores; reflect status on next entitlement refresh.
9. Analytics: view paywall, select plan, start trial, purchase success/failure.
10. Compliance: show Terms and Privacy, and link to subscription management help.

## Non-Goals
- Processing payments on Web in MVP.
- Cross‑platform subscription sharing beyond per‑store restore flows.

## Technical Considerations
- Do not embed store secrets in the app.
- Consider using a lightweight backend sync: Supabase Edge Function to receive client purchase tokens and write entitlements; server‑side validation can be deferred but planned.
- Product IDs configurable via remote config table `billing_products` to avoid redeploys.
- Timezone-aware expiry calculations.

## Success Metrics
- Paywall view → purchase conversion rate baseline captured.
- <2% failed entitlement sync after successful purchase.

## Open Questions
 - None.
