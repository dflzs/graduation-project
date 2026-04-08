# Global Search And In-Shell Cart Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make home-page search global across on-sale products and render cart as an in-shell bottom tab using shared cart content.

**Architecture:** Update `HomePage.ets` filtering so keywords search globally across all on-sale products while category browsing still works when the search box is empty. Extract cart UI into a reusable component and let both `CartPage.ets` and `Index.ets` render it so cart behavior stays in one place.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative UI, existing appContext cart/product state, current shell navigation

---

## Chunk 1: Reusable Cart Content

### Task 1: Extract cart body into a reusable component

**Files:**
- Create: `entry/src/main/ets/components/CartContent.ets`
- Modify: `entry/src/main/ets/pages/Cart/CartPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: cart rendering only exists inside routed `CartPage.ets`, so the shell tab cannot reuse it cleanly.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Cart/CartPage.ets`
Expected: cart UI and logic are tightly coupled to the page entry

- [ ] **Step 3: Write minimal implementation**

Move cart body rendering and refresh logic into a reusable component file. Keep `CartPage.ets` as a thin `@Entry` wrapper that renders the shared component.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect the new component and updated page
Expected: cart content can be reused without route navigation

## Chunk 2: In-Shell Cart Tab

### Task 2: Render cart inside the main shell

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Cart/CartPage.ets`
- Create or Reuse: `entry/src/main/ets/components/CartContent.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: bottom cart still pushes to another page instead of switching shell content.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: cart tab still calls `router.pushUrl`

- [ ] **Step 3: Write minimal implementation**

Update the shell so:

- cart occupies its own tab state
- cart tab renders shared cart content in place
- mine tab remains reachable as the last tab

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: cart no longer routes away from the shell

## Chunk 3: Global Search

### Task 3: Make home search global while preserving category browsing

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: search is still constrained by the selected category.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: filtering applies category before keyword for all cases

- [ ] **Step 3: Write minimal implementation**

Adjust home filtering so:

- all searches run across all on-sale products
- category filtering only applies when the keyword is empty
- feed header reflects search mode versus browse mode

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: keyword searches are global and category still works for browsing

## Chunk 4: Verification

### Task 4: Verify shell behavior

**Files:**
- Verify: `entry/src/main/ets/pages/Index.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Verify: `entry/src/main/ets/components/CartContent.ets`
- Verify: `entry/src/main/ets/pages/Cart/CartPage.ets`

- [ ] **Step 1: Run static inspection**

Run: inspect modified files
Expected: cart is shared, search is global, shell tab structure remains consistent

- [ ] **Step 2: Run available local verification**

Run: DevEco / hvigor build
Expected: build succeeds without new compile errors

- [ ] **Step 3: Manual runtime verification**

Verify in emulator:

- home search can find products regardless of selected category
- clearing the search box restores category-based browsing
- cart opens in the current shell instead of route-jumping
- standalone cart route still works if opened directly
