# Governance And Trust System Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the current moderation minimum loop into a complete governance and trust subsystem for the campus marketplace.

**Architecture:** Build this in three connected tranches: full moderation domain, appeal and user governance center, then governance-action and trust-signal integration. Keep remote-first service patterns, local hydration, and sync/event consistency aligned with the rest of the project.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing service/repository/remote-client pattern, Node backend under `backend_code`, Hypium local tests, DevEco hvigor verification.

## Progress Snapshot

**Updated:** 2026-04-15

Completed in repo:
- full moderation domain, lifecycle, repository persistence, and remote-first service path
- product/user/chat/order governance entry support
- admin moderation workbench, appeal review queue, and governance-action linkage
- appeal domain, repository, remote-first service, governance center, and appeal submission flow
- governance action domain/service, richer user status semantics, admin-user governance integration, and public trust signals
- governance center, admin moderation page, and moderation/appeal submit pages normalized onto shared copy helpers

Still worth finishing:
- backend route bootstrap and deployment-side final verification in the live server source tree
- governance system docs/status cleanup beyond this plan snapshot
- low-yield copy polish outside the governance main path

---

## Chunk 1: Full Moderation Domain

### Task 1: Expand moderation types, statuses, and record structure

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/types/moderation-remote.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write the failing tests**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify the new assertions fail for missing statuses/fields**
- [x] **Step 3: Add richer moderation target types, lifecycle statuses, and expanded record fields**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify the domain tests pass**

### Task 2: Expand moderation repository persistence

**Files:**
- Modify: `entry/src/main/ets/repositories/moderation.repo.ets`
- Modify: `entry/src/main/ets/data/db/local-db.ets`
- Modify: `entry/src/main/ets/data/db/persisted-state.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for richer moderation persistence and replacement behavior**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify persistence tests fail**
- [x] **Step 3: Support the richer moderation shape in local persistence and compatibility normalization**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify persistence tests pass**

### Task 3: Expand moderation remote client and service lifecycle

**Files:**
- Modify: `entry/src/main/ets/services/moderation-remote.client.ets`
- Modify: `entry/src/main/ets/services/moderation.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for triage, evidence-request, close, and richer review transitions**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify lifecycle tests fail**
- [x] **Step 3: Implement remote-first lifecycle operations with local fallback and sync publication**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify moderation lifecycle tests pass**

### Task 4: Add product and user report entry support

**Files:**
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Moderation/SubmitModerationPage.ets`
- Modify: `entry/src/main/ets/utils/trade-guard.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for report target selection and audience gating**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify these tests fail**
- [x] **Step 3: Add product-report and user-report entry points with consistent role/status semantics**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify entry-point tests pass**

### Task 5: Upgrade admin moderation page into a real workbench

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminModerationPage.ets`
- Modify: `entry/src/main/ets/utils/admin-navigation.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for queue filters, status tabs, and admin workbench actions**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify workbench tests fail**
- [x] **Step 3: Add queue filters, richer status handling, target summaries, and close/review actions**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify admin moderation tests pass**

## Chunk 2: Appeal Flow And User Governance Center

### Task 6: Add appeal domain and contracts

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Create: `entry/src/main/ets/types/appeal-remote.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for appeal model, status transitions, and eligibility**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify appeal-domain tests fail**
- [x] **Step 3: Add appeal types and service contracts**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify appeal-domain tests pass**

### Task 7: Add appeal repository, remote client, and service

**Files:**
- Create: `entry/src/main/ets/repositories/appeal.repo.ets`
- Create: `entry/src/main/ets/services/appeal-remote.client.ets`
- Create: `entry/src/main/ets/services/appeal.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/main/ets/data/db/local-db.ets`
- Modify: `entry/src/main/ets/data/db/persisted-state.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for appeal submit/list/review and sync behavior**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify appeal-service tests fail**
- [x] **Step 3: Implement remote-first appeal handling with local fallback**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify appeal-service tests pass**

### Task 8: Add user-facing governance center

**Files:**
- Create: `entry/src/main/ets/pages/Profile/GovernanceCenterPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Moderation/SubmitModerationPage.ets`
- Modify: `entry/src/main/ets/utils/marketplace-audience-ui.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for governance-center routing and audience semantics**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify these tests fail**
- [x] **Step 3: Add governance-center page showing report, complaint, appeal, and status history**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify governance-center tests pass**

### Task 9: Add appeal entry and appeal review UI

**Files:**
- Create: `entry/src/main/ets/pages/Moderation/SubmitAppealPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminModerationPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/GovernanceCenterPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for appeal entry visibility and appeal review behavior**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify these tests fail**
- [x] **Step 3: Add appeal submission page and admin appeal review queue**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify appeal UI tests pass**

## Chunk 3: Governance Actions And Trust Integration

### Task 10: Add governance-action domain and service

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Create: `entry/src/main/ets/types/governance-remote.ets`
- Create: `entry/src/main/ets/repositories/governance.repo.ets`
- Create: `entry/src/main/ets/services/governance-remote.client.ets`
- Create: `entry/src/main/ets/services/governance.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for warning, restrict, mute, suspend, and ban actions**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify governance-action tests fail**
- [x] **Step 3: Implement governance actions and sync publication**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify governance-action tests pass**

### Task 11: Upgrade user status model and permission effects

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/repositories/user.repo.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/services/chat.service.impl.ets`
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/services/cart.service.impl.ets`
- Modify: `entry/src/main/ets/utils/trade-guard.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for `restricted`, `muted`, and `suspended` user semantics**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify these permission tests fail**
- [x] **Step 3: Extend user status behavior across auth, chat, orders, cart, and page guards**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify permission tests pass**

### Task 12: Integrate governance action UI into admin users page

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Modify: `entry/src/main/ets/services/admin-user.service.impl.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for richer admin governance actions and summaries**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify admin-user governance tests fail**
- [x] **Step 3: Add action controls, governance summaries, and current restriction displays**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify admin-user governance tests pass**

### Task 13: Integrate trust signals into public-facing UI

**Files:**
- Modify: `entry/src/main/ets/utils/campus-trust-ui.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [x] **Step 1: Write failing tests for enriched trust badges and summaries**
- [x] **Step 2: Run `LocalUnit.test.ets` and verify trust-presentation tests fail**
- [x] **Step 3: Show completed-trade, dispute, and current governance-trust summaries in conservative UI form**
- [x] **Step 4: Re-run `LocalUnit.test.ets` and verify trust-presentation tests pass**

## Chunk 4: Backend Remote-First Completion

### Task 14: Add moderation backend support

**Files:**
- Create: `backend_code/moderation.controller.js`
- Create: `backend_code/moderation.routes.js`
- Modify: backend route registration file if present in deployment source
- Modify: `backend_code/云服务器后端代码.md` only if the route bootstrap remains doc-driven in this repo

- [ ] **Step 1: Add moderation submit/list/detail/review/close endpoints**
- [ ] **Step 2: Add required validation and permission checks**
- [ ] **Step 3: Keep contracts aligned with ArkTS remote-client expectations**
- [ ] **Step 4: Re-run client verification after contract stabilization**

### Task 15: Add appeal backend support

**Files:**
- Create: `backend_code/appeal.controller.js`
- Create: `backend_code/appeal.routes.js`
- Modify: backend route registration file if present in deployment source

- [ ] **Step 1: Add appeal submit/list/review endpoints**
- [ ] **Step 2: Support appeal eligibility and review comments**
- [ ] **Step 3: Keep response envelope aligned with existing backend style**
- [ ] **Step 4: Re-run client verification after contract stabilization**

### Task 16: Add governance backend support

**Files:**
- Create: `backend_code/governance.controller.js`
- Create: `backend_code/governance.routes.js`
- Modify: backend route registration file if present in deployment source
- Modify: backend schema/bootstrap docs if current backend remains partially doc-managed

- [ ] **Step 1: Add governance action list/create/cancel endpoints**
- [ ] **Step 2: Add user governance summary endpoint**
- [ ] **Step 3: Keep user-state updates compatible with current frontend auth/user flows**
- [ ] **Step 4: Re-run client verification after contract stabilization**

## Global Verification

### Task 17: Full-project verification after each tranche

**Files:**
- Verify only: `entry/src/test/LocalUnit.test.ets`
- Verify only: `entry` assemble target

- [x] **Step 1: Run local unit tests**

Run:
`$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets --analyze=normal --parallel --incremental --daemon`

Expected: `BUILD SUCCESSFUL`

- [x] **Step 2: Run assemble verification**

Run:
`$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon`

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Keep forbidden local-environment files untouched**

Never modify:
- `local.properties`
- `.idea` SDK bindings
- `build-profile.json5`
- local SDK version or DevEco project bindings

Plan complete and saved to `docs/superpowers/plans/2026-04-13-governance-trust-system-plan.md`. Ready to execute?
