# Admin User Governance Remote-First Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move admin user list and ban/restore actions onto backend APIs first while preserving current local user cache and sync semantics.

**Architecture:** Add a small remote admin-user client for `/api/admin/users` and `/api/admin/users/:id/status`, then introduce a focused admin user service that hydrates `userRepository` from remote results. `AdminUsersPage` should stop reading/modifying only local state and instead await the remote-first service, while still falling back to local users if remote fetch or mutation fails.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing `userRepository`, `AuthStateService`, backend admin APIs, Hypium, hvigor.

---

## Chunk 1: Remote Contracts And Client

### Task 1: Add admin user remote DTOs and client

**Files:**
- Create: `entry/src/main/ets/types/admin-user-remote.ets`
- Create: `entry/src/main/ets/services/admin-user-remote.client.ets`
- Reference: `backend_code/admin.controller.js`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add tests that expect a remote admin-user client to support:
- list users
- update user status

- [ ] **Step 2: Run test to verify it fails**

Run the required local unit test command.
Expected: FAIL because the remote client/contracts do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create DTOs and client methods for:
- `/api/admin/users`
- `/api/admin/users/:id/status`

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS for the new remote client contract tests.

## Chunk 2: Remote-First Admin User Service

### Task 2: Add admin user service and cache hydration

**Files:**
- Create: `entry/src/main/ets/services/admin-user.service.impl.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add service tests proving:
- admin user list prefers remote and hydrates local `userRepository`
- user status mutation prefers remote, hydrates local repository, and keeps sync events intact
- remote failures fall back to the current local repository behavior

- [ ] **Step 2: Run test to verify it fails**

Run the required local unit test command.
Expected: FAIL because no admin-user service exists yet.

- [ ] **Step 3: Write minimal implementation**

Implement a focused service that:
- resolves admin token from `AuthStateService`
- uses remote list/update when possible
- merges remote basic user fields into local users without erasing existing campus/verification fields
- preserves `admin:user-status-changed` and `users:changed`

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS for the service-level remote-first behavior tests.

## Chunk 3: Admin Users Page Async Wiring

### Task 3: Update `AdminUsersPage`

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`

- [ ] **Step 1: Write the failing test**

Add or extend tests covering async list/toggle usage if needed.

- [ ] **Step 2: Run test to verify it fails**

Run the required local unit test command.
Expected: FAIL because the page still assumes synchronous local-only user management.

- [ ] **Step 3: Write minimal implementation**

Update the page so:
- refresh awaits remote-first user list loading
- toggle awaits remote-first ban/restore action
- current guard, summary cards, and sync subscriptions remain intact

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command.
Expected: PASS with the page now aligned to the async service boundary.

## Chunk 4: Verification

### Task 4: Run required verification

**Files:**
- Verify only: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run LocalUnit**

Run:
```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 2: Run assemble**

Run:
```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Commit**

If committing later, use explicit `git add` paths only. Do not use `git add .`.

Plan complete and saved to `docs/superpowers/plans/2026-04-13-admin-user-governance-remote-first-plan.md`. Ready to execute.
