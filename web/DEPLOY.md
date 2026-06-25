# Deploying the landing page and wiring marshsight.com

The site is a standard Next.js app. The fastest path is Vercel, which also makes
the custom domain a few clicks.

## 1. Deploy to Vercel

```sh
cd web
npx vercel            # first run: log in and link the project
npx vercel --prod     # production deploy, gives a *.vercel.app URL
```

Set the API URL so the waitlist form posts to the real backend:

- In the Vercel project: Settings -> Environment Variables
- Add `NEXT_PUBLIC_API_URL` = the deployed platform API URL (e.g. `https://api.marshsight.com`)
- Redeploy so the value is baked into the static build.

Until the API is deployed, the form falls back to `http://localhost:8088` and
will only work locally.

## 2. Register and connect marshsight.com

1. Register `marshsight.com` at any registrar (about 12 USD/year).
2. In the Vercel project: Settings -> Domains -> add `marshsight.com` and
   `www.marshsight.com`.
3. Vercel shows the DNS records to set. Either:
   - Point the registrar's nameservers at Vercel, or
   - Add the A / CNAME records Vercel lists at your registrar.
4. HTTPS is issued automatically once DNS resolves.

## 3. Backend (so the waitlist actually stores emails)

The platform API in `../platform/api` writes the waitlist and contributions to
Supabase when `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` are set (see
`../platform/supabase/schema.sql` and `../platform/api/.env.example`). Deploy
that API to any Node host (Railway, Render, Fly, a small VM), set those env
vars, and point `NEXT_PUBLIC_API_URL` at it. A subdomain like
`api.marshsight.com` is a clean choice.
