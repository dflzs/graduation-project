# Direct Register Flow Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder SMS-style registration path with a one-page direct registration flow aligned to the live backend.

**Architecture:** Keep the existing auth service and remote client layering, but add a direct register contract that matches `/api/auth/register`. Route the login page to a new formal register page, create a normal auth session from the backend response, and leave the old SMS registration pages unreachable from the main flow.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing auth service/repository/session stack, current backend `POST /api/auth/register`

---

## Chunk 1: Direct Register Contract

### Task 1: Add direct registration request types and service contract

**Files:**
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`

- [ ] **Step 1: Add a direct registration payload type**

Add a dedicated payload class with:
- `phone`
- `nickname`
- `password`

- [ ] **Step 2: Extend the remote auth client contract**

Add a direct registration method to `RemoteAuthClient`, separate from the current SMS-style methods.

- [ ] **Step 3: Extend the auth service contract**

Add a direct registration method to `AuthService` so the page layer no longer depends on the old phone-code registration API.

## Chunk 2: Remote Auth Client and Auth Service

### Task 2: Implement direct backend register call

**Files:**
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`

- [ ] **Step 1: Implement remote register request**

Add a real POST request to `/api/auth/register` using the new payload type.

- [ ] **Step 2: Add auth-service direct register method**

Create a direct register method that:
- validates phone
- validates nickname
- validates password
- calls the remote client
- creates and persists a normal session from returned token and user

- [ ] **Step 3: Keep old SMS helpers isolated**

Do not delete the older SMS-style methods yet; just stop making the main registration flow depend on them.

## Chunk 3: Register Page

### Task 3: Add the formal one-page register screen

**Files:**
- Create: `entry/src/main/ets/pages/Auth/DirectRegisterPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: Create a single-page registration form**

Include:
- phone input
- nickname input
- password input
- confirm password input
- submit button
- back-to-login action

- [ ] **Step 2: Add local validation**

Check:
- phone format
- nickname minimum length
- password minimum length
- password confirmation equality

- [ ] **Step 3: Wire submit to auth service**

On success:
- show success feedback
- route to `pages/Index`

- [ ] **Step 4: Register the page in `main_pages.json`**

Make the new page available to the router.

## Chunk 4: Route the App to the New Flow

### Task 4: Switch login page registration entry to the formal register page

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`

- [ ] **Step 1: Update the register button target**

Change `手机号注册` to open the new direct register page.

- [ ] **Step 2: Update login-page explanatory copy**

Make the wording match the new real behavior:
- password login works
- direct registration works
- SMS login/register are not the active path

## Chunk 5: Cleanup and Verification

### Task 5: Verify the new primary registration path

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep1Page.ets` (only if needed for messaging)
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep2Page.ets` (only if needed for messaging)
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep3Page.ets` (only if needed for messaging)

- [ ] **Step 1: Ensure old SMS pages are no longer reachable from the main flow**

No deletion required in this task unless needed to fix routing confusion.

- [ ] **Step 2: Verify compile path**

Build in DevEco and confirm there are no new ArkTS errors from the auth changes.

- [ ] **Step 3: Verify runtime path**

Test:
- open login page
- tap register
- complete direct registration
- confirm user is auto-logged in
- confirm app lands on `Index`

- [ ] **Step 4: Verify persistence**

Kill the app and reopen it to confirm the newly registered user session is still restored correctly.

Plan complete and saved to `docs/superpowers/plans/2026-03-28-direct-register-flow-plan.md`. Ready to execute?
