# Verification-First Register Flow Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the temporary direct registration flow with a formal verification-first registration flow that validates phone ownership before account creation.

**Architecture:** Split registration into two frontend pages and three backend capabilities: send registration code, verify registration code, and complete registration with a one-time ticket. Keep development-mode verification visible on the client for now, but isolate that behavior so it can later move to backend console output without rewriting the flow.

**Tech Stack:** HarmonyOS ArkTS, ArkUI routing, existing auth service/client/session stack, Node.js backend reference code in `backend_code`, MySQL-backed cloud service

---

## Chunk 1: Backend Verification Contract

### Task 1: Add development-mode registration code endpoints and ticket-based completion contract

**Files:**
- Modify: `backend_code/auth.controller.js`
- Modify: `backend_code/auth.routes.js` or the backend auth route file that maps `/api/auth/*`
- Create or Modify: backend-side temporary verification storage utility if needed under `backend_code`
- Reference: `backend_code/云服务器后端代码.md`

- [ ] **Step 1: Review the current auth register controller and route mapping**

Confirm the current live-compatible backend shape:
- `POST /api/auth/login/password`
- `POST /api/auth/register`

Document where the auth route file actually lives in the reference code before editing.

- [ ] **Step 2: Add send-register-code controller behavior**

Implement a controller for:
- `POST /api/auth/register/code`

Behavior:
- validate phone format
- reject already registered phone numbers
- generate a 6-digit code
- persist phone/code/purpose/expiresAt/consumed in a development-safe storage location
- return success
- include the code in the response in development mode

- [ ] **Step 3: Add verify-register-code controller behavior**

Implement a controller for:
- `POST /api/auth/register/code/verify`

Behavior:
- validate phone and code shape
- verify phone/code match
- reject expired or consumed code
- mint a short-lived `registerTicket`
- mark the code as consumed
- return `{ phone, registerTicket }`

- [ ] **Step 4: Refactor register controller to require a ticket**

Change `POST /api/auth/register` so it expects:
- `phone`
- `registerTicket`
- `nickname`
- `password`

Behavior:
- validate ticket ownership and expiry
- validate nickname/password
- reject duplicate phone numbers
- create user
- return token and user as before

- [ ] **Step 5: Expose the new auth routes**

Update the auth route file to include:
- `POST /api/auth/register/code`
- `POST /api/auth/register/code/verify`
- `POST /api/auth/register`

- [ ] **Step 6: Verify backend syntax**

Run syntax verification on the edited backend files in the local reference code:
- `node -c backend_code/auth.controller.js`
- `node -c <auth route file>`

Expected:
- no output

## Chunk 2: Frontend Auth Contracts

### Task 2: Replace direct-register contracts with verification-first register contracts

**Files:**
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/types/auth-flow.ets`

- [ ] **Step 1: Remove the temporary direct-register payload from the primary contract**

Replace the direct-register-first contract with new types for:
- send register code payload/response
- verify register code payload/response
- complete register payload using `registerTicket`

- [ ] **Step 2: Extend remote auth client contract**

Add methods for:
- `sendRegisterCode(phone)`
- `verifyRegisterCode(phone, code)`
- `registerWithTicket(phone, registerTicket, nickname, password)`

- [ ] **Step 3: Extend auth service contract**

Add formal methods matching the new flow:
- `sendRegisterCode`
- `verifyRegisterCode`
- `completeRegister`

- [ ] **Step 4: Update auth-flow page params**

Reshape route params so step two receives:
- verified phone
- registerTicket
- development debug code if present

## Chunk 3: Frontend Remote Client and Auth Service

### Task 3: Implement the new remote registration flow

**Files:**
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`

- [ ] **Step 1: Implement send-register-code request**

Add the real request to:
- `POST /api/auth/register/code`

Return the backend message and development-mode code if present.

- [ ] **Step 2: Implement verify-register-code request**

Add the real request to:
- `POST /api/auth/register/code/verify`

Return the backend message plus the `registerTicket`.

- [ ] **Step 3: Implement ticket-based registration request**

Add the real request to:
- `POST /api/auth/register`

Payload:
- `phone`
- `registerTicket`
- `nickname`
- `password`

- [ ] **Step 4: Update auth service validation**

In `auth.service.impl.ets`:
- keep local validation focused and simple
- phone/code validation in step one
- nickname/password validation in step two
- create a normal auth session from the successful register response

- [ ] **Step 5: Remove direct-register-first behavior from the main service path**

Do not keep the direct registration method as the primary path. If it remains temporarily for compatibility, it must no longer be used from the primary UI flow.

## Chunk 4: New Registration Pages

### Task 4: Build the two-step formal registration UI

**Files:**
- Create: `entry/src/main/ets/pages/Auth/RegisterVerifyPage.ets`
- Create: `entry/src/main/ets/pages/Auth/RegisterProfilePage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: Build step-one phone verification page**

UI structure:
- phone input row
- code input and `获取验证码` button on one row, using a 2/3 and 1/3 width split
- `下一步` button
- development-mode debug code display area

- [ ] **Step 2: Implement step-one behavior**

Behavior:
- send code
- display debug code when returned
- verify code on `下一步`
- only navigate to step two after verification succeeds

- [ ] **Step 3: Build step-two account setup page**

UI structure:
- nickname input
- password input
- confirm password input
- `注册并登录`

- [ ] **Step 4: Implement step-two behavior**

Behavior:
- validate nickname/password locally
- submit `phone + registerTicket + nickname + password`
- show success feedback
- route to `pages/Index`

- [ ] **Step 5: Register both pages in `main_pages.json`**

Add:
- `pages/Auth/RegisterVerifyPage`
- `pages/Auth/RegisterProfilePage`

## Chunk 5: Switch Main Routing to the New Flow

### Task 5: Make the new pages the only primary registration path

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/PhoneLoginStep1Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/DirectRegisterPage.ets` or remove from main routing usage

- [ ] **Step 1: Update login landing page**

Point `手机号注册` to `RegisterVerifyPage`.

- [ ] **Step 2: Update password-login page**

Point `去注册` to `RegisterVerifyPage`.

- [ ] **Step 3: Update phone-code-login page**

Point its register entry to `RegisterVerifyPage`.

- [ ] **Step 4: Remove direct-register page from primary flow**

It may remain in code temporarily, but no main user entry should route to it.

- [ ] **Step 5: Align page copy**

Make the login-area wording consistent with reality:
- password login works
- registration is verification-first
- development mode may surface the debug code

## Chunk 6: Verification and Cloud Sync Checklist

### Task 6: Verify the formal registration path locally and prepare cloud rollout

**Files:**
- Reference: `docs/superpowers/specs/2026-03-29-verification-first-register-design.md`
- Reference: `backend_code/云服务器后端代码.md`

- [ ] **Step 1: Compile the frontend in DevEco**

Expected:
- no new ArkTS compile errors from the auth changes

- [ ] **Step 2: Verify runtime registration path**

Manual checks:
- open login page
- tap register
- enter phone
- request code
- see development-mode debug code
- enter code and tap next
- enter nickname/password
- submit registration
- confirm auto-login and landing on `Index`

- [ ] **Step 3: Verify invalid-code behavior**

Manual checks:
- request code
- enter wrong code
- confirm step two is blocked

- [ ] **Step 4: Verify session persistence**

Manual checks:
- register successfully
- kill the app
- reopen
- confirm the session is still restored

- [ ] **Step 5: Prepare cloud backend sync commands**

After local reference code is stable, produce an exact cloud-sync command set like previous backend rollouts, covering:
- auth controller file upload
- auth route file upload
- syntax verification
- PM2 restart
- curl-based endpoint verification

This step should be done only after frontend and local reference behavior are stable.

Plan complete and saved to `docs/superpowers/plans/2026-03-29-verification-first-register-plan.md`. Ready to execute?
