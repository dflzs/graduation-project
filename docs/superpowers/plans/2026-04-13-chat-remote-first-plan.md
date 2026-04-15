# Chat Remote-First Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move chat conversation and message reads/writes onto backend APIs first while preserving the current local-cache fallback experience.

**Architecture:** Keep the existing `ChatService` as the only boundary that pages use, but convert the service into an async remote-first facade similar to the order service. Remote conversation/message responses should hydrate the local chat repository so unread counts, detail pages, and fallback reads all stay consistent even when remote requests fail.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing local repositories, `AuthStateService`, backend `/api/conversations` endpoints, Hypium unit tests, hvigor verification.

---

## Chunk 1: Remote Chat Contracts And Client Foundation

### Task 1: Add remote chat DTOs

**Files:**
- Create: `entry/src/main/ets/types/chat-remote.ets`
- Reference: `backend_code/chat.controller.js`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add a test that maps one remote conversation item and one remote message item into the existing local/domain shape expected by chat pages.

- [ ] **Step 2: Run test to verify it fails**

Run: hvigor local unit test command with `--testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because remote chat DTOs and mapping helpers do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create DTOs for:
- remote conversation list item
- remote conversation detail response
- remote message list response
- remote message detail response
- create conversation payload
- send message payload

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS for the new remote mapping assertions.

### Task 2: Add remote chat client

**Files:**
- Create: `entry/src/main/ets/services/chat-remote.client.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add a fake remote chat client usage test that expects methods for:
- `listConversations`
- `getMessages`
- `createConversation`
- `sendMessage`

- [ ] **Step 2: Run test to verify it fails**

Run: hvigor local unit test command with `--testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because the remote client contract/methods are missing.

- [ ] **Step 3: Write minimal implementation**

Implement a remote chat client using the existing `AUTH_API_BASE_URL`/`AUTH_HTTP_TIMEOUT_MS` pattern and `/api/conversations` endpoints.

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS for the client-facing behavior tests.

## Chunk 2: Chat Service Remote-First Behavior

### Task 3: Convert service contracts to async chat operations

**Files:**
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/services/chat.service.impl.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add service tests proving:
- list threads prefers remote and hydrates local cache
- get messages prefers remote and hydrates local cache
- send message prefers remote and writes back locally
- open product thread prefers remote for numeric product ids and logged-in buyer sessions

- [ ] **Step 2: Run test to verify it fails**

Run: hvigor local unit test command with `--testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because `ChatService` is still synchronous/local-only.

- [ ] **Step 3: Write minimal implementation**

Update `ChatService` and `ChatServiceImpl` so these methods become async remote-first:
- `listThreads`
- `countUnread`
- `getMessages`
- `openProductThread`
- `sendMessage`

Keep:
- local validation and permission guards
- local fallback when no token, non-numeric ids, or remote failure
- read-only restricted participant behavior

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS for all new service-level remote-first behaviors.

### Task 4: Hydrate local repositories from remote chat data

**Files:**
- Modify: `entry/src/main/ets/services/chat.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/chat.repo.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add a test that remote unread/message data updates local thread ordering, unread counts, and detail reads after fallback.

- [ ] **Step 2: Run test to verify it fails**

Run: hvigor local unit test command with `--testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because local hydration helpers are not complete enough yet.

- [ ] **Step 3: Write minimal implementation**

Add repository/service helpers to:
- save remote thread records
- upsert remote messages
- keep local thread `updatedAt` in sync with remote last message time
- mark fetched messages as read locally for the viewer

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS for cache hydration and unread consistency.

## Chunk 3: Page Async Wiring

### Task 5: Update message hub and detail pages

**Files:**
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add tests that cover async chat service callers which now need awaiting and still preserve prior permission semantics.

- [ ] **Step 2: Run test to verify it fails**

Run: hvigor local unit test command with `--testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because pages and usage sites still assume synchronous chat service calls.

- [ ] **Step 3: Write minimal implementation**

Update the relevant pages so:
- message hub refresh awaits remote-first thread reads
- chat detail refresh/send await remote-first reads/writes
- product detail await thread creation before routing
- index unread badge refresh awaits remote-first unread reads

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS with no type/runtime errors from the async boundary shift.

## Chunk 4: Verification

### Task 6: Run end-to-end project verification

**Files:**
- Verify only: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run local unit tests**

Run:
```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 2: Run assemble verification**

Run:
```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Commit**

Use explicit `git add` paths only. Do not use `git add .`.

Plan complete and saved to `docs/superpowers/plans/2026-04-13-chat-remote-first-plan.md`. Ready to execute.
