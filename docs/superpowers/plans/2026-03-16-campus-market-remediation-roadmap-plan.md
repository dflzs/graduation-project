# Campus Market Remediation Roadmap Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the current HarmonyOS campus market prototype into a stable, stateful, credible graduation-project platform with stronger persistence, authentication, transaction, governance, and HarmonyOS-oriented product quality.

**Architecture:** Keep the existing page-service-repository-data layering, but strengthen boundaries and introduce missing infrastructure pieces: persistence adapters, centralized validation, richer order policies, moderation hooks, and adaptive HarmonyOS-friendly interaction patterns. Improve in phases so demo usability remains intact while the framework becomes more defendable.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, Hypium unit tests, local repositories, lightweight client persistence, current remote auth API integration

---

## Chunk 1: Persistence and Session Stabilization

### Task 1: Introduce durable local persistence for business entities

**Files:**
- Create: `entry/src/main/ets/data/db/persistence-adapter.ets`
- Create: `entry/src/main/ets/data/db/persisted-state.ets`
- Modify: `entry/src/main/ets/data/db/local-db.ets`
- Modify: `entry/src/main/ets/repositories/user.repo.ets`
- Modify: `entry/src/main/ets/repositories/product.repo.ets`
- Modify: `entry/src/main/ets/repositories/order.repo.ets`
- Modify: `entry/src/main/ets/repositories/cart.repo.ets`
- Modify: `entry/src/main/ets/repositories/review.repo.ets`
- Modify: `entry/src/main/ets/repositories/announcement.repo.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing persistence test**

```ts
it('local_db_should_restore_saved_state_after_reinitialization', 0, () => {
  // save users/products/orders into the local db,
  // recreate or rehydrate the db instance,
  // assert state is restored instead of falling back to seed-only data.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because the current `local-db.ets` only stores in-memory arrays.

- [ ] **Step 3: Implement minimal persistence infrastructure**

Add:
- a persisted-state schema for users, products, cart items, orders, reviews, announcements, and chats
- a persistence adapter abstraction
- local DB load/flush hooks
- a safe fallback path when persisted data is unavailable

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for persistence restoration scenarios.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/data/db/persistence-adapter.ets entry/src/main/ets/data/db/persisted-state.ets entry/src/main/ets/data/db/local-db.ets entry/src/main/ets/repositories/*.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: persist local business state"
```

### Task 2: Make session restoration durable and explicit

**Files:**
- Modify: `entry/src/main/ets/services/auth-state.service.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing session restoration test**

```ts
it('auth_state_should_restore_login_after_process_restart', 0, async () => {
  // log in, persist session, create a fresh auth service instance,
  // assert restoreSession returns the correct user.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because `auth-state.service.ets` is currently process-memory-only.

- [ ] **Step 3: Implement minimal durable session restoration**

Add:
- auth snapshot serialization
- last-login restoration path
- session expiry validation against persisted snapshot
- logout cleanup for persisted session state

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for session restoration and logout cleanup.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/auth-state.service.ets entry/src/main/ets/services/auth.service.impl.ets entry/src/main/ets/app/app-context.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: persist and restore auth session"
```

## Chunk 2: Authentication Hardening

### Task 3: Centralize auth validation and remove weak validation duplication

**Files:**
- Modify: `entry/src/main/ets/utils/validator.ets`
- Create: `entry/src/main/ets/services/auth-policy.service.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/pages/Auth/PasswordLoginPage.ets`
- Modify: `entry/src/main/ets/pages/Auth/PhoneLoginStep1Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep1Page.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep3Page.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing validation tests**

```ts
it('auth_policy_should_reject_invalid_phone_prefixes_and_weak_passwords', 0, () => {
  // verify strict phone and password rules via a centralized policy entry point.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because validation is currently simplistic and partially duplicated in pages.

- [ ] **Step 3: Implement centralized auth policy**

Add:
- phone normalization
- stronger phone validation policy
- password strength rules suitable for a graduation project
- verification-code format validation
- page usage of service-level validation results instead of ad hoc page-only checks

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for auth validation cases.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/utils/validator.ets entry/src/main/ets/services/auth-policy.service.ets entry/src/main/ets/services/auth.service.impl.ets entry/src/main/ets/pages/Auth/*.ets entry/src/test/LocalUnit.test.ets
git commit -m "refactor: centralize auth validation rules"
```

### Task 4: Replace hard-coded admin shortcut with a safer admin strategy

**Files:**
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/services/guard.service.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/pages/Auth/LoginPage.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing admin-auth test**

```ts
it('admin_access_should_require_explicit_admin_identity_strategy', 0, () => {
  // verify the app no longer promotes arbitrary users via a plain hard-coded code path.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because admin promotion is currently available through `ADMIN_LOGIN_CODE`.

- [ ] **Step 3: Implement minimal safer admin strategy**

Options to implement in code:
- remove admin login from the user-facing auth page
- keep admin access only for seeded admin accounts
- ensure role assignment is not created dynamically from a public login screen

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS and no plain-code privilege escalation path remains.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/auth.service.impl.ets entry/src/main/ets/services/guard.service.ets entry/src/main/ets/types/service-contracts.ets entry/src/main/ets/pages/Auth/LoginPage.ets entry/src/test/LocalUnit.test.ets
git commit -m "refactor: remove public admin backdoor"
```

## Chunk 3: Product and Order Credibility

### Task 5: Strengthen product validation and status management

**Files:**
- Modify: `entry/src/main/ets/services/product.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/product.repo.ets`
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing product-rule test**

```ts
it('product_service_should_enforce_publish_rules_and_valid_status_changes', 0, () => {
  // verify title, description, price, and status rules.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because current product rules are too thin.

- [ ] **Step 3: Implement minimal product hardening**

Add:
- title length limits
- description length rules
- image-count checks
- allowed status transition constraints
- seller-only update protections
- optional admin off-shelf status handling

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for product publication and status scenarios.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/product.service.impl.ets entry/src/main/ets/repositories/product.repo.ets entry/src/main/ets/types/domain.ets entry/src/main/ets/pages/Product/*.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: harden product publishing and status rules"
```

### Task 6: Make order flow defensible for a real campus trading demo

**Files:**
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/services/order-state-machine.ets`
- Modify: `entry/src/main/ets/repositories/order.repo.ets`
- Modify: `entry/src/main/ets/repositories/product.repo.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing transaction-credibility tests**

```ts
it('order_service_should_prevent_multiple_active_purchases_for_one_sale_item', 0, () => {
  // create a first active order and verify a second conflicting order is blocked.
});

it('order_service_should_record_a_readable_transaction_timeline', 0, () => {
  // verify create/pay/arrive/complete generate timeline entries.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because reservation and order timeline support do not yet exist.

- [ ] **Step 3: Implement minimal order hardening**

Add:
- single active-order protection per sale item
- order event timeline storage
- stronger transition validation
- clearer order-detail UI action rendering

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for conflicting-order prevention and timeline scenarios.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/order.service.impl.ets entry/src/main/ets/services/order-state-machine.ets entry/src/main/ets/repositories/order.repo.ets entry/src/main/ets/repositories/product.repo.ets entry/src/main/ets/pages/Order/*.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: strengthen order credibility rules"
```

### Task 7: Deepen credit-system integration

**Files:**
- Modify: `entry/src/main/ets/services/credit.service.impl.ets`
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/types/domain.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing credit-event tests**

```ts
it('credit_service_should_apply_reward_and_penalty_events', 0, () => {
  // verify completed trades, cancellations, and violations affect credit in distinct ways.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because credit is not yet event-rich enough.

- [ ] **Step 3: Implement minimal event-based credit integration**

Add:
- typed credit events
- differentiated score adjustments
- trust level derivation
- profile-page presentation of trust level

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for trust event calculations.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/credit.service.impl.ets entry/src/main/ets/services/order.service.impl.ets entry/src/main/ets/types/domain.ets entry/src/main/ets/pages/Profile/ProfilePage.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: integrate event-based credit scoring"
```

## Chunk 4: Governance, Discovery, and Messaging

### Task 8: Complete meaningful admin governance

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets`
- Modify: `entry/src/main/ets/services/announcement.service.impl.ets`
- Modify: `entry/src/main/ets/services/guard.service.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing governance test**

```ts
it('admin_tools_should_support_user_governance_product_governance_and_announcement_governance', 0, () => {
  // verify admin-only management operations end-to-end in service logic.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because governance remains shallow.

- [ ] **Step 3: Implement minimal governance completion**

Add:
- stronger dashboard stats
- user ban reason handling
- product moderation flow
- announcement CRUD completion

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for the new governance behavior.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Admin/*.ets entry/src/main/ets/services/announcement.service.impl.ets entry/src/main/ets/services/guard.service.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: complete admin governance capabilities"
```

### Task 9: Expand search and discovery capabilities

**Files:**
- Modify: `entry/src/main/ets/repositories/product.repo.ets`
- Modify: `entry/src/main/ets/services/product.service.impl.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing search/discovery tests**

```ts
it('product_search_should_support_sorting_and_multi_dimension_filters', 0, () => {
  // verify category, price ordering, and freshness filtering.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because current discovery is keyword/category-only.

- [ ] **Step 3: Implement minimal discovery upgrade**

Add:
- sort mode
- optional price range
- freshness filter
- simple related-product recommendation on detail page

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for extended search/discovery scenarios.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/repositories/product.repo.ets entry/src/main/ets/services/product.service.impl.ets entry/src/main/ets/types/service-contracts.ets entry/src/main/ets/pages/Home/HomePage.ets entry/src/main/ets/pages/Product/ProductDetailPage.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: improve product search and discovery"
```

### Task 10: Introduce a minimal messaging and negotiation skeleton

**Files:**
- Create: `entry/src/main/ets/repositories/chat.repo.ets`
- Create: `entry/src/main/ets/services/chat.service.impl.ets`
- Create: `entry/src/main/ets/pages/Chat/ChatListPage.ets`
- Create: `entry/src/main/ets/pages/Chat/ChatDetailPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing messaging tests**

```ts
it('chat_service_should_create_product_bound_conversations_and_store_messages', 0, () => {
  // verify buyer and seller can exchange messages tied to a product.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: FAIL because chat is not yet a completed subsystem.

- [ ] **Step 3: Implement minimal messaging skeleton**

Add:
- conversation storage
- product-bound thread creation
- simple send/read flow
- product-detail entry point to contact seller

- [ ] **Step 4: Run tests to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test`
Expected: PASS for basic chat persistence and product binding.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/repositories/chat.repo.ets entry/src/main/ets/services/chat.service.impl.ets entry/src/main/ets/pages/Chat/*.ets entry/src/main/resources/base/profile/main_pages.json entry/src/main/ets/app/app-context.ets entry/src/main/ets/pages/Product/ProductDetailPage.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: add basic buyer seller messaging"
```

## Chunk 5: HarmonyOS Differentiation and UX Consolidation

### Task 11: Standardize reusable UX states and responsive layouts

**Files:**
- Create: `entry/src/main/ets/components/EmptyState.ets`
- Create: `entry/src/main/ets/components/LoadingState.ets`
- Create: `entry/src/main/ets/components/ErrorState.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`

- [ ] **Step 1: Write the UI acceptance checklist**

```md
- every list page has empty/loading/error states
- no repeated ad hoc placeholders
- larger layouts remain readable
```

- [ ] **Step 2: Review current pages against the checklist**

Run: `rg -n "Empty|Loading|Error|No data|暂无" entry/src/main/ets/pages`
Expected: scattered or missing state handling.

- [ ] **Step 3: Implement minimal reusable state components**

Add:
- shared empty/loading/error components
- consistent usage on key user and admin pages
- more stable layout spacing across major pages

- [ ] **Step 4: Re-check UI state usage**

Run: `rg -n "EmptyState|LoadingState|ErrorState" entry/src/main/ets/pages entry/src/main/ets/components`
Expected: shared components are now used across major list pages.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/components/*.ets entry/src/main/ets/pages/Home/HomePage.ets entry/src/main/ets/pages/Order/OrderListPage.ets entry/src/main/ets/pages/Profile/ProfilePage.ets entry/src/main/ets/pages/Admin/AdminDashboardPage.ets
git commit -m "feat: standardize UX state components"
```

### Task 12: Strengthen HarmonyOS-facing platform value inside the framework

**Files:**
- Modify: `entry/src/main/ets/services/sync.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Modify: `docs/superpowers/specs/2026-03-16-campus-market-remediation-roadmap-design.md`

- [ ] **Step 1: Write the platform-value checklist**

```md
- lifecycle-safe persistence
- event-driven refresh path
- adaptive multi-screen-ready structure
- no Android-only assumptions in flow design
```

- [ ] **Step 2: Review current implementation against the checklist**

Run: `rg -n "sync|dashboard|layout|screen|window|adaptive" entry/src/main/ets docs/superpowers/specs/2026-03-16-campus-market-remediation-roadmap-design.md`
Expected: limited or uneven HarmonyOS-oriented expression.

- [ ] **Step 3: Implement minimal framework-facing platform improvements**

Add:
- cleaner event-driven update points
- adaptive layout considerations on key pages
- documentation alignment for how HarmonyOS characteristics are embodied in the system design

- [ ] **Step 4: Re-run the checklist review**

Run: `rg -n "sync|adaptive|event-driven|multi-device|ArkUI" entry/src/main/ets docs/superpowers/specs/2026-03-16-campus-market-remediation-roadmap-design.md`
Expected: concrete platform-facing design hooks are visible.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/sync.service.impl.ets entry/src/main/ets/app/app-context.ets entry/src/main/ets/pages/Index.ets entry/src/main/ets/pages/Home/HomePage.ets docs/superpowers/specs/2026-03-16-campus-market-remediation-roadmap-design.md
git commit -m "feat: reflect HarmonyOS strengths in framework design"
```

Plan complete and saved to `docs/superpowers/plans/2026-03-16-campus-market-remediation-roadmap-plan.md`. Ready to execute?
