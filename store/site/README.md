# Marketing site → GitHub Pages (one-click)

Static pages for **Marketing**, **Support**, and **Privacy Policy** URLs (App Store Connect).

UI languages: **English · 简体中文 · ئۇيغۇرچە · Uyghurche (ULY)**. This is the site chrome language only — not keyboard input.

## One-click on this repository

1. Push `main` (workflow: [`.github/workflows/pages.yml`](../../.github/workflows/pages.yml)).
2. GitHub → **Settings → Pages → Build and deployment → Source:** **GitHub Actions**.
3. Open **Actions → Deploy GitHub Pages** and confirm the run succeeded (or use **Run workflow**).
4. Site URL:
   - Project site: `https://<user-or-org>.github.io/<repo>/`
   - Privacy: `…/privacy.html`
   - Support: `…/support.html`
5. Replace every `CONTACT_EMAIL` in `privacy.html` / `support.html` / `i18n.js` before submit.
6. Paste those HTTPS URLs into App Store Connect.

Language switch: `?lang=en|zh|ug|uly` (remembered in `localStorage`).

## Attach `store/site` to a **different** repo name

If the marketing site should live under another GitHub repo (for example `uly-kunupka-site`):

```bash
# From this project root
git clone --depth 1 https://github.com/<you>/<this-repo>.git uly-src
mkdir uly-site && cp -a uly-src/store/site/. uly-site/
cd uly-site
git init
git add .
git commit -m "ULY Künupka marketing site"
gh repo create <you>/uly-kunupka-site --public --source=. --remote=origin --push
```

Then in **`uly-kunupka-site`**:

1. Add the same workflow (copy `.github/workflows/pages.yml` and change the copy step to `cp -a . _site/` if the site is at the repo root).
2. **Settings → Pages → Source: GitHub Actions**.
3. URL becomes `https://<you>.github.io/uly-kunupka-site/`.

Minimal root-site workflow:

```yaml
name: Deploy GitHub Pages
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: mkdir -p _site && cp -a . _site/ && rm -rf _site/.git _site/.github
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v3
        with:
          path: _site
      - id: deployment
        uses: actions/deploy-pages@v4
```

## Local preview

```bash
cd store/site
python3 -m http.server 3848
```

Open http://localhost:3848/?lang=ug

## Other hosts

Any static host works (Cloudflare Pages, Netlify): publish the `store/site` folder as the web root.
