# The House Edit

A small, mobile-friendly shared renovation decision app for **two homeowners and one designer friend**.

## Try it now

Open `index.html` in a modern browser. The app starts in **Demo mode**, with example room and material selections. Demo changes are saved **only in that browser**; use the persona switcher on desktop (or the People page on mobile) to preview each person's votes. Demo data is not uploaded or shared with your household.

### What works in the demo

- Room-by-room design decisions, from tiles to furniture
- Add choices with photo upload or image URL, product website, price and notes
- Independently vote **Love**, **Maybe**, **Pass** on every option
- Comment on options; view all three opinions and disagreement flags
- Homeowner-only final approval, only after **both homeowners** vote Love/Maybe
- Track approved → ordered → installed; reopen a decision
- Final selections schedule with CSV export (Australian dollars)
- Responsive desktop/mobile layout with a home-screen web app manifest

Seeded choices (e.g. splashback patterns, cabinetry, tapware) are **illustrative only**. Pattern illustrations are not real supplier product images. Cloud mode starts with blank decisions.

## Enable actual three-person collaboration

The static web app needs a backend to sync three phones or computers. This version supports **Supabase** with email sign-in, private invitations, row-level security and private image storage.

1. Create a **new** project at https://supabase.com/dashboard . Do not reuse or overwrite an unrelated app's database.
2. In **SQL Editor**, paste and run the entire `schema.sql`. It creates isolated `house_*` tables, SQL functions, RLS policies and a private photo bucket. Only use this on a project you control and have reviewed.
3. Under **Authentication → Providers**, enable **Email** sign-in. Ensure the email OTP / magic-link flow is enabled and that Supabase has sufficient mail sending capacity for your test users.
4. Under **Authentication → URL Configuration**, set your production **Site URL** and add the exact app URL (including path) to **Redirect URLs**. Example for GitHub Pages: `https://YOURNAME.github.io/the-house-edit/` . For local testing, add your local HTTP address such as `http://localhost:8765/`.
5. Open **Project Settings → API Keys**. Copy your **Project URL** and **publishable key** (or legacy `anon` key).
6. Edit `config.js` to enter only these two values, keeping the quotes. **Never** put a secret key, database password, or service_role key in any website file.
7. Upload `index.html`, `app.js`, `styles.css`, `config.js`, `manifest.webmanifest` and `favicon.svg` to a static host (GitHub Pages is suitable), or run `python -m http.server 8765` inside this folder to test locally.
8. Sign in by email, create your home, then open **Your people** and copy the two **one-time codes** for your other homeowner and your designer friend. Each signs in independently using their own email, then joins with the appropriate code. Their access level is determined by the code, not by what they type.

### Shared mode permissions

| Action | Homeowner A | Homeowner B | Designer |
| --- | --- | --- | --- |
| Add rooms, decisions and options | Yes | Yes | Yes |
| Upload photos, vote and comment | Yes | Yes | Yes |
| Approve final selection | Yes, after both approve via votes | Yes, after both approve via votes | No |
| Mark ordered / installed or reopen | Yes | Yes | No |
| See private invite codes | Owner only | No | No |

The shared project contains **at most three members** by design. Each user may join one project in this first version.

## Important limitations / next enhancements

- This version does **not** automatically pull a product photo or price from a general retailer URL; paste the direct product image URL or upload a screenshot instead. Product-site restrictions and copyright vary.
- Private cloud uploads are supported up to **6 MB** for JPEG, PNG and WebP; browser-only demo photos must be **under 700 KB** because localStorage is limited.
- Uploaded photos in private Supabase Storage are displayed using short-lived signed URLs. Refresh the app if an older image URL expires.
- Supplier prices and quantities are manually entered; selection totals are not full project budgets, installed costs or quotes.
- The shared-mode SQL and UI have not been exercised against your own Supabase project, because its URL, credentials, and live users have not been supplied. The demo workflow was browser-tested. Review permissions before using sensitive house plans or financial details.
- One project per person, one preassigned designer, and no guest read-only links in this MVP.
- Potential next steps: photo-first swipe review, full drag-and-drop moodboards, image comparison slider, sample sign-off, purchasing list with quantities/units (tiles by m²), cost forecasts, PDFs and notifications.

## Technical implementation

- Front end: plain HTML/CSS/JavaScript, no build step or package manager.
- Sync: Supabase Auth, Postgres + RLS, Realtime and private Supabase Storage.
- Deployment: any HTTPS static website (GitHub Pages, Cloudflare Pages, Netlify).
- Data model: projects → rooms → decisions → options → votes/comments. Households are restricted by membership checks. Sensitive approval and status transitions are validated server-side by restricted SQL RPCs, not only JavaScript.

For security, verify Supabase configuration, RLS rules and your deployed URL before using with real household data.
