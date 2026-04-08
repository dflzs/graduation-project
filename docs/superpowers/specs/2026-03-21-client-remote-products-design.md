# Client Remote Product Read Integration Design

> Approved scope: connect the HarmonyOS client home list and product detail pages to the deployed backend product read endpoints first, while leaving create/order/chat write flows for later.

## Goal

Make the client read real product data from the deployed backend so that:

- the home page shows server-backed products
- the product detail page shows server-backed details
- failures surface in Chinese instead of silently falling back to stale local seed data

## Why This Slice Next

The login loop is already connected to the deployed backend, so the next highest-value visible improvement is product browsing. It gives a much stronger demo than “login works” alone, while still keeping the change small and reversible.

Trying to replace the full local product/order/cart stack in one pass would create unnecessary risk. This slice keeps the client architecture stable and introduces only a remote read path for product browsing.

## In Scope

- Add remote product response types for list/detail endpoints
- Add a small HTTP client for:
  - `GET /api/products`
  - `GET /api/products/:id`
- Map backend product responses into the existing local `Product` domain model
- Update the home page to load and render remote products
- Update the product detail page to load and render a remote product
- Show Chinese error/empty states when the remote request fails or the product is missing

## Out Of Scope

- Publish product flow
- Product edit flow
- Cart write flow
- Order creation from the client
- Chat, announcements, admin client integration
- Large refactors of `product.service.impl.ets` or repository internals

## Architecture

This slice adds a separate remote read-only product path instead of replacing the entire local product service. The home page and detail page will fetch remote data directly through a small remote client plus mapper. Existing local product service and repository code stay in place for the rest of the app until later slices migrate them systematically.

This keeps the integration narrow:

- transport concerns stay in a remote client
- backend-to-domain conversion stays in a mapper/helper
- UI pages only coordinate loading, error state, and rendering

## Backend Contract Assumptions

Current deployed backend returns product list/detail records shaped like:

```json
{
  "code": 0,
  "message": "获取商品列表成功",
  "data": [
    {
      "id": 1,
      "seller_id": 2,
      "title": "二手机械键盘",
      "description": "九成新，功能正常，适合宿舍学习使用",
      "price": "88.50",
      "category": "电子数码",
      "location_tag": "图书馆门口",
      "cover_image": "",
      "status": "off_shelf",
      "created_at": "2026-03-20T13:29:58.000Z",
      "updated_at": "2026-03-20T14:22:20.000Z"
    }
  ]
}
```

Detail uses the same `data` shape but as a single object instead of an array.

## Domain Mapping

The existing client `Product` model expects:

- `id: string`
- `sellerId: string`
- `title: string`
- `desc: string`
- `price: number`
- `category: string`
- `images: string[]`
- `locationTag: string`
- `status: 'on_sale' | 'sold' | 'off_shelf'`
- `isDeleted: boolean`
- `createdAt: number`
- `updatedAt: number`

Mapping rules:

- `id` ← `String(id)`
- `sellerId` ← `String(seller_id)`
- `desc` ← `description`
- `price` ← `Number(price)`
- `images` ← `cover_image ? [cover_image] : []`
- `locationTag` ← `location_tag`
- `status` ← backend `status` if valid, else `on_sale`
- `isDeleted` ← `false`
- `createdAt/updatedAt` ← `Date.parse(...)`, fallback to `Date.now()`

## UI Behavior

### Home Page

- On page enter/show, request remote product list
- Render remote products in the existing card layout
- Keep current keyword/category filtering client-side for now
- If request fails, show a Chinese toast and an empty list
- If request succeeds but is empty, show a Chinese empty state

### Product Detail Page

- On page enter/show, request remote product detail by `productId`
- Render remote product details using the current layout
- If request fails or the product does not exist, show a Chinese “商品不存在或加载失败” state

## Error Handling

- Transport failure: show a Chinese network message
- Backend failure: surface backend `message`
- Unexpected payload: show a Chinese parsing/fetch failure message
- Missing product ID in route params: show a Chinese invalid-parameter message

## Verification Criteria

This slice is complete when:

1. Logging in and entering the home page shows real server products
2. The seeded server product “二手机械键盘” appears on the client
3. Tapping the item opens a detail page with remote data
4. If the remote call fails, the user sees a Chinese message instead of stale fake data or a crash

## Follow-Up Work

After this slice, recommended next client steps are:

1. Product publish flow against the backend
2. Order creation/list/detail integration
3. Chat integration
4. Remaining auth page localization and registration alignment
