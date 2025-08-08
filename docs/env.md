# Environment Variables

This app uses environment variables for configuration. Copy `.env.example` to `.env` and adjust per environment (dev/staging/prod).

Required values (MVP):
- `TERMS_URL` – Link to Terms of Service page users see from Auth screen.
- `PRIVACY_URL` – Link to Privacy Policy page users see from Auth screen.

Recommended conventions:
- Keep `.env` out of version control. Commit `.env.example` only.
- Use different values per environment.

Example:
```
TERMS_URL=https://example.com/terms
PRIVACY_URL=https://example.com/privacy
```

Where used:
- Auth UI adds footer links to Terms and Privacy.
- Future screens may link to these as well.

Notes:
- Replace `example.com` with your real domain in staging/production.
