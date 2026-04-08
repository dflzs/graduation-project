# Product Publish Review Remote Alignment Design

**Date:** 2026-03-28

**Goal:** Replace the current split local/remote product pipeline with a single backend-driven publish and moderation flow so newly published goods follow `发布 -> 审核 -> 上架 -> 锁定 -> 售出` and the homepage only shows approved, saleable inventory.

## Problem Summary

The app currently has two inconsistent product paths:

- The homepage and product detail pages read product data from the backend product API.
- The publish page writes products only into the local client repository.

This produces a product experience that is not defensible:

- publishing can succeed locally while the homepage still shows no new item
- moderation is missing even though the app already has an admin backend
- "我的" duplicates the publish action instead of helping users manage their published goods

The order flow also still assumes a simplistic direct-sale model. For a second-hand platform, a created order should lock the item instead of leaving it exposed in the public product feed.

## Approved Direction

Use the backend as the single source of truth for public products.

The client should stop treating locally created products as public inventory. Instead:

1. user submits a product through the publish page
2. backend creates the product in a pending-review state
3. admin reviews the product from backend/admin product management
4. approved products become visible on the homepage
5. rejected products remain visible only in "我发布的"

This keeps the platform defensible and aligns with professional second-hand marketplace patterns.

## Product Lifecycle

For this phase, keep the platform on a single-item idle-goods model. Do not introduce inventory counts yet.

Recommended product lifecycle:

- `pending_review`: user submitted, waiting for admin review
- `on_sale`: approved and publicly visible
- `locked`: an active transaction exists; item should not be publicly purchasable
- `sold`: transaction completed
- `off_shelf`: manually removed by seller/admin
- `rejected`: review failed

Homepage, category rail, and search should only show `on_sale`.

## Publish Flow

### Client

- `PublishProductPage` should submit to a backend create-product API instead of local-only `productService.createProduct()`.
- Successful publish feedback should say the item entered review rather than "发布成功即上架".
- After submission, route the user to "我发布的" or back to a management entry where they can see review state.

### Backend

- Product creation should persist the new product as `pending_review`.
- Product list APIs used by the public homepage should return only public saleable items by default, or the client should explicitly request `status=on_sale`.
- Admin product management should gain explicit review actions:
  - approve product
  - reject product
  - off-shelf product

## My Page Structure

The current "我的" page duplicates the publish entry, which is already handled by the center bottom publish button.

Replace the "发布商品" entry with:

- `我发布的`

This page should show the seller's own products grouped or tagged by status:

- 审核中
- 审核未通过
- 在售
- 交易中
- 已售出
- 已下架

This is a better personal-management surface and removes the redundant publish shortcut.

## Order and Product State Coordination

This phase should also align product visibility with the order lifecycle for single-item goods.

Recommended order-product coordination:

- create order:
  - if product is `on_sale`, transition product to `locked`
- cancel order before completion:
  - if no other active order exists, transition product back to `on_sale`
- complete order:
  - transition product to `sold`

This prevents public feeds from showing a product that is already in an active transaction.

## Remote API Direction

Current backend code already contains:

- public product listing and detail endpoints
- product creation endpoint
- admin product list endpoint
- admin off-shelf endpoint

This phase extends, rather than replaces, that backend shape:

- publish endpoint writes `pending_review`
- admin endpoints add approve/reject actions
- public list endpoint continues to serve the homepage as the source of truth

## Data Model Changes

### Frontend

- Expand `ProductStatus` to include:
  - `pending_review`
  - `locked`
  - `rejected`
- Update status-text and badge rendering across homepage, detail page, admin page, and seller-management page.
- Introduce a dedicated seller product management page rather than reusing the homepage.

### Backend

- Expand product status enum/allowed values to include:
  - `pending_review`
  - `locked`
  - `rejected`
- Update product create/list/admin update logic accordingly.

## Out of Scope

These are intentionally deferred to avoid mixing two large model changes at once:

- multi-quantity inventory (`stock`, `availableStock`)
- automatic stock decrement for multi-item goods
- buyer-side reservation timers
- chat-based offer negotiation
- seller self-service edit and re-submit after rejection beyond simple status handling

If the platform later needs "not only one item" goods, that should be a separate inventory-model project.

## Success Criteria

This work is successful when:

- publishing a product no longer creates a local-only ghost item
- new products enter `pending_review` instead of appearing immediately
- admin can approve or reject submitted items
- approved items appear on the homepage because homepage and publish now share the same backend truth source
- "我的" stops duplicating the publish action and instead provides `我发布的`
- creating an order for a single item removes it from public sale by moving it into `locked`
