# Finova Landing Page

Production landing page for `https://finova.ailooma.biz.id`, built with Next.js and prepared for Vercel.

## Local development

```sh
npm install
npm run dev
```

## Production validation

```sh
npm run build
```

## Deploy to Vercel

1. Push the repository to GitHub/GitLab/Bitbucket, or use the Vercel CLI.
2. In Vercel, import the repository and set **Root Directory** to `landing-page`.
3. Vercel detects Next.js automatically. Keep the default build command `npm run build`.
4. Deploy, then add `finova.ailooma.biz.id` under **Project → Settings → Domains**.
5. Apply the DNS record shown by Vercel at the DNS provider for `ailooma.biz.id`.

## Required public endpoints

- `/downloads/finova-android-v2.3.0.apk` — signed Android release APK
- `/api/webhook` — signed Lemon Squeezy `order_created` webhook
- `/privacy` — Privacy Policy
- `/terms` — Terms of Use
- `/app-ads.txt` — AdMob authorized seller declaration
- `/robots.txt` and `/sitemap.xml` — crawler metadata

## Release file

- Version: `2.3.0`
- SHA-256: `39B60FCA3A6C89AA2BCBECCF45E5F2BEA8DC96801F9CB3D8259DCBD061D74633`

When the APK changes, replace the file in `public/downloads`, update the version and checksum on the homepage, then run `npm run build` again.

The support email currently shown is `support@finova.ailooma.biz.id`; configure that mailbox or replace it before public launch.

## Premium webhook environment

Copy `.env.example` values into Vercel Environment Variables. Keep
`LEMON_SQUEEZY_WEBHOOK_SECRET` and `SUPABASE_SERVICE_ROLE_KEY` secret. Configure
the Lemon Squeezy webhook URL as `https://finova.ailooma.biz.id/api/webhook` and
subscribe to `order_created`.

