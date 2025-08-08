# Developer Seeding (Optional)

Use this only in local/dev environments. Do not use real credentials.

## Prerequisites
- Supabase project URL and Service Role Key (DEV/LOCAL ONLY)
- PowerShell (Windows) or a compatible shell

## Environment Variables
Set the following in your shell before running:

```
$env:SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="<service-role-key>"
$env:SEED_EMAIL="dev@example.com"
$env:SEED_PASSWORD="Password123!"
```

## Command
```
./scripts/seed-dev-user.ps1
```

The script creates a confirmed user via the Supabase Auth Admin API. On success, a corresponding `profiles` row is inserted by the signup trigger.

## Warnings
- Service Role key is highly privileged. Never commit or share it.
- Use distinct projects/keys for dev vs production.
- Rotate keys periodically.
