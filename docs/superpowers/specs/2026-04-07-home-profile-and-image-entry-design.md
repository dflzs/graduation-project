# Home Profile And Image Entry Design

**Goal**

Fix the inconsistent home product cards, rebuild the profile page into a more polished product-style account hub, and prepare the app for product-cover and user-avatar image entry.

**Design Summary**

- Home cards should use a fixed vertical rhythm so two-column cards no longer appear uneven.
- The profile page should stop looking like a button grid and instead feel like a real marketplace account page.
- Image support will be treated as a formal chain: data model and UI slots are prepared now, and upload entry is added through the existing remote image fields rather than one-off local hacks.

**Home Feed**

- Product cards use the same card height and internal section heights.
- Title, description, and price/footer each get fixed visual bands to keep the grid aligned.
- The card remains image-first and keeps the current click-through behavior.
- The footer is split into a clearer two-row commerce layout: the first row is price only, and the second row holds trade context on the left with a detail affordance on the right.
- Product category should no longer compete with price in the footer because the card already exposes category through the placeholder image block and overall content context.

**Profile Page**

- The page becomes: header, account card, grouped action cards, and logout action.
- The account card gets a stronger visual identity block so the page no longer feels like plain text plus buttons.
- Entry actions become list rows with title, short explanation, and right-side navigation cue.

**Image Readiness**

- Product cover and user avatar are already present in the remote data model.
- Front-end structures should preserve and display those fields cleanly.
- The actual native image-picker upload flow should be implemented as a separate, stable upload pass once the picker API is locked in.
