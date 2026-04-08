# Home Category Rail Design

**Date:** 2026-03-21

**Goal:** Remove the dedicated bottom `分类` tab and move category switching into the home page, while promoting `购物车` into the bottom navigation.

## Approved Information Architecture

- Bottom navigation:
  - 首页
  - 消息
  - 发布
  - 购物车
  - 我的
- `发布` remains the center primary action button.
- `分类` is removed from the bottom navigation.
- Home page order:
  - fixed search header
  - announcement strip
  - horizontal category rail
  - product feed

## Category Strategy

The app keeps the existing stable category vocabulary to avoid changing backend data or remote database values.

- 推荐
- 教材书籍
- 电子数码
- 日用百货
- 运动户外
- 其他

`推荐` means all `on_sale` products and does not map to a stored category value.

## Interaction Rules

- Announcement strip is global and does not change when category changes.
- Category switching only refreshes the product feed.
- Search filters within the currently selected category scope.
  - 推荐: search across all on-sale products
  - specific category: search only in that category
- The category rail is horizontally scrollable.
- The selected category uses a stronger visual style than inactive categories.

## Scope

### In scope

- Rebuild bottom navigation to `首页 / 消息 / 发布 / 购物车 / 我的`
- Add a horizontal category rail to the home page
- Make the home feed respond to selected category + keyword
- Promote existing cart page into the bottom navigation

### Out of scope

- Backend category migration
- Database schema changes
- New category detail pages
- Message business logic redesign
- Cart page visual redesign

## Implementation Notes

- Keep category values compatible with existing remote product data.
- Reuse the current home product-loading path.
- Reuse the current cart page route instead of building a new cart shell.
- Keep product status filtering consistent with the current home behavior: only `on_sale` items appear in the home feed.
