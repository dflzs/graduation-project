# Message Hub Skeleton Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the placeholder message tab with a formal message hub that combines transaction reminders and buyer-seller conversation entry points.

**Architecture:** Add a local notification subsystem and a lightweight chat-thread aggregation layer on top of the existing persisted local database. Keep first-version messaging local and deterministic: services generate notifications from order/review/moderation events, while a new chat service creates product-bound threads and messages for the message hub UI.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing local repositories and persistence, Hypium unit tests

---

## Chunk 1: Notification Domain and Service

### Task 1: Introduce notification domain storage and service

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/data/db/persisted-state.ets`
- Modify: `entry/src/main/ets/data/db/local-db.ets`
- Create: `entry/src/main/ets/repositories/notification.repo.ets`
- Create: `entry/src/main/ets/services/notification.service.impl.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing notification test**

```ts
it('notification_service_should_store_user_notifications_in_reverse_time_order', 0, () => {
  // create two notifications for one user
  // verify listByUser returns newest first
  // verify unread count is derived correctly
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because notification entities and services do not exist yet.

- [ ] **Step 3: Implement minimal notification domain**

Add:
- `MessageNotification` entity in `domain.ets`
- persisted local-db support for notifications
- repository save/list/markRead helpers
- notification service facade for UI usage

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for notification persistence and ordering.

- [ ] **Step 5: Checkpoint**

Record that notification domain, persistence, and service entry points are in place.

## Chunk 2: Generate Transaction and Review Notifications

### Task 2: Publish system reminders from existing business flows

**Files:**
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `entry/src/main/ets/services/notification.service.impl.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing reminder-generation tests**

```ts
it('order_service_should_generate_notifications_for_create_cancel_and_complete', 0, async () => {
  // create order, cancel order, complete order
  // verify buyer or seller receives corresponding notifications
});

it('admin_product_actions_should_generate_publish_review_notifications', 0, () => {
  // approve and reject product
  // verify seller gets approval/rejection notifications
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because current business flows do not create message notifications.

- [ ] **Step 3: Implement minimal notification generation**

Wire notifications into:
- order create
- order cancel
- order complete
- admin approve product
- admin reject product

Use small helper methods in the notification service to keep call sites simple.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for order and moderation reminder generation.

- [ ] **Step 5: Checkpoint**

Record that key business events now feed the message hub.

## Chunk 3: Chat Thread Skeleton

### Task 3: Introduce product-bound thread aggregation and simple message send flow

**Files:**
- Create: `entry/src/main/ets/repositories/chat.repo.ets`
- Create: `entry/src/main/ets/services/chat.service.impl.ets`
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing chat-thread test**

```ts
it('chat_service_should_create_or_reuse_product_bound_threads_and_store_messages', 0, () => {
  // create a thread for buyer-seller-product combination
  // send a message
  // create again and verify the same thread is reused
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because no thread abstraction or chat service exists.

- [ ] **Step 3: Implement minimal chat skeleton**

Add:
- `ChatThread` view model or domain shape
- repository methods for thread aggregation
- service methods to create/reuse thread and send text message
- app context exposure for the new service

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for thread creation, reuse, and message storage.

- [ ] **Step 5: Checkpoint**

Record that the app now has a usable local conversation backbone.

## Chunk 4: Message Hub UI

### Task 4: Replace the placeholder tab with a real message hub

**Files:**
- Create: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: Write the failing UI checklist**

```md
- message tab no longer shows placeholder copy
- transaction reminders are visible as a list
- conversation list is visible as a second section
- empty state is product-like and not developer-facing
- product detail has an entry to contact seller
```

- [ ] **Step 2: Review current implementation to verify it fails**

Run: `Get-Content entry\\src\\main\\ets\\pages\\Index.ets`
Expected: the current message tab is still a placeholder info block.

- [ ] **Step 3: Implement minimal message hub UI**

Build:
- message hub page with title, reminder section, conversation section, and empty state
- index tab content swap from placeholder to `MessageHubPage`
- product detail “联系卖家” entry that creates or opens a thread

- [ ] **Step 4: Re-check the UI checklist**

Run: inspect `entry/src/main/ets/pages/Chat/MessageHubPage.ets`, `entry/src/main/ets/pages/Index.ets`, and `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: placeholder is gone and the new sections exist.

- [ ] **Step 5: Checkpoint**

Record that the一级导航消息入口 has become a real product page.

## Chunk 5: Conversation Detail Page

### Task 5: Add a lightweight chat detail page

**Files:**
- Create: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing chat-detail behavior test**

```ts
it('chat_service_should_return_messages_for_a_thread_in_time_order', 0, () => {
  // send multiple messages in one thread
  // verify detail page data source can read them in ascending order
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because thread detail reading is not yet exposed as a dedicated flow.

- [ ] **Step 3: Implement minimal chat detail page**

Add:
- thread header with peer and product title
- message list
- simple text input and send action
- navigation from message hub conversation cards

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for thread message ordering and detail page data flow.

- [ ] **Step 5: Checkpoint**

Record that the message hub can now open usable conversation detail pages.

## Chunk 6: Verification

### Task 6: Verify the message hub safely

**Files:**
- Verify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Verify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Verify: `entry/src/main/ets/services/notification.service.impl.ets`
- Verify: `entry/src/main/ets/services/chat.service.impl.ets`
- Verify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run static inspection**

Run: `rg -n "MessageHubPage|ChatDetailPage|notification|ChatThread|联系卖家" entry\\src\\main\\ets entry\\src\\test`
Expected: all new message-hub pieces are referenced.

- [ ] **Step 2: Run available local verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for new notification and chat tests.

- [ ] **Step 3: Manual runtime verification**

Verify in DevEco/emulator:
- 消息 tab shows reminder cards and conversation cards
- product approval/rejection creates visible reminders
- order create/cancel/complete creates visible reminders
- product detail can open a seller conversation
- conversation detail can send and display local messages
- empty state appears cleanly when there is no data

- [ ] **Step 4: Document any follow-up gaps**

Capture items intentionally deferred:
- real-time sync
- remote persistence
- read receipts
- media messages

Plan complete and saved to `docs/superpowers/plans/2026-04-05-message-hub-skeleton-plan.md`. Ready to execute?
