# Client Password Login And Chinese Auth UI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the local HarmonyOS client to the deployed backend for password login and localize the login entry/password-login UI into Chinese.

**Architecture:** Keep the existing auth service boundary, but swap the remote transport and response mapping from the old demo backend to the deployed server. Limit UI changes to the login entry and password-login pages so the first working client-server loop is small and easy to verify.

**Tech Stack:** HarmonyOS ArkTS, existing local auth service layer, deployed Node.js backend at `http://49.232.30.147`

---

## Chunk 1: Remote Auth Contract Alignment

### Task 1: Repoint the auth base URL

**Files:**
- Modify: `entry/src/main/ets/constants/config.ets`
- Test: manual inspection of emitted constant value

- [ ] **Step 1: Write the failing test**

There is no dedicated test harness for these ArkTS constants in the current project, so use a narrow verification target instead: document the expected constant change and verify via file inspection after the edit.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/constants/config.ets`
Expected: `AUTH_API_BASE_URL` still points to the old demo backend

- [ ] **Step 3: Write minimal implementation**

Change only:

```ts
export const AUTH_API_BASE_URL: string = 'http://49.232.30.147';
```

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/constants/config.ets`
Expected: `AUTH_API_BASE_URL` equals `http://49.232.30.147`

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/constants/config.ets
git commit -m "feat: point auth client to deployed backend"
```

### Task 2: Replace old remote auth response types

**Files:**
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Test: manual compile-oriented inspection for type consistency

- [ ] **Step 1: Write the failing test**

Document the mismatch: current types assume XiaomiMall fields like `userinfo`, `tel`, and `username`, which do not exist in the deployed backend response.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/types/auth-remote.ets`
Expected: old `RemoteUserInfo` and `RemotePassResponse` shape still present

- [ ] **Step 3: Write minimal implementation**

Introduce backend-aligned types for:

```ts
export interface RemoteAuthUser {
  id: number;
  phone: string;
  nickname: string;
  avatar: string;
  role: string;
  status: string;
  credit_score: number;
}

export interface RemoteAuthData {
  token: string;
  user: RemoteAuthUser;
}

export interface RemotePassResponse {
  code: number;
  message: string;
  data?: RemoteAuthData;
}
```

Retain the `RemoteAuthClient` interface but plan for unsupported methods to return explicit failures.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/types/auth-remote.ets`
Expected: no dependency on `userinfo`, `tel`, or `username` in the response model

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/types/auth-remote.ets
git commit -m "feat: align auth remote types with deployed backend"
```

### Task 3: Rework the remote auth client for password login

**Files:**
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Test: manual code-path inspection and later app-level verification

- [ ] **Step 1: Write the failing test**

Document the mismatch: `loginByPassword()` currently posts to `/api/doLogin` with the wrong payload shape and old response assumptions.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/services/auth-remote.client.ets`
Expected: password login still targets `/api/doLogin`

- [ ] **Step 3: Write minimal implementation**

Change the password-login call to:

```ts
return this.post('/api/auth/login/password', { phone, password });
```

For unsupported methods (`sendLoginCode`, `validateLoginCode`, `sendRegisterCode`, `validateRegisterCode`, `registerByPhone`), return a resolved failure object with a Chinese message such as:

```ts
{ code: 1, message: '该功能暂未接通服务器，请先使用手机号密码登录。' }
```

Ensure network errors are converted to Chinese messages.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/services/auth-remote.client.ets`
Expected: password login uses `/api/auth/login/password`, unsupported methods fail explicitly in Chinese

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/auth-remote.client.ets
git commit -m "feat: align password auth client with deployed backend"
```

## Chunk 2: Auth Service Session Mapping

### Task 4: Adapt auth service password-login mapping

**Files:**
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Test: inspect mapping logic and verify login flow manually in app

- [ ] **Step 1: Write the failing test**

Document the mismatch: `createSessionFromRemote()` currently expects `response.success` and `response.userinfo?.[0]`, which do not exist in the new backend shape.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/services/auth.service.impl.ets`
Expected: old `userinfo[0]` mapping still present

- [ ] **Step 3: Write minimal implementation**

Update password-login handling so that:

- success is `response.code === 0`
- failure uses `response.message`
- current user comes from `response.data?.user`
- session token uses `response.data?.token`
- backend `credit_score` maps to local `creditScore`

Keep unsupported SMS/register methods returning clean Chinese failure results instead of trying to fake success.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/services/auth.service.impl.ets`
Expected: password-login path no longer depends on `userinfo[0]`

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/auth.service.impl.ets
git commit -m "feat: map backend auth responses into local session"
```

## Chunk 3: Chinese Login UI

### Task 5: Localize the login entry page

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Test: visual inspection in code and runtime

- [ ] **Step 1: Write the failing test**

Document the current issue: `LoginPage.ets` still shows English strings such as `Auth Center` and `Phone Password Login`.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Auth/LoginPage.ets`
Expected: English copy still present

- [ ] **Step 3: Write minimal implementation**

Translate only the visible strings on this page into Chinese while preserving navigation structure.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Auth/LoginPage.ets`
Expected: visible login entry strings are Chinese

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Auth/LoginPage.ets
git commit -m "feat: localize auth entry page to Chinese"
```

### Task 6: Localize the password-login page

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
- Test: visual inspection in code and runtime

- [ ] **Step 1: Write the failing test**

Document the current issue: the page still contains English labels, placeholders, and helper text mentioning `/api/doLogin`.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
Expected: English strings and obsolete helper text still present

- [ ] **Step 3: Write minimal implementation**

Translate the page to Chinese and update the helper text so it references the real server-backed password-login flow rather than `/api/doLogin`.

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
Expected: visible strings are Chinese and helper text is backend-accurate

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Auth/PasswordLoginPage.ets
git commit -m "feat: localize password login page to Chinese"
```

## Chunk 4: Manual Verification

### Task 7: Verify end-to-end password login

**Files:**
- Verify: `entry/src/main/ets/constants/config.ets`
- Verify: `entry/src/main/ets/types/auth-remote.ets`
- Verify: `entry/src/main/ets/services/auth-remote.client.ets`
- Verify: `entry/src/main/ets/services/auth.service.impl.ets`
- Verify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Verify: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`

- [ ] **Step 1: Run static inspection**

Run: inspect all modified files
Expected: no remaining old password-login endpoint or English login-entry strings in the touched pages

- [ ] **Step 2: Run app build or preview verification**

Run the available HarmonyOS build or preview command used by the project.
Expected: app compiles without auth-related type errors

- [ ] **Step 3: Verify runtime login against deployed backend**

Use the existing backend test account:

- phone: `13800138000`
- password: `12345678`

Expected: password login succeeds and enters the app

- [ ] **Step 4: Verify failure copy**

Try an incorrect password.
Expected: user sees understandable Chinese failure text from the backend/client

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/constants/config.ets entry/src/main/ets/types/auth-remote.ets entry/src/main/ets/services/auth-remote.client.ets entry/src/main/ets/services/auth.service.impl.ets entry/src/main/ets/pages/Auth/LoginPage.ets entry/src/main/ets/pages/Auth/PasswordLoginPage.ets
git commit -m "feat: connect client password login to deployed backend"
```
