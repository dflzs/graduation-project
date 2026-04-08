# Direct Register Flow Design

**Date:** 2026-03-28

**Goal:** Replace the current placeholder three-step SMS registration flow with a production-aligned one-page direct registration flow that matches the live backend contract and automatically signs the user in after success.

## Problem Summary

The current registration UX is not actually connected to the real backend flow.

- The frontend still routes users through:
  - `RegisterStep1Page`
  - `RegisterStep2Page`
  - `RegisterStep3Page`
- That flow assumes:
  - send registration code
  - verify registration code
  - register by phone + code + password
- But the real backend currently supports a simpler and already-working contract:
  - `POST /api/auth/register`
  - payload: `phone`, `password`, `nickname`

As a result, the current registration path tells users the feature is not available even though the backend can already create accounts.

## Approved Direction

Use a single-page direct registration flow as the formal product path.

The user enters:

- phone number
- nickname
- password
- confirm password

The app validates locally, then calls the live backend registration API directly. On success, the returned token and user object should create a normal logged-in session, and the user should land on the main app shell immediately.

This is the cleanest approach because it matches the current backend truth rather than forcing a fake SMS flow on top of a backend that does not provide it.

## UX Flow

### Entry

From `LoginPage`, tapping `手机号注册` should go directly to a new formal register page instead of the existing three-step SMS path.

### Register Page

The page should contain:

- phone number input
- nickname input
- password input
- confirm password input
- primary action button: `完成注册`
- secondary entry: `已有账号，去登录`

### Validation

Before submitting:

- phone must be a valid mainland China mobile number
- nickname length must meet backend expectations
- password length must meet backend expectations
- confirm password must exactly match password

Validation should fail early on the page with normal toast feedback.

### Success

On successful backend registration:

- create and persist normal auth session
- treat user as logged in
- route directly to `pages/Index`

This should feel the same as a successful password login rather than a separate onboarding branch.

## Contract Alignment

The frontend should stop relying on unsupported registration methods in `HttpRemoteAuthClient`.

Instead, the remote auth client should support:

- `registerByPassword(phone, nickname, password)` or equivalent direct register method

The existing SMS registration methods can remain temporarily in the interface only if needed for compatibility, but they should no longer be the active UX path.

## File Responsibilities

- `LoginPage.ets`
  - update register entry routing
- `DirectRegisterPage.ets` or equivalent new page
  - formal registration UI
- `auth-remote.client.ets`
  - add direct backend register request
- `auth-remote.ets`
  - add request payload type for direct registration
- `auth.service.impl.ets`
  - expose direct registration method that creates normal session from backend response
- `service-contracts.ets`
  - update auth service contract to include direct register path
- `main_pages.json`
  - register the new page

The old three-step SMS pages can stay in the codebase temporarily if we want to avoid broad deletion in the same change, but they should no longer be reachable from the main login flow.

## Product Rationale

This change is more professional than preserving the current three-step shell because:

- it removes a fake or half-connected registration experience
- it aligns frontend behavior with real backend capability
- it reduces user friction
- it avoids maintaining duplicate registration logic

For this project stage, direct registration is the right tradeoff. If SMS registration is required later, it can be added as a separate enhancement once the backend actually supports it.

## Success Criteria

This work is successful when:

- tapping `手机号注册` opens a real usable registration page
- a new account can be created through the app without server-mismatch errors
- registration success logs the user in immediately
- the app lands on the home shell after registration
- the old “未开通” experience disappears from the main registration path
