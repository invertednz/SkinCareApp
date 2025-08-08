# Usage:
#   $env:SUPABASE_URL="https://YOUR-PROJECT.supabase.co"
#   $env:SUPABASE_SERVICE_ROLE_KEY="<service-role-key>"
#   $env:SEED_EMAIL="dev@example.com"
#   $env:SEED_PASSWORD="Password123!"
#   ./scripts/seed-dev-user.ps1
#
# Notes:
# - Requires Service Role key; DO NOT commit real keys.
# - Creates a confirmed user via Supabase Auth Admin API.

param()

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY -or -not $env:SEED_EMAIL -or -not $env:SEED_PASSWORD) {
  Write-Error "Missing required env vars: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SEED_EMAIL, SEED_PASSWORD"; exit 1
}

$headers = @{
  "apikey" = $env:SUPABASE_SERVICE_ROLE_KEY
  "Authorization" = "Bearer $($env:SUPABASE_SERVICE_ROLE_KEY)"
  "Content-Type" = "application/json"
}

$body = @{
  email = $env:SEED_EMAIL
  password = $env:SEED_PASSWORD
  email_confirm = $true
} | ConvertTo-Json

$endpoint = "$($env:SUPABASE_URL.TrimEnd('/'))/auth/v1/admin/users"

try {
  $res = Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $body
  Write-Output "Seed user created: $($res.id) email=$($res.email)"
} catch {
  Write-Error "Failed to create seed user: $($_.Exception.Message)"
  if ($_.Exception.Response -ne $null) {
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $respBody = $reader.ReadToEnd()
    Write-Error "Response: $respBody"
  }
  exit 1
}
