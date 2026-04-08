# Transaction Experience Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the shopping-cart and order flow into a product-like transaction experience that is stronger for demo and presentation.

**Architecture:** Reuse the existing local order/cart services and improve the presentation layer around them. Keep business rules stable while restructuring cart, confirm-order, order-list, and order-detail UIs into clearer card-based flows with better action placement and fully Chinese product-facing copy.

**Tech Stack:** HarmonyOS ArkTS, ArkUI declarative UI, existing appContext cart/order/product repositories

---

## Chunk 1: Cart Experience

### Task 1: Upgrade cart content into a clearer checkout-style view

**Files:**
- Modify: `entry/src/main/ets/components/CartContent.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: cart content still reads like a simple debug list instead of a polished pre-checkout page.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/components/CartContent.ets`
Expected: item rows are plain text blocks and totals/actions are not strongly grouped

- [ ] **Step 3: Write minimal implementation**

Update cart content so it:

- uses stronger card-based item layout
- shows title, unit price, quantity, and subtotal clearly
- improves empty-state presentation
- keeps total and main actions visually grouped

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/components/CartContent.ets`
Expected: cart reads like a real checkout preparation page

## Chunk 2: Confirm Order Page

### Task 2: Rebuild order creation into a proper confirmation page

**Files:**
- Modify: `entry/src/main/ets/pages/Order/CreateOrderPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: create-order still looks like a plain developer form.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
Expected: product info, amount, and address entry are not yet grouped into a polished confirmation layout

- [ ] **Step 3: Write minimal implementation**

Update the page so it:

- presents product and amount in clearer grouped cards
- keeps the editable handover note/address field
- uses stronger Chinese copy
- presents submission as the main action

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
Expected: page reads like a real confirmation step

## Chunk 3: Order List

### Task 3: Convert order list into card-based status summaries

**Files:**
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: order list still exposes review inputs globally and lacks product-like status hierarchy.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Order/OrderListPage.ets`
Expected: review inputs still appear at the top and list items are plain information blocks

- [ ] **Step 3: Write minimal implementation**

Update the list so it:

- removes global review inputs
- uses clearer order cards
- highlights status and amount
- keeps only relevant quick actions plus detail entry

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Order/OrderListPage.ets`
Expected: order list reads like transaction progress cards

## Chunk 4: Order Detail

### Task 4: Make order detail fully Chinese and sectioned

**Files:**
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: order detail still contains English copy and presents information as raw text lines.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
Expected: English labels still exist and review entry is not well integrated

- [ ] **Step 3: Write minimal implementation**

Update the page so it:

- uses all-Chinese user-facing copy
- groups status, product info, and order info into cards
- places review input here for completed-unreviewed orders
- keeps action buttons aligned with current state

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
Expected: order detail looks like a real transaction detail page

## Chunk 5: Verification

### Task 5: Verify the full transaction demo path

**Files:**
- Verify: `entry/src/main/ets/components/CartContent.ets`
- Verify: `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
- Verify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Verify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`

- [ ] **Step 1: Run static inspection**

Run: inspect modified files
Expected: copy, grouping, and action placement align with the approved transaction UX

- [ ] **Step 2: Run available local verification**

Run: DevEco / hvigor build
Expected: build succeeds without new compile errors

- [ ] **Step 3: Manual runtime verification**

Verify in emulator:

- cart looks like a checkout-prep page
- order creation looks like confirmation rather than debug form
- order list has no top review form and uses clearer cards
- order detail is fully Chinese and handles review entry there
