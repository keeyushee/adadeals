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

Before running or deploying, create your local config:

```
cp config.example.js config.js
```

Then edit `config.js` and set `curatorPw` to the real curator password.

`config.js` is gitignored so the password stays out of this repository. Note that it is still readable by anyone who views the source of the deployed site — this gate keeps casual visitors out of the curator panel, it is not real access control. Anything that must actually be protected belongs behind Supabase row-level security.

## Deploying

The site is hosted on Cloudflare Pages. Upload the folder contents — `index.html` plus your filled-in `config.js`. If `config.js` is missing the site still loads fine; only the curator panel stops unlocking.

## Curator panel

Tap the logo five times to reveal the curator entry, then enter the password. From there you can add, edit and feature deals.

## Structure

```
index.html          the entire site
config.js           local secrets, gitignored
config.example.js   template for the above
```
