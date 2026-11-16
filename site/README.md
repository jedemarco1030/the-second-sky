# The Second Sky — website

The public marketing and playtest site for The Second Sky. It is a
self-contained Next.js (App Router, TypeScript, Tailwind CSS) app that lives
in `site/`. The Godot game stays at the repository root and is not part of
this build.

The site needs no environment variables.

## Local preview

Requires Node.js 20.9 or newer.

```bash
cd site
npm ci
npm run dev     # http://localhost:3000
npm run build   # production build check
```

## Editing links and downloads

Every outbound link is in `site.config.ts`:

- `sourceZipUrl`: the "Download Godot project" button (the `main` branch ZIP).
- `desktopDownloads`: empty for now, so the page says "Desktop build — planned".
  Add an entry per platform only after its GitHub Release asset exists, using
  the asset URL `https://github.com/jedemarco1030/the-second-sky/releases/download/<tag>/<file>`.
- `browserDemoUrl`: unset for now, so the page says "Browser demo — planned".
  Set it to show a "Play the browser demo" link.
- `gameplayScreenshots`: empty for now, so the screenshots slot is hidden.
  Put real captures in `public/images/screenshots/` and list them here.

Concept art is in `public/images/` and is labeled on the page as
"Concept art" or "Concept mockup".

## Deploying the existing Vercel project

The project at https://the-second-sky.vercel.app should build from `site/`.

1. In the Vercel dashboard, open the **the-second-sky** project, then
   **Settings → Build and Deployment**.
2. Set **Framework Preset** to **Next.js**.
3. Set **Root Directory** to `site` and save. Leave the build, output, and
   install commands at their defaults (Vercel detects `package-lock.json` and
   runs `npm install` and `next build`).
4. Confirm **Node.js Version** is 20.x or newer.
5. Redeploy: on **Deployments**, open the latest production deployment, choose
   **Redeploy**, and leave "Use existing Build Cache" unchecked. Merging this
   branch into `main` also triggers a production deployment once the root
   directory is set.

Optional: under **Settings → Build and Deployment → Ignored Build Step**, you
can skip builds that do not touch the site with
`git diff --quiet HEAD^ HEAD -- .` (run from the root directory, `site/`).
