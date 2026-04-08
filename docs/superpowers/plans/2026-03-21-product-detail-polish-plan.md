# Product Detail Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the client product detail page into a more polished e-commerce-style page while keeping the current remote detail loading flow unchanged.

**Architecture:** Keep the remote data loading and trade guard logic in the existing page, but reorganize the UI into a hero section, info cards, and a fixed bottom action bar. Extract only lightweight presentation helpers if needed; do not expand the page into new business modules.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative UI, existing remote product detail client

---

## Chunk 1: Product Detail Presentation Helpers

### Task 1: Add or refine display helpers for status and action copy

**Files:**
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current gap: the page shows plain status text and button labels without richer display states for polished presentation.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: no helper output exists for status chip colors or disabled button copy

- [ ] **Step 3: Write minimal implementation**

Add helpers for:

- status label
- status chip colors
- disabled button text for unavailable products

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: helper functions exist and are used by the UI

## Chunk 2: Product Detail Page Polish

### Task 2: Rebuild the page layout into an e-commerce style detail view

**Files:**
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: the detail page is still a plain text stack and unavailable products still look actionable.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: no hero area, no information cards, and no fixed bottom action bar

- [ ] **Step 3: Write minimal implementation**

Update the page to:

- add a product hero section
- show title, price, status chip, category chip, and location chip
- split detail content into white cards
- add centered loading/error states
- pin action buttons to the bottom
- disable action buttons visually when `status !== 'on_sale'`

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: polished layout structure and disabled button state are present

## Chunk 3: Verification

### Task 3: Verify the polished detail page safely

**Files:**
- Verify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`

- [ ] **Step 1: Run static inspection**

Run: inspect the modified page
Expected: remote load path is still intact and UI branches remain valid

- [ ] **Step 2: Run available local verification**

Run: local CLI/tooling check if available
Expected: if unavailable, explicitly record that no local HarmonyOS test/build command exists in this environment

- [ ] **Step 3: Manual runtime verification in emulator**

Open the product detail page from the home list.
Expected:

- remote product data renders correctly
- `已下架` state is visually obvious
- bottom buttons look disabled for unavailable products
- page does not crash
