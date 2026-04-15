# Announcement Remote-First Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move announcement list, publish, and delete onto backend APIs first while preserving the current local announcement cache as a fallback.

**Architecture:** Keep `AnnouncementServiceImpl` as the single app-facing boundary, add a small remote client for `/api/announcements`, and let pages await service calls instead of reading local repository synchronously. Remote success should hydrate the local repository and still publish the existing `announcements:changed` sync event.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing local announcement repository, `AuthStateService`, backend announcement/admin APIs, Hypium, hvigor.

---

## Chunk 1: Remote Contracts And Client

### Task 1: Add remote announcement DTOs and client

**Files:**
- Create: `entry/src/main/ets/types/announcement-remote.ets`
- Create: `entry/src/main/ets/services/announcement-remote.client.ets`
- Reference: `backend_code/announcement.controller.js`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] Write a failing test for remote announcement list/publish/delete contract shape.
- [ ] Run the unit test command and confirm the test fails because the remote client/contracts do not exist yet.
- [ ] Implement the minimal DTOs and remote client using the existing auth/base-url pattern.
- [ ] Re-run the unit test command and confirm the remote contract tests pass.

## Chunk 2: Service Remote-First

### Task 2: Convert announcement service to async remote-first

**Files:**
- Modify: `entry/src/main/ets/services/announcement.service.impl.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets` if needed
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] Write failing tests for remote-first list hydration, remote publish hydration, and remote delete fallback behavior.
- [ ] Run the unit test command and confirm the new tests fail for the expected reason.
- [ ] Implement async remote-first service behavior with local fallback and existing admin guards.
- [ ] Re-run the unit test command and confirm the service tests pass.

## Chunk 3: Page Async Wiring

### Task 3: Update announcement pages to await service calls

**Files:**
- Modify: `entry/src/main/ets/pages/Announcement/AnnouncementPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] Update refresh/publish/delete flows to await the async announcement service.
- [ ] Keep `announcements:changed` subscriptions intact.
- [ ] Verify list rendering and admin operations still use the same user-facing copy and sync chain.

## Chunk 4: Verification

### Task 4: Run full verification

**Files:**
- Verify only: `entry/src/test/LocalUnit.test.ets`

- [ ] Run the required LocalUnit test command and confirm `BUILD SUCCESSFUL`.
- [ ] Run the required `assembleHap` command and confirm `BUILD SUCCESSFUL`.
- [ ] If later committing, use explicit `git add` paths only.

Plan complete and saved to `docs/superpowers/plans/2026-04-13-announcement-remote-first-plan.md`. Ready to execute.
