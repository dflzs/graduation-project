# Reference Auth Flow Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current auth flow with the same verification-code login, password login, and registration flow used by `D:/codespace/XiaoMiMall`.

**Architecture:** Introduce reference-style auth DTOs and persisted login-state storage, then split auth UI into the same step-based pages as the reference project. Keep the rest of the marketplace working by mapping remote `userinfo` into the existing local `User` and `AuthSession` compatibility layer.

**Tech Stack:** ArkTS, HarmonyOS Stage model, `@ohos.net.http`, existing repository/services layer, Hypium local unit tests

---

## Chunk 1: Auth Models and Local State

### Task 1: Add failing tests for reference-style auth state behavior

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Reference: `docs/superpowers/specs/2026-03-16-reference-auth-flow-design.md`

- [ ] **Step 1: Write failing tests for password login and persisted auth state**

Add tests that expect:
- password login to call `/api/doLogin`
- code send methods to surface returned `code`
- logout to clear persisted auth state

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because password-login APIs and persisted auth-state helpers do not exist yet

- [ ] **Step 3: Add reference-style auth DTOs and local auth-state storage**

Create or modify:
- `entry/src/main/ets/types/auth-reference.ets`
- `entry/src/main/ets/services/auth-state.service.ets`
- `entry/src/main/ets/constants/config.ets`

Include:
- `ReferenceAuthResponse`
- `ReferenceUserInfo`
- request payload models for all six endpoints
- persisted `userinfo` and `isLogin` storage helpers

- [ ] **Step 4: Run test to verify partial progress**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: Some tests still fail because auth service and UI are not updated yet

### Task 2: Update auth service to match the reference flows

**Files:**
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`

- [ ] **Step 1: Extend the failing tests for full service behavior**

Add tests that expect:
- `sendLoginCode` and `sendRegisterCode` to return the server `code`
- `loginByPassword` to return a valid compatibility session
- `restoreSession` to rebuild from persisted `userinfo/isLogin`

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because `loginByPassword` and persisted restore behavior do not exist

- [ ] **Step 3: Implement minimal auth-service support**

Update service APIs to provide:
- `loginByPassword(phone, password)`
- `sendLoginCode/sendRegisterCode` returning `code`
- persisted restore/logout behavior
- compatibility mapping from `userinfo[0]` to local `User`

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for auth-state/service tests

## Chunk 2: Reference-Style Auth Pages

### Task 3: Add flow chooser and password login page

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Create: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`

- [ ] **Step 1: Define expected navigation behavior**

Write or extend tests if feasible; otherwise document manual verification targets in the test file comments.

- [ ] **Step 2: Implement the chooser and password login page**

`LoginPage.ets` should become a simple auth entry page linking to:
- password login
- phone code login
- registration

`PasswordLoginPage.ets` should mirror reference behavior:
- phone input
- password input
- agreement toggle if retained
- call `/api/doLogin` through `appContext.auth.loginByPassword`

- [ ] **Step 3: Run targeted build verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: PASS if page routing and imports are correct

### Task 4: Add two-step phone-code login pages

**Files:**
- Create: `entry/src/main/ets/pages/Auth/PhoneLoginStep1Page.ets`
- Create: `entry/src/main/ets/pages/Auth/PhoneLoginStep2Page.ets`

- [ ] **Step 1: Implement step 1**

Behavior:
- phone input
- call `sendLoginCode`
- navigate to step 2 carrying phone

- [ ] **Step 2: Implement step 2**

Behavior:
- code input
- resend support
- call `loginByPhone`
- complete login and return to app root

- [ ] **Step 3: Run targeted build verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: PASS

### Task 5: Add three-step registration pages

**Files:**
- Create: `entry/src/main/ets/pages/Auth/RegisterStep1Page.ets`
- Create: `entry/src/main/ets/pages/Auth/RegisterStep2Page.ets`
- Create: `entry/src/main/ets/pages/Auth/RegisterStep3Page.ets`

- [ ] **Step 1: Implement registration step 1**

Behavior:
- phone input
- call `sendRegisterCode`
- navigate to step 2

- [ ] **Step 2: Implement registration step 2**

Behavior:
- code input
- resend support
- call `verifyRegisterCode`
- navigate to step 3 with phone and code

- [ ] **Step 3: Implement registration step 3**

Behavior:
- password and confirm password
- call `registerByPhone`
- complete login and return to app root

- [ ] **Step 4: Run targeted build verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: PASS

## Chunk 3: Integration and Verification

### Task 6: Update app integration points and remove obsolete admin auth path from primary flow

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: any auth-entry call sites that assume the old combined page behavior

- [ ] **Step 1: Ensure all login entry points route into the new chooser**

- [ ] **Step 2: Ensure logout clears persisted auth state**

- [ ] **Step 3: Run full test verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS

- [ ] **Step 4: Run full build verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: PASS

- [ ] **Step 5: Manual verification checklist**

Verify:
- phone code login flow completes end-to-end
- password login flow completes end-to-end
- registration flow completes end-to-end
- auth state survives page re-entry
- logout clears auth state
