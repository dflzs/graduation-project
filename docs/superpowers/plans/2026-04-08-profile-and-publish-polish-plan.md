# Profile And Publish Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the profile and publish pages so the working upload flows feel production-ready and simulator-only helpers are clearly secondary.

**Architecture:** Add one small shared regression around simulator URL cleanup in `normalizeManualCoverUrl(...)`, then reuse that helper while rebalancing the two page layouts. Keep all existing upload and save flows intact.

**Tech Stack:** ArkTS, HarmonyOS/DevEco, Hypium local unit tests, existing upload/auth services.

---

## Chunk 1: URL Cleanup Regression

### Task 1: Add and satisfy a failing regression test for noisy pasted simulator URLs

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/utils/cover-image.ets`

- [ ] **Step 1: Write the failing test**

Add a test proving `normalizeManualCoverUrl(...)` extracts the first valid `http(s)` URL from a noisy pasted string that contains terminal residue.

- [ ] **Step 2: Run verification to observe failure**

Run the local compile/test flow that includes `LocalUnit.test.ets` expectations.
Expected: FAIL because the helper currently only accepts clean strings starting with `http://` or `https://`.

- [ ] **Step 3: Implement the smallest helper change**

Update `normalizeManualCoverUrl(...)` to trim, detect clean URLs, and otherwise extract the first valid `http(s)` URL.

- [ ] **Step 4: Re-run verification**

Expected: the new regression passes.

## Chunk 2: Profile Page Polish

### Task 2: Rebalance the profile page toward a professional information layout

**Files:**
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`

- [ ] **Step 1: Keep avatar and nickname as the first-class content**

Make the upper card read like a personal-profile card, with album selection as the main action.

- [ ] **Step 2: Move simulator-only helpers into a softer secondary section**

Keep the manual URL fallback available, but visually demote it and pair draft-reset with that section instead of the hero area.

- [ ] **Step 3: Preserve the single primary save action**

Ensure `保存资料` remains the only strong primary action on the page.

## Chunk 3: Publish Page Polish

### Task 3: Clean up publish-page copy and simulator-fallback hierarchy

**Files:**
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`

- [ ] **Step 1: Restore concise Chinese copy**

Replace awkward or temporary wording with clean publish-flow copy for section labels, helper text, and buttons.

- [ ] **Step 2: Make the simulator URL field secondary**

Keep album selection as the main path and move manual URL input into a clearly labeled simulator helper section.

- [ ] **Step 3: Preserve the current working submit flow**

Do not change the successful cover-upload and publish behavior while reworking presentation.

## Chunk 4: Final Verification

### Task 4: Verify helper behavior and full compile

**Files:**
- Test: `entry/src/test/LocalUnit.test.ets`
- Manual: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Manual: `entry/src/main/ets/pages/Product/PublishProductPage.ets`

- [ ] **Step 1: Verify the helper regression**

Confirm the noisy URL normalization behavior is covered.

- [ ] **Step 2: Re-run ArkTS compile**

Run the DevEco `assembleHap` flow and confirm build success.

- [ ] **Step 3: Manual UI verification**

Check:
- profile page keeps simulator tools secondary
- save flow still works
- publish page copy reads naturally
- publish page still previews local/manual cover input correctly
