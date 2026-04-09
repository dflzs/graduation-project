# Auth UI Rev2 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the core auth pages into the approved A-style product UI and enforce symmetric secondary actions on the login center.

**Architecture:** Extend the shared auth polish tokens with a reusable symmetric split-button layout, cover it with a small unit test, then apply the shared layout and updated visual hierarchy to the five auth pages without changing auth business logic.

**Tech Stack:** ArkTS, ArkUI, Hypium local unit tests

---

## Chunk 1: Shared Auth Layout Tokens

### Task 1: Add a reusable symmetric split-button layout token

**Files:**
- Modify: `entry/src/main/ets/utils/ui-polish-tokens.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] Add an `AuthSplitButtonLayout` class with `leftWeight`, `rightWeight`, and `gap`.
- [ ] Add `getAuthSymmetricSplitButtonLayout()` returning equal weights and the shared gap.
- [ ] Write a unit test asserting the two weights are equal and the gap matches the approved layout.

## Chunk 2: Login Center

### Task 2: Apply the shared symmetric layout to the login center

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`

- [ ] Replace the current low-emphasis layout with the approved A-style hero card and action card.
- [ ] Use the shared split-button layout so `验证码登录` and `手机号注册` are visually centered and equal-width.
- [ ] Keep route behavior unchanged.

## Chunk 3: Password and Code Request Pages

### Task 3: Polish password login and code-request login

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/PhoneLoginStep1Page.ets`

- [ ] Move both pages to the three-section structure: hero card, form card, action card.
- [ ] Keep only one primary CTA per page.
- [ ] Replace English/testing copy with formal Chinese where needed.
- [ ] Use the shared split-button layout for secondary actions.

## Chunk 4: Code Entry and Register Verify

### Task 4: Bring the remaining auth pages into the same system

**Files:**
- Modify: `entry/src/main/ets/pages/Auth/PhoneLoginStep2Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterVerifyPage.ets`

- [ ] Restyle the verification code entry page to match the approved auth system.
- [ ] Restyle the register verify page so it no longer looks like an old test page.
- [ ] Keep countdown, resend, and navigation logic unchanged.

## Chunk 5: Verification

### Task 5: Verify compile path and summarize manual checks

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] Ensure token tests cover the new split-button layout helper.
- [ ] Ask for DevEco `assembleHap` verification after implementation.
- [ ] Ask for manual checks on the five auth pages, especially the symmetric pair in the login center.
