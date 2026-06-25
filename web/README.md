# MarshSight — web

Marketing landing page and waitlist for **MarshSight**, a free, open-source AR
navigation app for hunters and anglers.

Built with Next.js (App Router) + TypeScript + Tailwind CSS v4.

## Getting started

Install dependencies and run the dev server:

```bash
npm install
npm run dev
```

Open http://localhost:3000 to view the page.

## Production build

```bash
npm run build
npm run start
```

## Environment variables

The waitlist form POSTs `{ "email": "..." }` to `${NEXT_PUBLIC_API_URL}/v1/waitlist`.

| Variable             | Default                 | Description                                  |
| -------------------- | ----------------------- | -------------------------------------------- |
| `NEXT_PUBLIC_API_URL`| `http://localhost:8088` | Base URL of the waitlist backend API.        |

Because it is prefixed with `NEXT_PUBLIC_`, this value is inlined into the client
bundle at build time. Set it before building for production, for example:

```bash
NEXT_PUBLIC_API_URL=https://api.marshsight.app npm run build
```

Or create a `.env.local` file:

```
NEXT_PUBLIC_API_URL=https://api.marshsight.app
```

The form handles both outcomes gracefully: a `200` response shows a success
state, and any non-OK response or network failure shows a friendly error. The
backend endpoint is expected to exist separately; this app only makes the client
call.

## Project structure

```
src/app/
  layout.tsx        Root layout and metadata
  page.tsx          Landing page (server component)
  WaitlistForm.tsx  Waitlist signup form (client component)
  globals.css       Tailwind import + theme tokens
```

## Placeholders to fill in before launch

- TestFlight button (`Join the beta` section in `page.tsx`) — replace `href="#"`
  with the public TestFlight invite link.
- Footer GitHub links — point at the real GitHub org/repo once published.
