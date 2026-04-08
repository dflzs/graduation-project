# Cart And Page Header Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the cart into a management-oriented settlement page and align major pages to a top-first header rhythm.

**Architecture:** Keep existing product, cart, and order services intact while restructuring the cart UI around selection state and mode switching. Adjust major page headers in place instead of introducing a heavy navigation refactor.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing appContext services, local repositories, DevEco runtime verification

---

## Chunk 1: Cart Interaction Model

### Task 1: Add selection and management state to cart

**Files:**
- Modify: `entry/src/main/ets/components/CartContent.ets`

- [ ] **Step 1: Write the failing behavior checklist**

```md
- cart supports normal mode and management mode
- cart supports item selection and all-select
- bottom bar changes between settlement and delete actions
```

- [ ] **Step 2: Review current cart responsibilities**

Run: `rg -n "@State|buildEmptyState|buildCartItem|合计|删除|下单" entry\\src\\main\\ets\\components\\CartContent.ets`
Expected: current cart is still a simple card list with per-item actions.

- [ ] **Step 3: Implement cart state model**

Add:
- selected item ids
- management mode state
- all-select helper
- selected-total calculation

- [ ] **Step 4: Re-check behavior checklist**

Run: `rg -n "manageMode|selectedItemIds|toggleSelect|toggleSelectAll" entry\\src\\main\\ets\\components\\CartContent.ets`
Expected: cart now owns explicit management and selection state.

- [ ] **Step 5: Checkpoint**

Record that cart interaction no longer depends on per-card standalone buttons only.

## Chunk 2: Cart UI Reconstruction

### Task 2: Rebuild the cart layout around top header and bottom action bar

**Files:**
- Modify: `entry/src/main/ets/components/CartContent.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`

- [ ] **Step 1: Write the failing UI acceptance checklist**

```md
- cart header is top-left title with right-side manage/done action
- empty cart keeps header and bottom structure
- bottom bar is fixed-feeling and mode-aware
- selected total and settlement action are visually clear
```

- [ ] **Step 2: Review current cart page structure**

Run: `rg -n "购物车|管理|全选|结算|删除" entry\\src\\main\\ets\\components\\CartContent.ets entry\\src\\main\\ets\\pages\\Index.ets`
Expected: current layout still lacks top-right manage flow and bottom settlement bar.

- [ ] **Step 3: Implement cart UI**

Update:
- top header row
- item row selection UI
- empty state placement
- bottom settlement bar
- bottom management bar

- [ ] **Step 4: Re-check UI acceptance checklist**

Run: `rg -n "管理|完成|全选|结算|删除" entry\\src\\main\\ets\\components\\CartContent.ets`
Expected: all core cart actions are now represented in the new layout.

- [ ] **Step 5: Checkpoint**

Record that the cart now reads as a transaction-preparation page instead of a simple list.

## Chunk 3: Checkout Guardrails

### Task 3: Align cart settlement behavior with current single-product order model

**Files:**
- Modify: `entry/src/main/ets/components/CartContent.ets`

- [ ] **Step 1: Write the failing behavior checklist**

```md
- settlement works for one selected item
- multi-select settlement explains current limitation clearly
- delete works on selected items in manage mode
```

- [ ] **Step 2: Review current order entry behavior**

Run: `rg -n "createOrder|CreateOrderPage|productId" entry\\src\\main\\ets\\components\\CartContent.ets entry\\src\\main\\ets\\pages\\Order\\CreateOrderPage.ets entry\\src\\main\\ets\\services\\order.service.impl.ets`
Expected: current flow is product-oriented, not multi-product order creation.

- [ ] **Step 3: Implement minimal professional guardrails**

Update:
- one selected item -> proceed to `CreateOrderPage`
- multiple selected items -> toast and hold
- manage mode delete -> remove selected items in bulk

- [ ] **Step 4: Re-check behavior checklist**

Run: `rg -n "selectedItems|removeItem|CreateOrderPage|showToast" entry\\src\\main\\ets\\components\\CartContent.ets`
Expected: single-item settlement and multi-item guardrails are both explicit.

- [ ] **Step 5: Checkpoint**

Record that cart behavior matches the current order architecture without misleading the user.

## Chunk 4: Top-First Page Layout

### Task 4: Normalize header rhythm on major pages

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Modify: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`

- [ ] **Step 1: Write the failing UI acceptance checklist**

```md
- page titles feel anchored near the top
- right-side header actions appear where relevant
- support text sits directly under the title
- content begins immediately below the header area
```

- [ ] **Step 2: Review current vertical rhythm**

Run: `rg -n "fontSize\\(26\\)|fontSize\\(28\\)|padding\\(16\\)|Scroll\\(" entry\\src\\main\\ets\\pages\\Home\\HomePage.ets entry\\src\\main\\ets\\pages\\Chat\\MessageHubPage.ets entry\\src\\main\\ets\\pages\\Order\\OrderListPage.ets entry\\src\\main\\ets\\pages\\Product\\MyPublishedProductsPage.ets entry\\src\\main\\ets\\pages\\Profile\\ProfilePage.ets`
Expected: pages still vary in top spacing and action placement.

- [ ] **Step 3: Implement header rhythm cleanup**

Update:
- top spacing
- title/description grouping
- right-side actions where applicable
- immediate content follow-through below headers

- [ ] **Step 4: Re-check UI acceptance checklist**

Run: `rg -n "管理|全部已读|购物车|我的订单|我发布的|消息" entry\\src\\main\\ets\\pages\\Home\\HomePage.ets entry\\src\\main\\ets\\pages\\Chat\\MessageHubPage.ets entry\\src\\main\\ets\\pages\\Order\\OrderListPage.ets entry\\src\\main\\ets\\pages\\Product\\MyPublishedProductsPage.ets entry\\src\\main\\ets\\pages\\Profile\\ProfilePage.ets`
Expected: headers expose a more product-like structure and clearer actions.

- [ ] **Step 5: Checkpoint**

Record that major pages now feel top-anchored and easier to scan.

## Chunk 5: Verification

### Task 5: Verify cart and page-layout polish

**Files:**
- Verify: `entry/src/main/ets/components/CartContent.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Verify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Verify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Verify: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Verify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`

- [ ] **Step 1: Run static usage inspection**

Run: `rg -n "管理|完成|全选|结算|删除|全部已读" entry\\src\\main\\ets\\components\\CartContent.ets entry\\src\\main\\ets\\pages`
Expected: new cart controls and top-right actions are visible in code.

- [ ] **Step 2: Manual DevEco verification**

Verify:
- message tab no longer crashes
- cart normal mode and manage mode both work
- empty cart still feels like a full page
- selecting one item can proceed toward checkout
- selecting multiple items gives a clear limitation message
- major pages feel top-anchored instead of vertically floating

- [ ] **Step 3: Record follow-up**

If multi-product checkout still feels too limited after the polish pass, queue a later dedicated spec for batch checkout instead of forcing it into this pass.
