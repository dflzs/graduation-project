# Global Search And In-Shell Cart Design

**Date:** 2026-03-21

**Goal:** Make the home-page search global across on-sale products and turn cart into an in-shell bottom tab instead of a route jump.

## Approved UX Changes

- Home search becomes global.
- Category rail still exists for browsing.
- When the search box contains text:
  - search matches all on-sale products
  - selected category does not limit results
- When the search box is empty:
  - the selected category controls the home feed
- Cart should no longer navigate away from the main shell.
- Cart becomes a first-class bottom tab rendered inside the current shell.

## Navigation Structure

- 首页
- 消息
- 发布
- 购物车
- 我的

`发布` remains the center raised action button.

## Home Feed Rules

- Search always matches only `on_sale` products.
- Search keyword checks title and description, same as current logic.
- Category rail is preserved as a browsing aid.
- Feed header should reflect the current mode:
  - if searching: show search-results semantics
  - if not searching: show current category / 推荐 semantics

## Cart Rendering Strategy

Do not duplicate cart logic inside `Index.ets`.

Instead:

- extract the current cart body into a reusable component
- let the standalone cart page reuse that component
- let the shell tab render the same component

This keeps cart behavior in one place and avoids divergence between routed cart and tab cart.

## Scope

### In scope

- Global search behavior in `HomePage`
- Reusable cart content component
- In-shell cart tab rendering in `Index`

### Out of scope

- Cart visual redesign
- Message business logic changes
- Search result page routing
- Backend search changes
