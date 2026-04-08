# Phone SMS Auth Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the simulated `123456` phone login with the real SMS login/registration API flow described in `phone-sms-login-api.md`, while keeping the project's local business modules intact.

**Architecture:** Add a focused remote auth client, extend the local user model to retain remote identity fields, update `AuthServiceImpl` to orchestrate remote login/register flows, and reshape the login page into user-login, user-register, and admin-login modes. Keep admin authentication local and preserve existing repositories and session usage.

**Tech Stack:** HarmonyOS ArkTS, `@ohos.net.http`, Hypium unit tests, local repositories

---

## Chunk 1: Remote Auth Boundary

### Task 1: Add the remote auth client and response models

**Files:**
- Create: `entry/src/main/ets/types/auth-remote.ets`
- Create: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/constants/config.ets`
- Modify: `entry/src/main/module.json5`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing tests for remote auth response mapping and client injection shape**

```ts
it('auth_service_should_use_remote_login_result_to_build_session', 0, async (done) => {
  // Arrange a fake remote client result, then assert session/user mapping behavior.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because no remote client contract or injected auth path exists

- [ ] **Step 3: Write the minimal implementation**

```ts
export interface RemoteAuthClient {
  sendLoginCode(phone: string): Promise<RemotePassResponse>;
  validateLoginCode(phone: string, code: string): Promise<RemotePassResponse>;
  sendRegisterCode(phone: string): Promise<RemotePassResponse>;
  validateRegisterCode(phone: string, code: string): Promise<RemotePassResponse>;
  registerByPhone(phone: string, code: string, password: string): Promise<RemotePassResponse>;
}
```

Add base URL config, request permission, remote DTOs, and an HTTP-backed client.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the new remote-contract-oriented test

- [ ] **Step 5: Do not commit yet**

Reason: current git root is broader than the project directory and is unsafe for partial commits.

## Chunk 2: Service-Layer Auth Refactor

### Task 2: Refactor `AuthServiceImpl` to use real phone login/register flows

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/user.repo.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests for remote login, register verification, and banned-user guard**

```ts
it('auth_service_should_persist_remote_user_fields_after_phone_login', 0, async (done) => {
  // loginByPhone -> mapped local user contains remoteUserId/remoteSalt
});

it('auth_service_should_register_user_after_code_verification', 0, async (done) => {
  // registerByPhone -> session created from remote register response
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because service methods are still synchronous and tied to `SIMULATED_SMS_CODE`

- [ ] **Step 3: Write the minimal implementation**

```ts
async loginByPhone(phone: string, code: string): Promise<OperationResult<AuthSession>> {
  const response = await this.remoteClient.validateLoginCode(phone, code);
  return this.buildSessionFromRemote(phone, response, false);
}
```

Extend `User`, support async auth methods, map remote fields onto local users, and keep admin login local.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the new auth service cases and existing admin cases

- [ ] **Step 5: Do not commit yet**

Reason: git scope is unsafe until repository boundaries are corrected.

## Chunk 3: Login/Register UI Flow

### Task 3: Replace the simulated login page with real SMS login/register states

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/main/ets/constants/config.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test for user phone auth flow entry points**

```ts
it('auth_service_should_send_login_and_register_codes_through_remote_client', 0, async (done) => {
  // sendLoginCode + sendRegisterCode should call the fake client, not local constants
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because there are no send-code methods on the service/page path

- [ ] **Step 3: Write the minimal implementation**

```ts
enum AuthMode {
  USER_LOGIN,
  USER_REGISTER,
  ADMIN_LOGIN
}
```

Add user login/register modes, send-code actions, password confirmation for registration, loading state, and async button handlers. Remove the fixed-code hint.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for service entry-point tests and project still compiles against the updated page/service contracts

- [ ] **Step 5: Do not commit yet**

Reason: git scope is unsafe until repository boundaries are corrected.

## Chunk 4: Regression Cleanup

### Task 4: Update demo tests and remove simulated-user assumptions

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/constants/config.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`

- [ ] **Step 1: Replace tests that depend on hardcoded `123456` login**

```ts
it('order_service_should_complete_demo_trade_flow', 0, async (done) => {
  // use a deterministic fake remote auth client to obtain seller and buyer sessions
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL until all old simulated auth assumptions are removed

- [ ] **Step 3: Write the minimal implementation**

```ts
// keep ADMIN_LOGIN_CODE only; remove SIMULATED_SMS_CODE from normal user auth flow
```

Update regression tests to use injected fake remote responses and remove ordinary-user dependence on fixed local codes.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the full local unit suite

- [ ] **Step 5: Do not commit yet**

Reason: git scope is unsafe until repository boundaries are corrected.

Plan complete and saved to `docs/superpowers/plans/2026-03-14-phone-sms-auth-plan.md`. Ready to execute.
