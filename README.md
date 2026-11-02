# The House Edit — V3 (product link import reliability)

A mobile-friendly renovation selection app for two homeowners and a designer friend. This release improves product-link importing; all other features from V2 remain in place.

## Update an existing V2 installation

Replace **`app.js`** and **`styles.css`** with the files in `the-house-edit-v3-changed-files.zip`. No database migration or changes to your `config.js` are needed. Keep `schema.sql`, `config.js`, images, and other existing files.

For a new install use `the-house-edit-v3.zip`, which contains all project files. To enable real multi-person collaboration, complete the Supabase setup below; without configuration the app stays in browser-only demo mode.

After deploying, perform a hard refresh (Windows: Ctrl + Shift + R; iPhone Safari: refresh the page; if necessary close and reopen the page).

## How link importing works

1. Open a decision and choose **Add an option**.
2. Paste a retailer product URL into **Product / supplier link**. `www.` links are accepted; `https://` is added when required.
3. Wait for the product name and photo preview. It automatically extracts a title and photo *when the public metadata service makes them available*.
4. Add a price or notes if desired, then select **Add to comparison**.
5. Even if you save immediately after pasting, the app waits for a metadata lookup before saving the item. If lookup fails, it can create the item from the product link and a readable title based on the URL; add the photo manually later.

Images sourced from a product page are now displayed using an image relay (`wsrv.nl`) to reduce problems with retailer hotlink restrictions, falling back to the original image and Microlink's image delivery endpoint. This also benefits previously imported items. User-uploaded private Supabase images are **never passed to these public image services**.

The preview now reports whether a photo actually loads. If every candidate is blocked, it shows a clear warning rather than silently displaying a broken image. You can select **Try again** after a failed lookup. A direct image URL or uploaded image still takes precedence.

### Limitations

- Automated preview uses Microlink's free metadata endpoint: https://microlink.io/api. It currently offers 25 uncached requests/day; this is shared across requests using its public service. You don't need an API key for that free endpoint.
- Some retailer sites restrict scraping, omit a product image, or present anti-bot checks. Neither a static GitHub Pages app nor free relays can guarantee extraction from every shop.
- Image relay `wsrv.nl` receives publicly available retailer photo URLs; Microlink receives the provided retailer product page URL. Do not paste confidential or private links.
- Prices are still manually entered and are not checked against live retailer pricing.
- Internet access is required for product previews. Browsers may temporarily cache old versions of the app.
- Real-time cross-device sharing requires Supabase; demo mode only saves in the current browser.

## Cloud setup (new installations)

1. Create a separate Supabase project at https://supabase.com/dashboard.
2. Run `schema.sql` in Supabase's SQL Editor (review the SQL first). It creates private `house_*` tables, access policies and an image bucket.
3. Enable Email authentication and configure your published URL in Auth URL Configuration.
4. Edit `config.js` with the project's URL and **publishable** (or legacy `anon`) key. Never put a service role, secret key or DB password in a public site.
5. Host the files on GitHub Pages or another HTTPS static host. Sign in, create a home project, and use the invitation codes to invite the second homeowner and designer.
6. Test permissions and photo uploads with the three real accounts before using the project for sensitive content.

## What was tested

- Browser UI tested with **mocked metadata API responses**: title and image present, metadata with no image, and an HTTP 429 rate-limit response.
- URL normalisation (`www.` links), form submission, local demo saves, and fallback name generation were checked; no application JavaScript errors surfaced in those tests.
- `node --check` passed on the updated script.
- Real retailer websites and their image-relay behaviour could not be live-tested in this execution environment. If a particular retailer still fails, provide one public product link to reproduce that case.
