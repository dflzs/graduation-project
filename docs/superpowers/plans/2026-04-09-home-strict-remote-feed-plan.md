# Home Strict Remote Feed Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the home product feed, search, and category filtering show only cloud-backed products so public browsing and trade entry stay on one server-driven data source.

**Architecture:** Keep the existing `HomePage` UI and filtering behavior, but stop falling back to local seed products for the public feed. The home page will render only ids returned by the remote product list API, and when the cloud feed is empty or unavailable it will show an empty/error state instead of mixing in local demo data.

**Tech Stack:** ArkTS, HarmonyOS ArkUI, existing `HomePage`, `productRepository`, `remoteProductClient`, Hypium local unit tests.

---

### Task 1: Lock Home Feed To Remote Product IDs

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add a unit test proving that home-feed id selection does not fall back to local-only product ids when the remote id list is empty.

- [ ] **Step 2: Run test to verify it fails**

Run the relevant local unit suite in DevEco.
Expected: FAIL because the current home feed logic still includes local products when no remote ids are known.

- [ ] **Step 3: Write minimal implementation**

Extract a tiny helper for home-feed source selection if needed, or simplify `HomePage.refreshProductsFromLocalState()` so it only reads products whose ids came from the remote list response.

- [ ] **Step 4: Run test to verify it passes**

Run the same local unit test in DevEco.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Home/HomePage.ets entry/src/test/LocalUnit.test.ets
git commit -m "refactor: make home feed cloud-only"
```

### Task 2: Keep Empty And Error States Honest

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add a test for the empty/error copy decision when remote products are unavailable and no cloud-backed items exist.

- [ ] **Step 2: Run test to verify it fails**

Run the relevant local unit suite in DevEco.
Expected: FAIL because the current page still hides this case behind local fallback content.

- [ ] **Step 3: Write minimal implementation**

Update `HomePage.refreshProducts()` and related empty-text handling so remote failure shows the proper message and remote-empty shows `暂无在售商品` rather than local seed cards.

- [ ] **Step 4: Run test to verify it passes**

Run the same local unit test in DevEco.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Home/HomePage.ets entry/src/test/LocalUnit.test.ets
git commit -m "fix: remove local fallback from home feed"
```

### Task 3: Verify Search And Category Filters Still Work On Cloud Feed

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] **Step 1: Write the failing test**

Add a focused regression test showing that cloud-backed ids still filter correctly by keyword and category after the source change.

- [ ] **Step 2: Run test to verify it fails**

Run the relevant local unit suite in DevEco.
Expected: FAIL if the filter logic accidentally depends on local fallback behavior.

- [ ] **Step 3: Write minimal implementation**

Adjust any helper or page logic only if needed to keep filtering behavior unchanged on the cloud-only feed.

- [ ] **Step 4: Run test to verify it passes**

Run the same local unit test in DevEco.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add entry/src/test/LocalUnit.test.ets entry/src/main/ets/pages/Home/HomePage.ets
git commit -m "test: cover cloud-only home feed filtering"
```
