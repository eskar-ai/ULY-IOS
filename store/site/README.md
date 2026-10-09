# GitHub Pages (optional)

Host these files as your **Marketing**, **Support**, and **Privacy Policy** URLs.

## Steps

1. Create a GitHub repo (or use this repo).
2. **Settings → Pages → Source:** deploy from branch, folder `/store/site` (or copy files to `docs/`).
3. Replace `CONTACT_EMAIL` in `privacy.html` and `support.html` with your email.
4. In App Store Connect:
   - **Privacy Policy URL** → `https://<user>.github.io/<repo>/privacy.html`
   - **Support URL** → `https://<user>.github.io/<repo>/support.html`
   - **Marketing URL** (optional) → `https://<user>.github.io/<repo>/`

Or use any static host (Cloudflare Pages, Netlify, etc.).
