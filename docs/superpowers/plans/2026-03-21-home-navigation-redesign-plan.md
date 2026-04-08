# Home And Navigation Redesign Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the client from a development-shell navigation flow into a formal marketplace app structure with a real home page and a Xianyu-inspired bottom navigation model.

**Architecture:** Rebuild `Index.ets` into the true app shell with five navigation sections, migrate current home responsibilities into the real home tab, move announcement access into a home strip instead of a dedicated tab, and split browsing concerns between `首页` and `分类`. Keep current backend product read integration intact while restructuring the UI hierarchy incrementally.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative UI, existing remote product client, current product domain model

---

## Chunk 1: App Shell Restructure

### Task 1: Redesign the main shell into the final navigation structure

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: `Index` is still a temporary jump page and still includes a dedicated announcement tab.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: page still contains the old "进入首页" structure and `公告` tab

- [ ] **Step 3: Write minimal implementation**

Update `Index.ets` so it:

- becomes the true app shell
- uses bottom navigation structure:
  - 首页
  - 分类
  - 发布
  - 消息
  - 我的
- removes the dedicated `公告` tab
- gives `发布` a center-primary visual treatment if feasible within current ArkUI layout patterns

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Index.ets`
Expected: old jump-page structure is gone and the new tab responsibilities exist

## Chunk 2: Real Home Page

### Task 2: Move home into the true first tab

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: product browsing still lives behind a second navigation step.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Index.ets` and `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: users still need to enter `HomePage` from `Index`

- [ ] **Step 3: Write minimal implementation**

Refactor so the real home tab contains:

- fixed search bar
- announcement strip with latest 1 to 2 items
- product feed

Keep product loading logic stable while removing the extra "进入首页" layer.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect modified files
Expected: the true home experience is reachable immediately from the first tab

## Chunk 3: Home Feed Visual Redesign

### Task 3: Upgrade home feed into a two-column marketplace layout

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: the home feed is still a plain single-column list and duplicates category controls that should belong to the category tab.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: single-column cards and category buttons still exist on home

- [ ] **Step 3: Write minimal implementation**

Update home so it:

- removes category controls from home
- keeps search-driven filtering
- uses a two-column product card flow
- includes an announcement strip entry to the announcement history page

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: home is product-led, search-first, and category UI is removed

## Chunk 4: Category / Message / My Responsibilities

### Task 4: Create or adapt the remaining tab content to match the approved architecture

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Create or Modify as needed for category/message placeholders

- [ ] **Step 1: Write the failing test**

Document the current gap: category and message tabs do not yet reflect their approved responsibilities.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect relevant tab content in `Index.ets`
Expected: category and message do not yet map to the approved structure

- [ ] **Step 3: Write minimal implementation**

Adjust tab content so:

- 分类 acts as category-channel browsing
- 消息 acts as message/session shell
- 我的 consolidates profile and personal actions

- [ ] **Step 4: Run test to verify it passes**

Run: inspect modified files
Expected: all five tabs align with the approved information architecture

## Chunk 5: Verification

### Task 5: Verify the new navigation flow safely

**Files:**
- Verify: `entry/src/main/ets/pages/Index.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Verify any category/message placeholder files added

- [ ] **Step 1: Run static inspection**

Run: inspect the modified navigation files
Expected: no duplicate "home inside home" flow remains

- [ ] **Step 2: Run available local verification**

Run: HarmonyOS build in DevEco or local CLI if available
Expected: build succeeds without new compile errors

- [ ] **Step 3: Manual runtime verification**

Verify in emulator:

- first tab opens the real home experience directly
- search stays at the top
- announcement strip opens announcement history
- home uses two-column product cards
- no dedicated announcement tab remains
- publish tab/button opens publish page
