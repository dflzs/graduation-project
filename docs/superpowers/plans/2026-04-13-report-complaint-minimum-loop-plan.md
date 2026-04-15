# Report And Complaint Minimum Loop Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the first abnormal-trade governance loop so users can submit order complaints and chat reports, and admins can review them from a dedicated backend page.

**Architecture:** Implement this as one vertical slice with shared moderation domain objects, a remote-first moderation service on the client, and minimal backend persistence endpoints. Keep the first slice narrow: support order complaints and chat reports first, reserve appeal as a model-ready extension instead of opening a half-finished user flow.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing remote client/service pattern, Node backend controllers under `backend_code`, Hypium local unit tests.

---

## Chunk 1: Shared Moderation Domain

### Task 1: Add report/complaint domain and client contracts

**Files:**
- Create: `entry/src/main/ets/types/moderation-remote.ets`
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add unit coverage for:
- mapping a remote moderation item into a local moderation record
- rejecting unsupported report targets
- distinguishing `order_complaint` and `chat_report`

- [ ] **Step 2: Run test to verify it fails**

Run: `LocalUnit.test.ets`
Expected: missing types / helper import / assertions fail.

- [ ] **Step 3: Write minimal implementation**

Add:
- `ModerationTargetType`
- `ModerationStatus`
- `ModerationRecord`
- remote payload/response types
- `ModerationService` contract

- [ ] **Step 4: Run test to verify it passes**

Run: `LocalUnit.test.ets`
Expected: new moderation domain assertions pass.

## Chunk 2: Remote-First Moderation Service

### Task 2: Add moderation remote client and service with local cache fallback

**Files:**
- Create: `entry/src/main/ets/repositories/moderation.repo.ets`
- Create: `entry/src/main/ets/services/moderation-remote.client.ets`
- Create: `entry/src/main/ets/services/moderation.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add unit coverage for:
- remote-first submit complaint/report succeeds and hydrates local cache
- remote failure falls back to local cache record
- admin review list hydrates local cache
- admin review action updates local status and emits sync

- [ ] **Step 2: Run test to verify it fails**

Run: `LocalUnit.test.ets`
Expected: missing service/client/repository assertions fail.

- [ ] **Step 3: Write minimal implementation**

Implement:
- local moderation repository
- remote client for submit/list/review
- service-level permission checks
- sync keys such as `moderation:changed`

- [ ] **Step 4: Run test to verify it passes**

Run: `LocalUnit.test.ets`
Expected: moderation service assertions pass.

## Chunk 3: User Entry Points

### Task 3: Add complaint/report entry points on order detail and chat detail

**Files:**
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`

- [ ] **Step 1: Add order complaint entry**

Allow trade participants with active user accounts to submit an order complaint from order detail.

- [ ] **Step 2: Add chat report entry**

Allow conversation participants with active user accounts to submit a chat report from chat detail.

- [ ] **Step 3: Keep restricted/admin semantics consistent**

Do not expose submit actions to admins or restricted users; show conservative readonly guidance instead.

- [ ] **Step 4: Run build verification**

Run: `assembleHap`
Expected: build passes with the new UI entry points.

## Chunk 4: Admin Review Page

### Task 4: Add backend moderation review page

**Files:**
- Create: `entry/src/main/ets/pages/Admin/AdminModerationPage.ets`
- Modify: `entry/src/main/ets/utils/admin-navigation.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add unit coverage for:
- admin moderation list access guard
- review action status transitions
- sync refresh after review

- [ ] **Step 2: Run test to verify it fails**

Run: `LocalUnit.test.ets`
Expected: missing page/service wiring assertions fail.

- [ ] **Step 3: Write minimal implementation**

Render tabs for pending / resolved moderation items and expose approve / reject style review actions.

- [ ] **Step 4: Run verification**

Run:
- `LocalUnit.test.ets`
- `assembleHap`

Expected: both pass.

## Chunk 5: Backend Support

### Task 5: Add minimal backend persistence and review endpoints

**Files:**
- Create: `backend_code/moderation.controller.js`
- Create: `backend_code/moderation.routes.js`
- Modify: backend route registration file if present in deployment source
- Update docs only if route registration lives in `backend_code/云服务器后端代码.md`

- [ ] **Step 1: Add submit endpoints**

Support creating:
- order complaints
- chat reports

- [ ] **Step 2: Add admin list/review endpoints**

Support:
- list moderation records
- review record with status and admin comment

- [ ] **Step 3: Keep scope narrow**

Do not open a full appeal center yet; only keep fields and status design extensible.

- [ ] **Step 4: Re-run project verification**

Run:
- `LocalUnit.test.ets`
- `assembleHap`

Expected: client still passes after backend-facing contract changes.

Plan complete and saved to `docs/superpowers/plans/2026-04-13-report-complaint-minimum-loop-plan.md`. Ready to execute.
