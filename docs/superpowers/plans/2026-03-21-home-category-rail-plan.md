# Home Category Rail Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move category navigation into the home page, remove the dedicated bottom category tab, and promote cart into the main bottom navigation.

**Architecture:** Update `Index.ets` to use the new five-slot bottom navigation and route cart directly from the shell. Extend `HomePage.ets` with a horizontal category rail and make the existing remote product feed filter by selected category plus keyword while preserving the current on-sale-only rule.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative UI, existing remote product client, current cart page route

---

## Chunk 1: Bottom Navigation Restructure

### Task 1: Replace the bottom category tab with cart

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: the bottom navigation still includes `分类`, and cart is not a first-level navigation item.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: bottom navigation still contains `分类`

- [ ] **Step 3: Write minimal implementation**

Update `Index.ets` so the bottom navigation becomes:

- 首页
- 消息
- 发布
- 购物车
- 我的

Wire `购物车` to the existing `pages/Cart/CartPage` route.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: `分类` is removed from the bottom navigation and `购物车` is present

## Chunk 2: Home Category Rail

### Task 2: Add horizontal category switching to the home page

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/constants/config.ets` (reference only if category constants need reuse)

- [ ] **Step 1: Write the failing test**

Document the current issue: the home page has no horizontal category rail and the feed cannot switch category in place.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: no horizontal category rail exists

- [ ] **Step 3: Write minimal implementation**

Extend `HomePage.ets` so it:

- tracks selected category with default `推荐`
- renders a horizontally scrollable category rail with:
  - 推荐
  - 教材书籍
  - 电子数码
  - 日用百货
  - 运动户外
  - 其他
- refreshes the product feed based on selected category + keyword
- keeps only `on_sale` products visible

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: category rail exists and filtering logic depends on selected category

## Chunk 3: Shell Routing Cleanup

### Task 3: Remove obsolete category tab content from the shell

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: `Index.ets` still contains the old category-tab builder and category-count shell content.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: category placeholder tab content still exists

- [ ] **Step 3: Write minimal implementation**

Remove obsolete category-tab-only content that is no longer needed after moving category switching into home. Keep message and mine tabs intact.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: no dedicated category tab content remains

## Chunk 4: Verification

### Task 4: Verify navigation and filtering behavior

**Files:**
- Verify: `entry/src/main/ets/pages/Index.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] **Step 1: Run static inspection**

Run: inspect modified files
Expected: home owns category switching and bottom navigation owns cart

- [ ] **Step 2: Run available local verification**

Run: DevEco / hvigor build
Expected: build succeeds without new compile errors

- [ ] **Step 3: Manual runtime verification**

Verify in emulator:

- home shows horizontal category rail below announcement strip
- switching category changes only the product feed
- search filters within the selected category scope
- bottom navigation shows `首页 / 消息 / 发布 / 购物车 / 我的`
- cart opens from the bottom navigation
