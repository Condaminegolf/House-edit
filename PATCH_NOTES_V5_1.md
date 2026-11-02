# The House Edit V5.1 — sign-in password-length fix

## What was wrong
V5 incorrectly placed `minlength="8"` on the **Sign in** password field. This caused the browser to block submission of six-character passwords that an administrator had legitimately set in Supabase.

## Fix
Removed the `minlength="8"` constraint from the **Sign in** password input only. Supabase still checks the credentials with `auth.signInWithPassword` and controls account authentication. The app retains the 8-character minimum for **Create account**, **Set / change password**, and **Reset password** forms.

## Install
Replace **app.js** in your existing GitHub Pages site and hard-refresh. No changes to `schema.sql`, existing users, passwords, Supabase policies, the publishable API key or house data are required.

## Check
1. Open the site in a fresh/private window.
2. Enter the email and six-character password of the existing account.
3. The app should submit to Supabase rather than displaying an 8-character browser validation error.
4. If Supabase returns an authentication or weak-password error, follow the provider's message or set a longer password in your Supabase account administration.
5. Recommend changing the account password to 12+ unique characters when convenient.

For already-confirmed accounts, an ordinary successful password sign-in doesn't send an email.
