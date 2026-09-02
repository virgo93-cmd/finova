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

- `/downloads/finova-android-v1.0.0.apk` — signed Android release APK
- `/privacy` — Privacy Policy
- `/terms` — Terms of Use
- `/app-ads.txt` — AdMob authorized seller declaration
- `/robots.txt` and `/sitemap.xml` — crawler metadata

## Release file

- Version: `1.0.0`
- SHA-256: `2826507E293FCE254640EB0DD02B501278523CB9C9CE49CDF0725390C9179E1F`

When the APK changes, replace the file in `public/downloads`, update the version and checksum on the homepage, then run `npm run build` again.

The support email currently shown is `support@finova.ailooma.biz.id`; configure that mailbox or replace it before public launch.
