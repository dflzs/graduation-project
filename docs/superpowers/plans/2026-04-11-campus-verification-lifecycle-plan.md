# Campus Verification Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make campus profile and verification semantics consistent, then expose a unified trust presentation across transaction pages.

**Architecture:** Keep profile editing and verification submission conceptually separate, but centralize all public-facing verification rendering in a shared utility. Transaction pages consume the shared presentation instead of building ad-hoc trust text.

**Tech Stack:** ArkTS, ArkUI, local unit tests via Hypium.

---

## Chunk 1: Shared Trust Presentation

### Task 1: Add a reusable public verification presentation helper

**Files:**
- Create: `entry/src/main/ets/utils/campus-trust-ui.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add unit coverage for:
- verified user -> trusted badge + summary
- pending user -> waiting badge + conservative helper text
- rejected/unverified user -> non-trusted fallback text
- missing user -> graceful fallback

- [ ] **Step 2: Run test to verify it fails**

Run: `LocalUnit.test.ets`
Expected: missing helper import / missing function assertions fail.

- [ ] **Step 3: Write minimal implementation**

Implement a small helper that returns:
- `badgeText`
- `badgeTextColor`
- `badgeBackgroundColor`
- `headline`
- `summary`
- `helperText`

The helper must be safe for null users and must never claim verified identity for non-verified states.

- [ ] **Step 4: Run test to verify it passes**

Run: `LocalUnit.test.ets`
Expected: new trust presentation assertions pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add shared campus trust presentation`

## Chunk 2: Product And Chat Integration

### Task 2: Show seller or counterparty trust identity on product and chat pages

**Files:**
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`

- [ ] **Step 1: Wire the helper into product detail**

Read seller from `userRepository`, build a trust card, and place it near transaction information.

- [ ] **Step 2: Wire the helper into chat detail**

Read peer identity from `userRepository`, render a compact trust line in the product summary card.

- [ ] **Step 3: Verify conservative fallback behavior**

If counterparty is missing locally, show neutral fallback copy instead of fake verified info.

- [ ] **Step 4: Run build verification**

Run: `assembleHap`
Expected: build passes.

- [ ] **Step 5: Commit**

Commit message: `feat: surface campus trust in product and chat detail`

## Chunk 3: Order Detail Integration

### Task 3: Show counterparty campus trust on order detail page

**Files:**
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`

- [ ] **Step 1: Add counterparty trust section**

Render the other party’s verification badge, school summary, and helper copy in order detail.

- [ ] **Step 2: Keep buyer/seller perspective correct**

If viewer is buyer, show seller trust; if viewer is seller, show buyer trust.

- [ ] **Step 3: Run build verification**

Run: `assembleHap`
Expected: build passes.

- [ ] **Step 4: Commit**

Commit message: `feat: add campus trust summary to order detail`
