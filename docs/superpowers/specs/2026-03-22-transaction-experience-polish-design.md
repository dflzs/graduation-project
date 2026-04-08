# Transaction Experience Polish Design

**Date:** 2026-03-22

**Goal:** Turn the shopping-cart and ordering flow into a more product-like, presentation-ready transaction experience suitable for a graduation project demo.

## Approved Scope

Polish the following pages and shared cart content:

- `entry/src/main/ets/components/CartContent.ets`
- `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
- `entry/src/main/ets/pages/Order/OrderListPage.ets`
- `entry/src/main/ets/pages/Order/OrderDetailPage.ets`

## Product Direction

Reference modern second-hand marketplace flows such as Xianyu:

- clear price hierarchy
- card-based transaction information
- strong state visibility
- simple, obvious primary actions
- reduced developer-facing text and debug-like layouts

The visual system should stay consistent with the app's current warm neutral background + white card language rather than introducing a brand new style.

## Cart Experience

- Cart should feel like a pre-checkout area, not a temporary debug list.
- Each cart item should clearly show:
  - title
  - unit price
  - quantity
  - subtotal
- Primary page focus:
  - current cart content
  - total amount
  - checkout entry
- Empty cart should use a cleaner empty-state presentation.

## Create Order Experience

- Reframe as a proper confirmation page.
- Show:
  - product info
  - amount
  - default face-to-face pickup context
  - editable handover note/address
- Main action should clearly communicate order submission.
- Simulated payment remains, but the explanation should sound product-like instead of technical.

## Order List Experience

- Use card-based order summaries.
- Each card should prioritize:
  - product title
  - amount
  - current status
  - creation time
- Keep quick actions on the card only when they are relevant to the current status.
- Remove always-visible top-of-page review inputs.
- Reviews should move to order detail only.

## Order Detail Experience

- Convert all visible text to Chinese.
- Split the page into clear sections:
  - status card
  - product info card
  - order info card
  - action area
- Completed-but-not-reviewed orders expose review inputs here instead of in the list page.

## Out of Scope

- backend or database changes
- real payment
- order state-machine redesign
- messaging integration
- advanced order filtering or searching

## Success Criteria

The demo path should feel coherent:

`购物车 -> 确认下单 -> 订单列表 -> 订单详情 -> 完成/评价`

The user should be able to explain the transaction flow confidently without needing to apologize for placeholder-looking screens.
