# Product Publish Review Remote Alignment Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify product publishing, moderation, homepage visibility, and single-item transaction locking under one backend-driven product lifecycle.

**Architecture:** Keep the existing page-service-repository layering, but move public product truth fully to the backend. The frontend should publish remotely, read public products remotely, manage seller-specific products through dedicated views, and reflect a richer product-status model. Backend controllers should enforce the moderation lifecycle and single-item lock/sold transitions.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, local repositories as cache, existing backend Node.js controllers, current remote product API integration

---

## Chunk 1: Product Lifecycle Model

### Task 1: Expand product status model for review and transaction locking

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/services/product-remote.client.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `backend_code/product.controller.js`
- Modify: `backend_code/admin.controller.js`

- [ ] **Step 1: Define expanded product statuses**

Add and use:
- `pending_review`
- `on_sale`
- `locked`
- `sold`
- `off_shelf`
- `rejected`

- [ ] **Step 2: Update frontend status parsing and display**

Ensure remote status parsing no longer coerces unknown review/lock statuses back to `on_sale`.

- [ ] **Step 3: Update backend create/list/admin logic to accept the new statuses**

Make controller logic use the expanded lifecycle explicitly.

- [ ] **Step 4: Verify static consistency**

Check that homepage still filters public feed to `on_sale` only and detail/admin pages can render the new statuses without fallback breakage.

## Chunk 2: Remote Publish and Moderation

### Task 2: Replace local-only publish with backend publish

**Files:**
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/services/product.service.impl.ets`
- Create: `entry/src/main/ets/types/product-publish-remote.ets`
- Modify: `entry/src/main/ets/services/product-remote.client.ets`
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `backend_code/product.controller.js`

- [ ] **Step 1: Add a remote publish contract**

Create a dedicated frontend remote payload/response type for product publishing so publish no longer relies on local repository writes.

- [ ] **Step 2: Implement remote create product client call**

Add a POST create-product request path to the remote product client.

- [ ] **Step 3: Route publish page through the remote client**

On submit:
- validate locally
- call backend create endpoint
- show "已提交审核" style feedback
- stop relying on local-only product creation for public data

- [ ] **Step 4: Change backend product creation default status**

Set created products to `pending_review` instead of `on_sale`.

- [ ] **Step 5: Verify publish semantics**

Publishing should succeed remotely and the created product should not appear on the homepage until approved.

### Task 3: Add admin approve/reject actions

**Files:**
- Modify: `backend_code/admin.controller.js`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `entry/src/main/ets/services/product-remote.client.ets`
- Modify: `entry/src/main/ets/services/product.service.impl.ets`

- [ ] **Step 1: Add backend review actions**

Provide admin endpoints for:
- approve product -> `on_sale`
- reject product -> `rejected`
- existing off-shelf remains available

- [ ] **Step 2: Expose the actions in admin product management**

Admin UI should show review buttons for `pending_review` products and status-aware actions for already-reviewed ones.

- [ ] **Step 3: Refresh product state from backend after admin action**

Ensure the admin page reflects the updated remote state without relying on stale local status.

- [ ] **Step 4: Verify moderation flow**

Confirmed sequence:
- publish product
- product enters `pending_review`
- admin approves
- product becomes visible in homepage public feed

## Chunk 3: Seller Management Surface

### Task 4: Replace duplicate "发布商品" in 我的 with "我发布的"

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Create: `entry/src/main/ets/pages/Product/MyPublishedProductsPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/services/product-remote.client.ets`

- [ ] **Step 1: Remove duplicate publish entry from 我的**

Keep the center publish button as the primary publish action.

- [ ] **Step 2: Add seller product management page**

Create `我发布的` page showing the current user's own products and their statuses.

- [ ] **Step 3: Add a remote query path for seller-owned products**

Fetch seller products from backend rather than composing this page from the public homepage feed.

- [ ] **Step 4: Verify seller visibility**

User should be able to see newly published `pending_review` items in `我发布的` even when homepage cannot see them yet.

## Chunk 4: Order-to-Product Locking

### Task 5: Lock single-item goods when an order is created

**Files:**
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/services/product.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/product.repo.ets`
- Modify: `backend_code/order.controller.js`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`

- [ ] **Step 1: Change create-order behavior**

On successful order creation for a single-item product:
- transition product from `on_sale` to `locked`

- [ ] **Step 2: Restore visibility on cancellation**

If the order is canceled before completion, transition the product back to `on_sale`.

- [ ] **Step 3: Preserve sold transition on completion**

Completed orders should still move product state to `sold`.

- [ ] **Step 4: Verify public feed behavior**

Locked products should disappear from homepage public feed and be clearly marked as unavailable in detail contexts.

## Chunk 5: Frontend Consistency and Copy

### Task 6: Align product pages and messages with the moderated lifecycle

**Files:**
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `entry/src/main/ets/constants/config.ets`

- [ ] **Step 1: Update copy**

Replace immediate-sale language with review-aware language, including:
- publish success
- status labels
- unavailable-state explanations

- [ ] **Step 2: Update action states**

Buttons and badges should reflect:
- 审核中
- 审核未通过
- 交易中
- 已售出
- 已下架

- [ ] **Step 3: Verify end-to-end UX**

Final user-facing flow should read naturally:
- 发布商品 -> 审核中
- 管理员审核通过
- 首页展示
- 买家下单后商品进入交易中
- 交易完成后商品已售出

Plan complete and saved to `docs/superpowers/plans/2026-03-28-product-publish-review-remote-alignment-plan.md`. Ready to execute?
