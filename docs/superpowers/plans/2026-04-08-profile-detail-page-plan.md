# Personal Profile Page Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a dedicated profile-details page and move nickname/avatar editing there while keeping `我的` clean.

**Architecture:** Reuse the existing auth update endpoint and session-refresh path, expand it from avatar-only to profile-save, and route editing through a dedicated page instead of the tab shell.

**Tech Stack:** ArkTS, HarmonyOS UI, existing auth remote client/service, Node/Express backend reference code.

---

## Chunk 1: Profile Save Contract

### Task 1: Expand profile update payload and tests

**Files:**
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] Add failing tests for nickname + avatar profile save payload and session refresh.
- [ ] Expand frontend contracts to support profile save.
- [ ] Re-run focused tests.

## Chunk 2: Auth Save Logic

### Task 2: Implement profile save in auth service

**Files:**
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`

- [ ] Implement one auth-service save path for nickname/avatar together.
- [ ] Keep session persistence behavior intact.
- [ ] Re-run focused tests.

## Chunk 3: UI Flow

### Task 3: Move editing into dedicated profile page

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`

- [ ] Remove inline avatar editor from `我的`.
- [ ] Make the summary card open the profile page.
- [ ] Rebuild `ProfilePage.ets` into a dedicated details editor.
- [ ] Run ArkTS compile.

## Chunk 4: Backend Reference

### Task 4: Expand backend reference endpoint

**Files:**
- Modify: `backend_code/auth.controller.js`
- Modify: `backend_code/auth.routes.js`

- [ ] Update `/api/auth/me` reference behavior to support nickname + avatar.
- [ ] Run `node -c` syntax checks for touched backend files.
