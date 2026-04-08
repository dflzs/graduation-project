# Verification-First Register Flow Design

**Date:** 2026-03-29  
**Status:** Approved

## Context

The current direct registration path is technically usable, but it does not verify phone ownership before creating an account. That is acceptable as a short-lived unblock, but it is not acceptable as the final product flow for this graduation project.

The project should now treat registration as a formal product feature:

- phone ownership is verified before account creation
- the main registration path no longer depends on the older placeholder SMS pages
- the implementation remains compatible with a future real SMS provider

This design replaces the direct-registration-first approach as the primary registration direction.

## Goals

- Require phone verification before a user can finish registration
- Keep the registration flow product-like and easy to understand
- Support efficient development-time debugging without blocking on a real SMS vendor
- Leave a clean extension point for future real SMS integration

## Non-Goals

- Real SMS provider integration in this phase
- Full anti-abuse/rate-limiting platform hardening
- Refactoring password login or phone-code login beyond what is needed for registration

## Recommended Approach

Use a two-step registration flow with verification completed in step one.

### Step 1: Phone Verification

The first page is responsible only for proving phone ownership.

Layout:

- first row: phone input
- second row: verification code input on the left and `获取验证码` button on the right
- third row: `下一步`

Behavior:

- the user enters a phone number
- the user taps `获取验证码`
- the backend generates a registration code and stores it with expiration metadata
- in development mode, the backend also returns the code and the page displays it as a debug helper
- the user enters the code and taps `下一步`
- the backend verifies the phone and code pair
- if valid, the backend returns a one-time registration ticket
- only then does the app allow navigation to step two

This keeps the flow product-like: phone ownership is resolved before the user spends time filling the rest of the form.

### Step 2: Account Setup

The second page is responsible only for account completion.

Fields:

- nickname
- password
- confirm password

Behavior:

- the page receives the verified phone number and the one-time registration ticket
- the user fills in nickname and password
- the app validates nickname length, password length, and password confirmation locally
- the app submits the ticket, nickname, and password to the backend
- on success, the backend creates the user, returns token and user info, and the app auto-logs in
- the app navigates to `pages/Index`

## Backend Design

The backend should support three separate capabilities instead of a single direct register call.

### 1. Send Register Code

Suggested endpoint:

`POST /api/auth/register/code`

Input:

- `phone`

Responsibilities:

- validate phone format
- reject already-registered phone numbers
- generate a six-digit code
- store code, phone, purpose, expiration time, and consume status
- return a success message
- in development mode, also return the generated code for debugging

### 2. Verify Register Code

Suggested endpoint:

`POST /api/auth/register/code/verify`

Input:

- `phone`
- `code`

Responsibilities:

- validate phone and code format
- confirm the code exists, matches the phone, is unexpired, and is unused
- mint a short-lived one-time `registerTicket`
- mark the code as consumed or otherwise prevent unsafe reuse
- return the verified phone and ticket

### 3. Complete Registration

Suggested endpoint:

`POST /api/auth/register`

Input:

- `phone`
- `registerTicket`
- `nickname`
- `password`

Responsibilities:

- validate the ticket belongs to the phone and is still valid
- validate nickname and password
- reject already-registered phone numbers
- create the user
- return `token + user`

This splits verification from user creation cleanly and avoids carrying raw verification codes through the entire process.

## Development-Mode Verification Strategy

For now, the project should use a development-friendly verification strategy:

- the backend stores real verification data and expiry metadata
- the send-code endpoint returns the generated code to the client
- the first-step page displays the code as a short debug hint, for example `调试验证码：123456`

After end-to-end verification is stable, the system should switch to a safer development posture:

- the backend still generates and stores the code
- the client no longer displays it
- the code is printed only to backend logs/console

This means the core verification implementation stays the same. Only the debug exposure changes.

## Frontend Structure

The main registration path should be reshaped around the new formal flow.

### Main Pages

- `RegisterVerifyPage`
  - phone input
  - code input
  - send-code button
  - next-step button
  - development-mode debug-code display

- `RegisterProfilePage`
  - nickname
  - password
  - confirm password
  - complete registration button

### Routing

Primary registration entry points should route only to the new verification-first flow:

- login landing page
- password login page's `去注册`
- phone-code login page's register entry

Older placeholder registration pages may remain in the codebase temporarily, but they should no longer be reachable from the primary user journey.

## Validation Rules

### Local Validation

Step 1:

- phone format
- code length and numeric shape

Step 2:

- nickname minimum length
- password minimum length
- password equals confirm password

### Server Validation

- phone format
- duplicate phone prevention
- code correctness
- code expiration
- ticket validity
- banned or invalid user creation edge cases

## Session Handling

Registration success should behave like a normal successful login:

- create session from returned token and user
- persist session using the existing auth-state persistence path
- route to `pages/Index`
- preserve login state across app restarts

## Error Handling

The user should receive clear, product-like messages:

- invalid phone number
- verification code send failure
- verification code incorrect
- verification code expired
- phone already registered
- nickname too short
- password too short
- passwords do not match
- network request failure

The first page should not allow the user into step two until verification succeeds.

## Why This Is the Recommended Final Direction

This design gives the project the right product shape without overbuilding:

- more formal than direct registration
- easier to explain in a defense/demo
- more realistic than the old placeholder SMS flow
- cleanly extensible to real SMS later

It also avoids a common trap: building fake SMS pages that look realistic but do not line up with backend behavior. Here, the product flow and backend contract are designed together.
