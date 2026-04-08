# Admin And Home Polish Design

**Goal**

Unify the admin-facing pages and the home product feed with the same top-down product layout language already used in the improved cart and primary pages.

**Design Summary**

- Admin pages should feel like part of the same app, not separate tooling screens.
- Every page should start from the top with a left-aligned title, an optional right-side action, a short explanatory line, and content cards directly below.
- Home product cards should read faster: image first, tighter status/location row, stronger title/price hierarchy, and a clearer secondary action cue.

**Page Decisions**

- `AdminDashboardPage` becomes a product-style overview with a compact header, stat cards, and clearly grouped entry actions.
- `AdminUsersPage` becomes a moderation list with readable identity, role, status, credit, and a strong right-side action.
- `AdminProductsPage` becomes a review queue with better item hierarchy, state badges, and cleaner action grouping for review and force-off-shelf actions.
- `AdminAnnouncementPage` becomes a simple content workspace: compose card first, then published announcement cards below.
- `HomePage` keeps the existing search/category structure, but product cards get tighter spacing, better scan order, and a more polished price/footer section.

**Interaction Notes**

- Existing behavior stays the same; this pass is layout and presentation polish.
- Admin guards and existing navigation remain in place.
- Empty/error/loading states should continue using the shared components already introduced.

**Success Criteria**

- Admin pages visually match the rest of the app instead of looking like raw CRUD panels.
- Home cards feel more intentional and more like a real marketplace feed.
- No page content appears vertically stranded in the middle of the screen.
