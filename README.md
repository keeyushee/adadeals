# AdaDeals

A mall deals feed for Kuching. Shoppers browse promotions running inside a mall, save the ones they want, and share them.

Live: https://adadeals.pages.dev

## What this is

A single-page static site — one `index.html` with the markup, styles and JS inline. No build step, no framework, no dependencies to install. Deals are read from Supabase at page load, with a bundled fallback set baked into the file.

## Running it locally

Serve the folder over HTTP (opening the file directly works, but a server matches production more closely):

```
python3 -m http.server 8000
```

Then open http://localhost:8000

## Configuration

There is none — the curator password lives only as a Supabase Edge Function secret (`CURATOR_PASSWORD`), never in a deployed file. See "Backend setup" below.

## Deploying

The site is hosted on Cloudflare Pages. Upload the folder contents — just `index.html`.

## Backend setup (Supabase)

The `deals` table's row-level security only allows public reads. All writes (add/edit/delete) go through the `manage-deal` Edge Function, which checks the curator password server-side and uses the service-role key. Visitor actions (save/share/claim) go through narrow, validated RPCs instead of direct table writes.

One-time setup in the Supabase Dashboard:
1. **SQL Editor** → paste and run `supabase/migrations/0001_lock_down_deals.sql`.
2. **Edge Functions** → create a function named `manage-deal` → paste in `supabase/functions/manage-deal/index.ts` → Deploy.
3. **Edge Functions → manage-deal → Secrets** → add `CURATOR_PASSWORD` set to the real curator password.

No CLI required — both steps are done entirely in the dashboard.

## Curator panel

Tap the logo five times to reveal the curator entry, then enter the password. From there you can add, edit and feature deals.

## Structure

```
index.html                          the entire site
supabase/migrations/                RLS lock-down + visitor RPCs
supabase/functions/manage-deal/     curator-only write path (server-side)
```
