# Message Hub Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the current message hub skeleton into a more product-like message center with unread state, better reminder routing, and campus-friendly conversation detail improvements.

**Architecture:** Keep the existing local notification and chat services as the source of truth. Add small targeted capabilities on top: unread aggregation for the bottom tab, auto-read transitions when opening reminders or threads, and richer chat detail UI with product context and quick replies.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing local persistence, local repositories/services, Hypium unit tests

---

## Chunk 1: Unread State and Message Tab Badge

### Task 1: Add unread aggregation for reminders and conversations

**Files:**
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/services/chat.service.impl.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing unread-state test**

```ts
it('message_hub_should_count_unread_reminders_and_threads_together', 0, async () => {
  // create one unread reminder
  // create one unread incoming chat message
  // verify aggregated unread count is 2
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because no aggregated message unread capability exists.

- [ ] **Step 3: Implement minimal unread aggregation**

Add:
- a helper in `Index.ets` or app-level computation for unread badge count
- conversation unread count reuse from `ChatService`
- a lightweight badge on the bottom `消息` tab

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for unread aggregation behavior.

- [ ] **Step 5: Checkpoint**

Record that the message tab now exposes unread signal at navigation level.

## Chunk 2: Reminder Auto-Read and Better Navigation

### Task 2: Make reminder cards behave like actionable tasks

**Files:**
- Modify: `entry/src/main/ets/repositories/notification.repo.ets`
- Modify: `entry/src/main/ets/services/notification.service.impl.ets`
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing reminder-read test**

```ts
it('notification_service_should_mark_single_notification_as_read', 0, () => {
  // create unread notification
  // mark it read by id
  // verify unread count decreases
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because only markAllRead exists today.

- [ ] **Step 3: Implement minimal single-read behavior**

Add:
- repository method to mark one notification as read
- service method wrapper
- message hub click path marks a reminder read before navigation
- reject reminder route goes to `pages/Product/MyPublishedProductsPage`

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for single reminder read flow.

- [ ] **Step 5: Checkpoint**

Record that reminder cards now behave like actionable tasks instead of static logs.

## Chunk 3: Conversation Detail Product Context

### Task 3: Add product summary card and richer conversation header

**Files:**
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Modify: `entry/src/main/ets/services/chat.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/product.repo.ets` (only if helper access is needed)

- [ ] **Step 1: Write the failing UI checklist**

```md
- chat detail shows product title
- chat detail shows product price
- chat detail shows location tag
- chat detail can still open even if product is unavailable
```

- [ ] **Step 2: Verify current implementation fails checklist**

Run: inspect `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
Expected: header exists, but no product summary card exists yet.

- [ ] **Step 3: Implement minimal product context card**

Add:
- product summary card under header
- product title / price / location / status
- fallback copy for unavailable product

- [ ] **Step 4: Re-check UI checklist**

Run: inspect `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
Expected: product summary card exists and uses current product state.

- [ ] **Step 5: Checkpoint**

Record that each conversation is now visibly tied to a specific campus item.

## Chunk 4: Quick Replies for Campus Transactions

### Task 4: Add campus-friendly quick reply chips

**Files:**
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Create: `entry/src/main/ets/constants/message-quick-replies.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing quick-reply test**

```ts
it('message_quick_replies_should_expose_campus_trade_phrases', 0, () => {
  // import replies
  // verify several expected campus-oriented phrases exist
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because no quick-reply constant exists.

- [ ] **Step 3: Implement minimal quick-reply support**

Add:
- a constant list of campus trade phrases
- chip buttons in chat detail
- chip tap fills and sends or fills input, whichever is simpler and clearer

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for quick-reply presence.

- [ ] **Step 5: Checkpoint**

Record that first-contact friction in chat has been reduced for campus trade scenarios.

## Chunk 5: Message Page States and Polishing

### Task 5: Refine message states and copy

**Files:**
- Modify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Modify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`

- [ ] **Step 1: Write the failing UI checklist**

```md
- login-empty state is not developer-facing
- reminder-empty state is concise and product-like
- conversation-empty state encourages contacting seller
- time and unread states are visually clear
```

- [ ] **Step 2: Review current implementation to verify gaps**

Run: inspect message hub files
Expected: some states exist, but copy and visual weight still need a second polish pass.

- [ ] **Step 3: Implement minimal polish**

Refine:
- titles and subtitles
- spacing between sections
- empty state copy
- unread badge visual weight

- [ ] **Step 4: Re-check UI checklist**

Run: inspect updated files
Expected: states read like a formal product, not a demo page.

- [ ] **Step 5: Checkpoint**

Record that the message center has moved from functional skeleton to polished product page.

## Chunk 6: Verification

### Task 6: Verify message-hub polish safely

**Files:**
- Verify: `entry/src/main/ets/pages/Chat/MessageHubPage.ets`
- Verify: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Verify: `entry/src/main/ets/constants/message-quick-replies.ets`
- Verify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run static inspection**

Run: `rg -n "未读|全部已读|联系卖家|快捷|审核中|ChatDetailPage|MessageHubPage" entry\\src\\main\\ets entry\\src\\test`
Expected: all polish-related references are present.

- [ ] **Step 2: Run available local verification**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for added unread and quick-reply tests.

- [ ] **Step 3: Manual runtime verification**

Verify in DevEco/emulator:
- message tab shows unread badge when there are unread reminders or incoming chat messages
- opening a reminder marks it read
- reject reminder routes to `我发布的`
- chat detail shows product summary card
- quick reply chips can be used to start a campus trade conversation
