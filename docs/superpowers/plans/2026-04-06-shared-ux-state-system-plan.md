# Shared UX State System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize empty, loading, and error states across the highest-value user and admin pages in the campus marketplace.

**Architecture:** Introduce three reusable presentation components for empty, loading, and error states, then migrate key pages to those components without changing existing service or routing logic. Keep state ownership in each page while making presentation and copy consistent.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing page-service-repository structure, Hypium unit tests

---

## Chunk 1: Shared State Components

### Task 1: Create reusable empty/loading/error components

**Files:**
- Create: `entry/src/main/ets/components/EmptyState.ets`
- Create: `entry/src/main/ets/components/LoadingState.ets`
- Create: `entry/src/main/ets/components/ErrorState.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing component checklist**

```md
- EmptyState supports title, description, and optional action
- LoadingState supports title and optional description
- ErrorState supports title, description, and retry action
```

- [ ] **Step 2: Review current component layer to verify the gap**

Run: `rg -n "EmptyState|LoadingState|ErrorState" entry\\src\\main\\ets\\components entry\\src\\test`
Expected: no shared state components exist yet.

- [ ] **Step 3: Implement minimal shared components**

Add:
- one reusable empty-state component
- one reusable loading-state component
- one reusable error-state component
- lightweight prop surfaces only

- [ ] **Step 4: Re-check component checklist**

Run: `rg -n "struct EmptyState|struct LoadingState|struct ErrorState" entry\\src\\main\\ets\\components`
Expected: all three shared components exist.

- [ ] **Step 5: Checkpoint**

Record that key state presentation is now reusable instead of page-local.

## Chunk 2: User-Facing Page Adoption

### Task 2: Migrate home, order list, and my published products

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Modify: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing UI acceptance checklist**

```md
- home no longer uses ad hoc inline empty/loading blocks
- order list empty state uses shared component
- my published uses shared loading and empty or error presentation
```

- [ ] **Step 2: Review current pages against the checklist**

Run: `rg -n "buildEmptyState|buildLoadingState|errorText|暂无|正在加载" entry\\src\\main\\ets\\pages\\Home\\HomePage.ets entry\\src\\main\\ets\\pages\\Order\\OrderListPage.ets entry\\src\\main\\ets\\pages\\Product\\MyPublishedProductsPage.ets`
Expected: each page still contains page-specific state handling.

- [ ] **Step 3: Implement minimal migration**

Update:
- home page to use shared loading/empty presentation
- order list to use shared empty-state with browse action
- my published products to use shared loading and empty/error states

- [ ] **Step 4: Re-check UI acceptance checklist**

Run: `rg -n "EmptyState\\(|LoadingState\\(|ErrorState\\(" entry\\src\\main\\ets\\pages\\Home\\HomePage.ets entry\\src\\main\\ets\\pages\\Order\\OrderListPage.ets entry\\src\\main\\ets\\pages\\Product\\MyPublishedProductsPage.ets`
Expected: shared state components are now in use on all three pages.

- [ ] **Step 5: Checkpoint**

Record that the main user flows now share one state language.

## Chunk 3: Message Hub and Admin Adoption

### Task 3: Extend shared states to message hub and admin dashboard

**Files:**
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`

- [ ] **Step 1: Write the failing UI acceptance checklist**

```md
- message hub empty/login-empty presentation reads like one product family
- admin dashboard can surface empty or unavailable states more cleanly
- profile-adjacent empty/error wording stays consistent with the rest of the app
```

- [ ] **Step 2: Review current pages against the checklist**

Run: `rg -n "登录后|暂无|空态|加载|错误|失败" entry\\src\\main\\ets\\pages\\Chat\\MessageHubPage.ets entry\\src\\main\\ets\\pages\\Admin\\AdminDashboardPage.ets entry\\src\\main\\ets\\pages\\Profile\\ProfilePage.ets`
Expected: current pages still mix local phrasing and one-off state UI.

- [ ] **Step 3: Implement minimal migration**

Update:
- message hub empty/login-empty sections to align with shared state visual structure
- admin dashboard to use shared state where content is missing or unavailable
- profile page to align copy/styling where state-like messaging appears

- [ ] **Step 4: Re-check UI acceptance checklist**

Run: `rg -n "EmptyState\\(|LoadingState\\(|ErrorState\\(" entry\\src\\main\\ets\\pages\\Chat\\MessageHubPage.ets entry\\src\\main\\ets\\pages\\Admin\\AdminDashboardPage.ets entry\\src\\main\\ets\\pages\\Profile\\ProfilePage.ets`
Expected: shared state usage is visible where appropriate.

- [ ] **Step 5: Checkpoint**

Record that user-facing and admin-facing page states now feel part of one system.

## Chunk 4: Verification

### Task 4: Verify shared UX states

**Files:**
- Verify: `entry/src/main/ets/components/EmptyState.ets`
- Verify: `entry/src/main/ets/components/LoadingState.ets`
- Verify: `entry/src/main/ets/components/ErrorState.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Verify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Verify: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Verify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Verify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`

- [ ] **Step 1: Run static usage inspection**

Run: `rg -n "EmptyState\\(|LoadingState\\(|ErrorState\\(" entry\\src\\main\\ets\\pages entry\\src\\main\\ets\\components`
Expected: shared state components are reused across major pages.

- [ ] **Step 2: Run available local verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for existing unit tests, or document if local shell verification is still blocked and defer to DevEco.

- [ ] **Step 3: Manual runtime verification**

Verify in DevEco/emulator:
- home empty and loading states read clearly
- order list empty state has a sensible next action
- my published empty/loading/error states are consistent
- message hub empty/login-empty feels aligned with the rest of the app
- admin dashboard unavailable state does not look like a raw placeholder
