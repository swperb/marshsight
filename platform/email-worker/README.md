# MarshSight camera inbox (Cloudflare Email Worker)

Routes trail-camera email (`cam-<code>@marshsight.com`) to the user's map:
parse the photo → upload to the Supabase Storage bucket → POST `/v1/inbound/camera`.
Any other `@marshsight.com` mail is forwarded to `FORWARD_TO`.

## Deploy

```sh
cd platform/email-worker
npm install
npx wrangler login            # once, authorizes Cloudflare

# Secrets (not committed):
npx wrangler secret put SUPABASE_URL            # https://<project>.supabase.co
npx wrangler secret put SUPABASE_SERVICE_KEY    # Supabase service_role key
npx wrangler secret put FORWARD_TO              # your real inbox, e.g. you@gmail.com

npx wrangler deploy
```

## Wire it to email

In the Cloudflare dashboard for `marshsight.com`:

1. **Email → Email Routing → Enable** (adds the MX + TXT automatically).
2. **Destination addresses →** add and verify your real inbox (for forwarding).
3. **Routing rules → Catch-all address →** action **Send to a Worker →**
   pick `marshsight-camera-inbox`.

Now `cam-<code>@marshsight.com` photos flow to the app, and everything else
forwards to your inbox.
