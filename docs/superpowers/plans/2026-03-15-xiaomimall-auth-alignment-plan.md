# XiaoMiMall Auth Alignment Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make this project's login and registration strategy fully match `D:/codespace/XiaoMiMall`, including step-based pages, test-code reception, and local login-state persistence.

**Architecture:** Keep the existing remote auth client and local domain model, but move login/register flow orchestration into multiple pages that mirror the reference project. Extend the auth boundary so send-code responses surface the returned `code`, then map successful remote responses into the current project's local session and user model.

**Tech Stack:** HarmonyOS ArkTS, `@ohos.net.http`, ArkUI router, Hypium unit tests, local repositories

---

## Chunk 1: Align Remote Auth Response Shape

### Task 1: Surface returned verification codes from send-code endpoints

**Files:**
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing tests**

```ts
it('send_login_code_should_return_debug_code_when_remote_api_provides_it', 0, async () => {
  // fake client returns { success: true, message: '发送成功', code: '123456' }
  // assert service result exposes the code for the page flow
});

it('send_register_code_should_return_debug_code_when_remote_api_provides_it', 0, async () => {
  // same for register send-code flow
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because current send-code service methods only return `OperationResult<void>`

- [ ] **Step 3: Write minimal implementation**

```ts
export interface SendCodeResult {
  message: string;
  code?: string;
}
```

Update the remote response model and service contract so send-code calls return the optional test code.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the new send-code result tests

- [ ] **Step 5: Do not commit**

Reason: current git root is broader than the project and unsafe for partial commits.

## Chunk 2: Persist Login State Like the Reference Project

### Task 2: Add a lightweight auth state store compatible with current business code

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/user.repo.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing tests**

```ts
it('login_by_phone_should_persist_session_from_remote_userinfo', 0, async () => {
  // fake remote login succeeds
  // assert restoreSession returns mapped current user
});

it('register_by_phone_should_persist_session_from_remote_userinfo', 0, async () => {
  // fake remote register succeeds
  // assert restoreSession returns mapped current user
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL if session persistence is not aligned with the new flow/state contract

- [ ] **Step 3: Write minimal implementation**

Keep current `AuthSession`, but ensure successful login/register stores the mapped user/session in a way that mirrors `userinfo + isLogin` semantics.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the session-persistence tests

- [ ] **Step 5: Do not commit**

Reason: repository boundaries remain unsafe.

## Chunk 3: Replace Single-Page Auth UI with Reference-Style Step Pages

### Task 3: Add login step pages

**Files:**
- Create: `entry/src/main/ets/pages/Auth/PhoneLoginStep1Page.ets`
- Create: `entry/src/main/ets/pages/Auth/PhoneLoginStep2Page.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`

- [ ] **Step 1: Add failing route usage expectation**

Use a compile-time target: the project should route to the new step-1 page instead of the old all-in-one auth page.

- [ ] **Step 2: Run build to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: FAIL until the new pages and routes exist

- [ ] **Step 3: Write minimal implementation**

`PhoneLoginStep1Page.ets`
- collect phone
- call `sendLoginCode`
- display/log returned test code
- navigate to step 2 with phone and code context

`PhoneLoginStep2Page.ets`
- show masked phone
- support resend countdown
- collect verification code
- call `loginByPhone`
- on success go back to main flow

- [ ] **Step 4: Run build to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: PASS for route and page compilation

- [ ] **Step 5: Do not commit**

Reason: repository boundaries remain unsafe.

### Task 4: Add register step pages

**Files:**
- Create: `entry/src/main/ets/pages/Auth/RegisterStep1Page.ets`
- Create: `entry/src/main/ets/pages/Auth/RegisterStep2Page.ets`
- Create: `entry/src/main/ets/pages/Auth/RegisterStep3Page.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: Add failing route usage expectation**

Use a compile-time target: register entry should route through the new three-step pages.

- [ ] **Step 2: Run build to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: FAIL until the register pages and route references exist

- [ ] **Step 3: Write minimal implementation**

`RegisterStep1Page.ets`
- collect phone
- call `sendRegisterCode`
- display/log returned test code
- navigate to step 2

`RegisterStep2Page.ets`
- collect code
- resend with countdown
- call `verifyRegisterCode`
- on success navigate to step 3 with phone/code

`RegisterStep3Page.ets`
- collect password and confirmation
- call `registerByPhone`
- on success return to main flow

- [ ] **Step 4: Run build to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap`
Expected: PASS for route and page compilation

- [ ] **Step 5: Do not commit**

Reason: repository boundaries remain unsafe.

## Chunk 4: Remove Strategy Mismatches from Existing Auth Entry

### Task 5: Retire the current single-page normal-user auth flow and keep admin login separated

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `entry/src/main/ets/pages/Order/CreateOrderPage.ets`

- [ ] **Step 1: Write the failing regression tests**

```ts
it('auth_entry_should_no_longer_depend_on_single_page_sms_form_flow', 0, async () => {
  // compile-oriented regression: old flow assumptions are removed from service tests
});
```

- [ ] **Step 2: Run test/build to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL until old assumptions are removed

- [ ] **Step 3: Write minimal implementation**

Keep `LoginPage.ets` only for admin login or convert it into an auth hub page with explicit buttons to:
- phone login
- phone register
- admin login

Update all guarded pages to route to the new auth entry.

- [ ] **Step 4: Run test/build to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS with no old single-page user auth assumptions left

- [ ] **Step 5: Do not commit**

Reason: repository boundaries remain unsafe.

## Chunk 5: Regression Coverage

### Task 6: Rework auth-related tests around the reference strategy

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Replace old tests that assume fixed-code or single-step login**

Add deterministic fake remote responses for:
- send login code
- validate login code
- send register code
- validate register code
- register

- [ ] **Step 2: Run tests to verify failures appear in the right places**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL until all old assumptions are updated

- [ ] **Step 3: Write minimal implementation changes in tests**

Use a fake remote client that matches the new multi-step strategy and returned test-code contract.

- [ ] **Step 4: Run the full target test suite**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the auth suite and existing business regression tests

- [ ] **Step 5: Do not commit**

Reason: repository boundaries remain unsafe.
