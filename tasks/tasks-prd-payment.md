## Relevant Files

- `lib/features/paywall/presentation/paywall_screen.dart` - Paywall UI with plans and trial details.
- `lib/features/paywall/data/iap_service.dart` - StoreKit/Play Billing integration.
- `lib/features/paywall/data/subscription_repository.dart` - Entitlement state and sync.
- `lib/router/app_router.dart` - Guard main app behind active subscription.
- `supabase/functions/entitlement-sync/index.ts` - Edge Function to process purchase tokens and write subscriptions.
- `supabase/schema.sql` - `subscriptions`, `billing_products` tables + RLS.

### Notes

- Web shows non-functional paywall (mock).

## Tasks

- [ ] 1.0 Configure store products (Monthly $7 with 7-day trial, Annual $47) and IDs
  - [ ] 1.1 Create products in App Store Connect and Google Play Console
  - [ ] 1.2 Record product IDs and pricing including trial for monthly
  - [ ] 1.3 Add config mapping in `iap_service.dart`
  - [ ] 1.4 Set up test users/sandbox

- [ ] 2.0 Implement paywall UI and price localization (incl. annual per‑month equivalent)
  - [ ] 2.1 Render plan cards and highlight recommended plan
  - [ ] 2.2 Fetch localized prices and trial info from stores
  - [ ] 2.3 Compute annual per‑month equivalent and display
  - [ ] 2.4 Show Terms/Privacy links and restore purchases button
  - [ ] 2.5 Snapshot tests of UI

- [ ] 3.0 Integrate IAP (iOS/Android) incl. restore purchases
  - [ ] 3.1 Initialize billing clients; handle connection lifecycle
  - [ ] 3.2 Start purchase flow and handle success/cancel/error
  - [ ] 3.3 Implement restore purchases
  - [ ] 3.4 Persist receipts/tokens for server validation

- [ ] 4.0 Implement entitlement sync to Supabase and route guards
  - [ ] 4.1 Edge Function validates receipts/tokens and writes to `subscriptions`
  - [ ] 4.2 `subscription_repository` polls/receives entitlement updates
  - [ ] 4.3 Router guards gate main app on active entitlement
  - [ ] 4.4 Background refresh on app start

- [ ] 5.0 Instrument analytics and handle errors; web mock behavior
  - [ ] 5.1 Track `paywall_view`, `paywall_select_plan`, `purchase_success`/`purchase_failure`
  - [ ] 5.2 Implement error toasts and retry guidance
  - [ ] 5.3 Web: show mock paywall and block purchase
