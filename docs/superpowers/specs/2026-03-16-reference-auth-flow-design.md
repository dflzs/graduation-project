# Reference Auth Flow Design

**Date:** 2026-03-16

**Goal**

Make this project use the same authentication flow as `D:/codespace/XiaoMiMall`, including:
- phone verification-code login
- phone/password login
- phone verification-code registration

The goal is to match the reference project's interface usage and local login-state strategy, while keeping the rest of this project's marketplace features usable.

## Scope

In scope:
- replace the current combined auth page with reference-style multi-step pages
- support `/api/sendLoginCode`, `/api/validateLoginCode`, `/api/doLogin`, `/api/sendCode`, `/api/validateCode`, `/api/register`
- store login state using `userinfo` and `isLogin`
- map remote `userinfo` into the existing local `User` model so downstream product/order/admin pages continue to work

Out of scope:
- redesigning non-auth pages
- replacing the marketplace domain model outside auth compatibility changes
- introducing a new backend or token-based auth system

## Reference Behavior

The reference project treats auth as three independent flows:

1. Verification-code login
   - enter phone
   - call `/api/sendLoginCode`
   - enter code
   - call `/api/validateLoginCode`
   - persist `userinfo`
   - set `isLogin = true`

2. Password login
   - enter phone and password
   - call `/api/doLogin`
   - persist `userinfo`
   - set `isLogin = true`

3. Verification-code registration
   - enter phone
   - call `/api/sendCode`
   - enter code
   - call `/api/validateCode`
   - enter password
   - call `/api/register`
   - persist `userinfo`
   - set `isLogin = true`

The verification-code send endpoints may return a `code` field for testing. The client should accept and surface that result as part of the flow instead of assuming real SMS delivery.

## Target Architecture

The auth subsystem will be split into three layers:

1. Remote auth protocol layer
   - request/response DTOs shaped like the reference project
   - HTTP client for the six remote auth endpoints

2. Local auth state layer
   - persist remote `userinfo` and `isLogin`
   - restore current login state on app startup and page entry
   - clear local state on logout

3. Compatibility auth service layer
   - convert remote `userinfo` into this project's local `User`
   - keep the existing `appContext.auth` entry point for the rest of the app
   - expose methods for the three reference flows

This keeps the external behavior aligned with `XiaoMiMall` without forcing unrelated pages to read raw remote payloads.

## Page Structure

The current single `LoginPage` is not the primary flow anymore. Auth pages will follow the reference split:

- `pages/Auth/LoginPage`
  - acts as flow chooser page
  - links to phone-code login, password login, and registration

- `pages/Auth/PhoneLoginStep1Page`
  - phone input
  - send login code
  - navigate to step 2 with the phone number

- `pages/Auth/PhoneLoginStep2Page`
  - code input
  - resend code
  - validate code and complete login

- `pages/Auth/PasswordLoginPage`
  - phone + password input
  - call `/api/doLogin`

- `pages/Auth/RegisterStep1Page`
  - phone input
  - send registration code

- `pages/Auth/RegisterStep2Page`
  - code input
  - resend code
  - validate code and navigate to password setup

- `pages/Auth/RegisterStep3Page`
  - password + confirm password
  - complete registration

## Data Model

The remote response model will match the reference project:

```ts
interface ReferenceAuthResponse {
  success: boolean
  message: string
  code?: string
  userinfo?: ReferenceUserInfo[]
}
```

`ReferenceUserInfo` carries `_id`, `username`, `tel`, `salt`, and mall account fields.

Local state will preserve:
- `isLogin`
- `userinfo`

Compatibility mapping will also ensure the local repository keeps a `User` record with:
- `phone` from `tel`
- `nickname` from `username`
- `remoteUserId` from `_id`
- `remoteSalt` from `salt`
- `passwordConfigured` when password login or registration is used

## Navigation and Session Strategy

Navigation will match the reference step order. Successful login or registration returns to the app root.

Session semantics change in an important way:
- remote `userinfo` plus `isLogin` become the source of truth for auth state
- the local `AuthSession` returned by `appContext.auth` becomes a compatibility wrapper around that state
- logout clears both persisted remote auth state and the in-memory compatibility session

This makes auth behavior consistent with the reference project while keeping downstream code stable.

## Error Handling

All auth pages will:
- show the backend `message` directly on failed auth calls
- validate phone format before requests
- validate verification-code length before verification
- validate password confirmation before registration
- prevent duplicate submissions while a request is in flight

For code-send endpoints:
- if `code` is present in the response, store it in the result object and surface it for testing use
- do not block the flow on the assumption of real SMS delivery

## Testing Strategy

Tests will cover:
- send-login-code returns and exposes `code`
- phone verification-code login persists local state and creates compatibility session
- password login uses `/api/doLogin` and persists local state
- registration step verification succeeds before registration completes
- registration persists local state and creates compatibility session
- logout clears persisted auth state

UI flow tests are not required if the ArkTS test harness makes them impractical, but service and state behavior must be covered.
