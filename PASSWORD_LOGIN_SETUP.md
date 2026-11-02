# The House Edit V5 — email and password sign-in

## What changed

V5 replaces magic-link **login** with email and password. It adds separate **Sign in** and **Create account** screens, **Forgot password**, **Choose a new password** on return from a Supabase reset email, and **Set / change password** in **Your people** for any logged-in household member. The household's Supabase user ID and membership are unchanged by adding a password. Existing decisions, votes, images, invitations and the V4 deletion features are unchanged.

## Upgrade an existing deployed V4 site

1. Keep your existing Supabase project and its `house_*` tables. **Do not rerun `schema.sql` or the deletion migration**; there are no database changes for V5.
2. Upload the two updated files **`app.js` and `styles.css`**, replacing their existing versions at the published GitHub Pages path. Your existing `index.html`, `config.js`, `favicon.svg` and other files can stay unchanged. The full ZIP also has the correctly configured project URL and publishable key if you need a complete reupload.
3. Hard-refresh the site (`Ctrl + Shift + R` on Windows). Ensure the screen says **Sign in** with an **email** and **password** field, plus a **Create account** tab. If the old screen remains, check your GitHub Pages deployment and browser cache.
4. Supabase Dashboard → Authentication → Providers → Email: leave email/password sign-in enabled and **Confirm email on**. Ensure Authentication → URL Configuration has your real published HTTPS app address in Site URL and Redirect URLs; account-verification and password-reset links return there.
5. Because Supabase's built-in email sender is restricted, configure **Authentication → SMTP Settings** with a verified sender for first-time registration confirmations and forgotten-password resets. **Ordinary password sign-ins do not send an email and are not affected by the Auth email-sending quota.**

## Existing user: avoid duplicate accounts and duplicate houses

- **Still signed into The House Edit in any browser?** Open **Your people → Your account → Set / change password**, then use that same email address and password when signing in on any other browser or phone. This uses `supabase.auth.updateUser` on the current account; no email is normally sent and the existing membership is retained.
- **Already signed up with email links, but now signed out?** Use **Sign in → Forgot password** with that same email address to set a password on the existing Supabase account. This **does send one reset email** and may encounter the current email limit until SMTP is configured. **Do not use Create account with the same email** in an attempt to repair the existing account.
- **Brand-new person?** Use **Create account**, confirm their email once, then sign in using the password. They will join the existing house using their **own invitation code**; they should **not create a separate house**.
- Passwords require at least 8 characters (Supabase may enforce additional requirements depending on project policy). Credentials are submitted directly to Supabase Auth and are never saved by The House Edit or shared between participants.

## Test checklist

- Log in as an existing homeowner on another browser using the same email; the previously created house and votes should appear.
- Register a **new** invited participant and verify the signup confirmation link arrives. Have them **join** the existing house by invitation code, not create a house.
- In **Your people**, change the password and then sign out and sign in with the new one.
- Use **Forgot password** in a separate browser. Click the email recovery link and enter a replacement password.
- Open the project on two devices and verify new options, votes and deletions appear on both after refresh.

## Current limitations

- Supabase email confirmation on new accounts and password reset emails **still use email**. Without custom SMTP the built-in email sender has very low limits and only allows delivery to authorized organisation email addresses.
- Live authentication was **not tested against your private Supabase project**, because this environment cannot access its management API. Local browser simulation tests cover the sign-in UI and auth-method calls, but you must complete the on-device checks above before relying on it for the household.
- The email/password migration does not automatically export local Demo data to the cloud.

### Docs
- https://supabase.com/docs/guides/auth/passwords
- https://supabase.com/docs/reference/javascript/auth-updateuser
- https://supabase.com/docs/reference/javascript/auth-onauthstatechange
- https://supabase.com/docs/guides/auth/auth-smtp
