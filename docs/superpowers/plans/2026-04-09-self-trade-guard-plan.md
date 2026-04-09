# Self Trade Guard Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Block users from buying or carting their own products at the earliest possible entry points, while keeping service-layer protection as a hard backstop.

**Architecture:** Add a shared ownership guard for transaction entry decisions, enforce it in both UI entry points and service methods, and preserve a final validation in checkout. Existing cart data is not auto-deleted; instead, invalid self-owned items are clearly blocked from settlement and guided toward manual removal.

**Tech Stack:** ArkTS, HarmonyOS UI, existing local unit tests in `entry/src/test/LocalUnit.test.ets`

---

### Task 1: Add failing tests for self-trade guards

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing test for self-owned product cart blocking**

- [ ] **Step 2: Write failing test for self-owned product order blocking**

- [ ] **Step 3: Write failing test for cart checkout helper behavior around self-owned products if a helper is introduced**

- [ ] **Step 4: Verify tests are logically red**

- [ ] **Step 5: Commit after implementation passes**

### Task 2: Harden service-layer transaction rules

**Files:**
- Modify: `entry/src/main/ets/services/cart.service.impl.ets`
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Optional create: `entry/src/main/ets/utils/trade-guard.ets`

- [ ] **Step 1: Add a minimal shared check for “current user owns this product”**

- [ ] **Step 2: Make cart service reject adding self-owned products**

- [ ] **Step 3: Keep order service self-purchase rejection as the final hard stop**

- [ ] **Step 4: Re-run target tests**

- [ ] **Step 5: Commit**

### Task 3: Fix misleading UI entry points

**Files:**
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
- Modify: `entry/src/main/ets/components/CartContent.ets`

- [ ] **Step 1: Disable or relabel self-owned product purchase actions in product detail**

- [ ] **Step 2: Show a direct toast if a user taps self-owned product actions**

- [ ] **Step 3: Guard checkout page entry for self-owned products and return early**

- [ ] **Step 4: Prevent cart settlement for self-owned items already present from historical data**

- [ ] **Step 5: Re-run verification**

### Task 4: Review neighboring anti-patterns in the trade flow

**Files:**
- Review: `entry/src/main/ets/pages/Home/HomePage.ets`
- Review: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Review: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Review: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`

- [ ] **Step 1: Check for other “allowed to enter, then blocked later” trade actions**

- [ ] **Step 2: Apply only minimal guard fixes if a nearby issue is directly related**

- [ ] **Step 3: Summarize any remaining non-blocking UX debts instead of expanding scope**

### Task 5: Validate and report

**Files:**
- Modify if needed: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run the narrowest available local verification**

- [ ] **Step 2: If local harness cannot run, state that clearly and rely on user-side DevEco verification**

- [ ] **Step 3: Report fixed paths, verified behavior, and any residual risks**
