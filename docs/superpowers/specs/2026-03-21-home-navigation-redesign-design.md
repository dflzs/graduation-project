# Client Home And Navigation Redesign Design

> Approved scope: redesign the client information architecture from a development-style shell into a formal marketplace app structure inspired by Xianyu, while staying within the current campus second-hand product scope.

## Goal

Turn the current client structure into a more realistic product architecture:

- remove the confusing "home inside home" flow
- remove the dedicated announcement tab
- promote search and product discovery to the true home page
- introduce a clearer bottom navigation model aligned with a second-hand marketplace app

## Why This Change

The current structure still reflects a development shell:

- `Index` is a jumping page, not the real home page
- users must tap "进入首页" to reach the actual product list
- announcements occupy a full bottom tab despite being low-frequency information

This makes the app harder to understand and weakens the overall product feel during demo and defense.

## Approved Information Architecture

The bottom navigation should become:

- `首页`
- `分类`
- `发布`
- `消息`
- `我的`

### Navigation Roles

- `首页`: search-first discovery page, announcement strip, product feed
- `分类`: category-channel page for browsing products by type
- `发布`: center floating circular primary action, opens publish page directly
- `消息`: message index and future conversation entry
- `我的`: profile, orders, published items, admin entry

## Home Page Structure

The current two-step structure should be removed:

- `Index` should become the true app shell and real home container
- users should not tap again to "enter" home

### Home Layout Priority

The top-to-bottom order should be:

1. fixed search bar at the top
2. horizontal announcement strip under search
3. product feed as the main body

### Search

- search bar is fixed at the top
- search is the strongest entry point on home
- it should remain visible while browsing the product list

### Announcement Strip

- only show the newest 1 to 2 announcements
- use a horizontal strip instead of a separate card block
- tapping enters the full announcement history page

### Product Feed

- no category section on home
- category browsing belongs entirely to the `分类` tab
- home product feed should use a two-column card layout
- this feed should feel like a marketplace discovery surface rather than a utility dashboard

## Category Page

The second tab should not be a generic list page. It should behave like a lightweight channel page:

- show the main categories:
  - 教材书籍
  - 电子数码
  - 日用百货
  - 运动户外
  - 其他
- tapping a category enters or filters that category's product feed

This replaces the need for duplicate category UI on home.

## Publish Button

- `发布` is the center circular primary action in the bottom bar
- it should be visually stronger than the other tabs
- tapping it opens the existing publish product page directly

## Message Page

The `消息` tab should act as the future communication container:

- start with a message index / session list shell
- later evolve into buyer-seller conversations and system interaction reminders

This prevents the tab from feeling like a dead placeholder.

## My Page

The `我的` tab should consolidate personal actions:

- profile information
- order access
- published items access
- admin entrance for admin users

This removes the need for repeated quick entries on home.

## Design Direction

The redesign should feel closer to a campus marketplace app than a generic management app:

- search-first top area
- light announcement strip
- product-led home page
- stronger visual treatment for the center publish button
- cleaner separation between discovery, category browsing, messaging, and personal actions

## In Scope

- redesign app-level navigation structure
- redefine home page as the real primary landing page
- remove the dedicated announcement tab from the final architecture
- redesign home layout order
- add the new tab responsibilities for category and message

## Out Of Scope

- full chat implementation
- full published-items management center
- backend message API integration
- detailed announcement management redesign
- final visual polish of every tab in one pass

## Verification Criteria

This redesign is complete when:

1. users no longer need to tap "进入首页" to reach the real home page
2. bottom navigation is `首页 / 分类 / 发布 / 消息 / 我的`
3. `公告` is no longer a dedicated bottom tab
4. home starts with a fixed search bar, then announcement strip, then product feed
5. home uses a two-column product card layout
6. category browsing is handled by the `分类` tab, not duplicated on home
