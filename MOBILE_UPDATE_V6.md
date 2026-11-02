# The House Edit V6 — iPhone layout update

This release retains the V5.1 login, Supabase project connection, database schema, shared house records, invitations, product import, voting and deletion behaviour.

## What's improved

- A compact branded iPhone header with a properly sized refresh control.
- A four-tab bottom navigation that respects the iPhone Home indicator and side safe areas.
- The **Decide** tab remains highlighted when viewing a product comparison.
- Responsive home, room, comparison, selection and people screens.
- Larger touch targets for votes, filters, navigation, edit and deletion actions.
- Scrollable filter chips rather than squeezed labels on narrow phones.
- Better presentation of approved selections, product links and long notes.
- Add-product and edit dialogs appear as mobile bottom sheets, staying within the visual viewport when the software keyboard opens.
- The navigation bar is hidden during text input and modal editing so it doesn't obstruct the keyboard.
- 16px form controls to prevent automatic Safari focus zoom.
- Cache-busting version numbers in `index.html` so iPhone Safari fetches updated CSS/JavaScript.

## GitHub Pages deployment

### Existing installation
Upload **index.html**, **styles.css** and **app.js** to the same location as your existing website files. Keep your current `config.js` unchanged. Do not rerun the Supabase schema; V6 contains no database changes.

### Complete installation
The full ZIP contains all website and Supabase setup files, including the configured publishable key. Upload the website files to your existing GitHub Pages repository.

Check the site on iPhone Safari after GitHub Pages finishes publishing. If it still looks old, close the Safari tab and reopen the site, or remove the previous Home Screen shortcut and add it again.

## QA

Checked by Chromium browser emulation at 320x568, 375x667, 390x844, 430x932, 667x375 (landscape) and 1024x768. Each was checked across Home, Decisions, Decision detail, Add option modal, Selections and People (36 view/viewport combinations). No document-level horizontal overflow or JavaScript exceptions. Verified creating and voting on a new option in demo.

These are browser emulation tests, not tests on a physical iPhone or your live Supabase accounts.
