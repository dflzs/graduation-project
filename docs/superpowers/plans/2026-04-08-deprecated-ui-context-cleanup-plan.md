# Deprecated UIContext Cleanup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace deprecated global router and toast usage with `UIContext` helpers in the first migration batch of ArkTS pages.

**Architecture:** Introduce one thin `UIContext` utility that accepts a page/component host and forwards navigation/toast calls to `getUIContext().getRouter()` and `getUIContext().getPromptAction()`. Use it to migrate pages mechanically while keeping existing route options and toast payloads unchanged.

**Tech Stack:** ArkTS, HarmonyOS ArkUI `UIContext`, existing Hypium tests, hvigor compile/test pipeline.

---

## Chunk 1: Shared Helper and Tests

### Task 1: Add a thin UIContext helper

**Files:**
- Create: `entry/src/main/ets/utils/ui-context-actions.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] Add failing helper tests for push/replace/back/getParams/showToast delegation.
- [ ] Implement the thin helper with no behavior changes.
- [ ] Re-run focused tests.

## Chunk 2: Pilot Migration

### Task 2: Migrate a small pilot set

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`

- [ ] Replace deprecated navigation/toast calls with helper calls.
- [ ] Keep page flow identical.
- [ ] Run `assembleHap` and verify the pilot warnings disappear.

## Chunk 3: First Batch Migration

### Task 3: Migrate the main warning-heavy pages

**Files:**
- Modify: `entry/src/main/ets/components/CartContent.ets`
- Modify: `entry/src/main/ets/pages/Announcement/AnnouncementPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Modify: `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/DirectRegisterPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/PhoneLoginStep1Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/PhoneLoginStep2Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterVerifyPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep1Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep2Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep3Page.ets`

- [ ] Convert page imports and replace helper-covered calls.
- [ ] Leave capability warnings untouched.
- [ ] Re-run compile verification.

## Chunk 4: Verification and Remaining Surface

### Task 4: Re-run tests and summarize leftovers

**Files:**
- Modify: `docs/superpowers/plans/2026-04-08-deprecated-ui-context-cleanup-plan.md`

- [ ] Run `hvigor test`.
- [ ] Run `assembleHap`.
- [ ] Record the remaining warning categories after this batch.
