# Client Product Detail Polish Design

> Approved scope: upgrade the client product detail page into a more e-commerce-style presentation page without changing backend contracts or extending the transaction flow.

## Goal

Make the product detail page feel closer to a real shopping app page while keeping the current remote detail loading path stable.

## Why This Slice

The current detail page already works functionally, but it still looks like a development screen:

- information is shown as plain text rows
- the page has too much empty space
- unavailable products still show active-looking action buttons

Polishing this page improves demo quality immediately without risking the order/cart integration.

## In Scope

- Upgrade `ProductDetailPage.ets` visual layout
- Add a richer hero area for product image or placeholder
- Emphasize title, price, and status
- Present category and location as compact tags
- Split product details into card sections
- Keep bottom action buttons fixed and reflect disabled purchase states visually
- Improve loading, empty, and error presentation

## Out Of Scope

- Backend contract changes
- Product publish flow
- Cart or order service refactor
- Seller profile card
- Recommendation module

## Layout

The page should use a soft light-gray background with white cards.

### Top Hero

- Large product visual area
- If `images[0]` exists, show the image
- If no image exists, show a designed placeholder block instead of leaving blank space

### Core Purchase Info

- Large title
- Prominent warm red price
- Status chip with color by product status
- Category and location chips below

### Detail Cards

- `商品说明` card for the description
- `交易信息` card for status, location, and publish time

### Bottom Action Bar

- Fixed to bottom
- `加入购物车` and `立即下单`
- If product is not tradable, buttons must look disabled and text should explain why

## Status Rules

- `on_sale` -> 在售, green-style chip, action buttons enabled
- `sold` -> 已售出, dark neutral chip, action buttons disabled
- `off_shelf` -> 已下架, warm gray/orange chip, action buttons disabled

## Error And Loading States

- Loading should use a full-page placeholder layout instead of a single line of text
- Empty/error state should be centered and readable
- Error state should offer a retry action

## Verification Criteria

This slice is complete when:

1. Product detail page still loads remote data by `productId`
2. The current server product shows title, price, category, status, location, time, and description
3. `已下架` products show disabled-looking action buttons
4. The page feels visually closer to an e-commerce product page than the current plain text version
