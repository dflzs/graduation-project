# Avatar Upload And Publish Copy Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the publish page to Chinese product copy and add a complete current-user avatar upload flow with immediate local refresh.

**Architecture:** Reuse the existing image-upload client for both product covers and avatars, add a minimal authenticated `PUT /api/auth/me` backend entry for avatar updates, and refresh the persisted local session after the backend returns the updated user. Keep the current publish-product upload chain intact while only changing presentation copy there.

**Tech Stack:** ArkTS, DevEco/HarmonyOS, local repositories, persisted auth state, Node.js Express backend reference code, existing `/api/upload/image` transport.

---

## Chunk 1: Contracts And Tests

### Task 1: Add failing tests for avatar update helpers and auth-session refresh

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`

- [ ] **Step 1: Write the failing tests**

Add tests covering:
- a remote current-user update payload carrying `avatar`
- auth service updating the current session user avatar after a successful remote response

- [ ] **Step 2: Run the targeted test scope to verify it fails**

Run: DevEco local unit test flow or existing local Hypium run for `LocalUnit.test.ets`
Expected: FAIL because update-current-user contracts and behavior do not exist yet

- [ ] **Step 3: Add minimal type definitions**

Add:
- `RemoteUpdateMePayload`
- `RemoteMeResponse`
- `AuthService.updateAvatar(...)`

- [ ] **Step 4: Re-run the targeted test scope**

Expected: still FAIL, but now specifically because implementation is missing

## Chunk 2: Frontend Avatar Remote Flow

### Task 2: Add current-user update support to the remote auth client

**Files:**
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/types/auth-remote.ets`

- [ ] **Step 1: Write the failing test expectation**

Use the test from Chunk 1 as the failing guard.

- [ ] **Step 2: Implement minimal remote client support**

Add an authenticated `PUT /api/auth/me` request helper and a public method for avatar update.

- [ ] **Step 3: Re-run targeted tests**

Expected: still FAIL until auth service wiring is added

### Task 3: Update auth service, repository, and persisted session

**Files:**
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/user.repo.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`

- [ ] **Step 1: Implement minimal avatar update flow**

Behavior:
- require active session
- call remote update endpoint
- merge returned user into local repository
- update in-memory session
- persist with `authStateService.saveSession(...)`

- [ ] **Step 2: Re-run targeted tests**

Expected: PASS for avatar/session update tests

## Chunk 3: UI Updates

### Task 4: Restore publish page Chinese copy without changing logic

**Files:**
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`

- [ ] **Step 1: Keep current logic intact and replace temporary English labels with Chinese copy**

Restore product-facing Chinese text for:
- title
- helper text
- cover section
- buttons
- placeholders

- [ ] **Step 2: Rebuild mentally against the existing compile issue hotspots**

Check builder structure remains unchanged and no new ArkTS syntax risk is introduced.

### Task 5: Add avatar upload entry to the bottom-tab “我的” page

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/utils/cover-image.ets`

- [ ] **Step 1: Add a small avatar action area to the current user card**

Support:
- choose from album
- remove local selection if needed
- simulator URL fallback
- save avatar action

- [ ] **Step 2: Reuse existing upload flow**

If a local file is selected:
- upload first
- then call avatar update

If no local file is selected:
- use validated manual URL fallback

- [ ] **Step 3: Refresh local page state after success**

Expected:
- avatar preview updates immediately in the current tab
- reopening the app still shows the new avatar

## Chunk 4: Backend Reference Sync Files

### Task 6: Add current-user avatar update backend reference code

**Files:**
- Modify: `backend_code/auth.controller.js`
- Modify: `backend_code/auth.routes.js`

- [ ] **Step 1: Add an authenticated `PUT /api/auth/me` handler**

Behavior:
- read `req.user.id`
- validate avatar string
- update `users.avatar`
- return updated user row

- [ ] **Step 2: Wire route in `auth.routes.js`**

Add `router.put('/me', authMiddleware, updateMe);`

- [ ] **Step 3: Run backend syntax verification**

Run:
- `node -c backend_code/auth.controller.js`
- `node -c backend_code/auth.routes.js`

Expected: both commands produce no output

## Chunk 5: Final Verification

### Task 7: Verify the integrated flow

**Files:**
- Test: `entry/src/test/LocalUnit.test.ets`
- Manual: publish page and “我的” page

- [ ] **Step 1: Run local unit verification**

Run the relevant local unit tests for:
- upload URL handling
- manual URL validation
- avatar update session refresh

- [ ] **Step 2: Compile the ArkTS app**

Run: DevEco `assembleHap`
Expected: build succeeds

- [ ] **Step 3: Manual app verification**

Check:
- publish page is back to Chinese
- product cover flow still works
- avatar can be updated from “我的”
- avatar remains after page revisit / session restore

- [ ] **Step 4: Prepare cloud sync follow-up**

If local verification passes, sync only:
- `backend_code/auth.controller.js`
- `backend_code/auth.routes.js`

Then restart PM2 and verify `PUT /api/auth/me`.
