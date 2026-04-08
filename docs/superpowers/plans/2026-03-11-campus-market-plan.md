# Campus Market Low-Cost Graduation Project Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the HarmonyOS campus market prototype so it supports a stable demo flow, basic admin management, and low-cost paper alignment without adding high-cost integrations.

**Architecture:** Keep the current page-service-repository-data layering, strengthen order/admin/persistence behavior inside existing modules, and align documentation to a prototype-oriented scope. Avoid backend services, third-party payment, and real distributed device integration.

**Tech Stack:** HarmonyOS ArkTS, Hypium unit tests, local repositories, lightweight device-side persistence

---

## Chunk 1: Persistence Foundation

### Task 1: Add persistent local database storage

**Files:**
- Create: `entry/src/main/ets/data/db/storage.ets`
- Modify: `entry/src/main/ets/data/db/local-db.ets`
- Modify: `entry/src/main/ets/data/db/schema.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing persistence test**

```ts
it('local_db_should_restore_saved_entities', 0, async () => {
  // Save products/orders into the persistent store, recreate db, verify restoration.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because no persistence adapter or restore path exists

- [ ] **Step 3: Write minimal persistence implementation**

```ts
export interface StorageAdapter {
  load(): PersistedState | null;
  save(state: PersistedState): void;
}
```

Add a lightweight storage adapter and call it whenever repository-backed state changes.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the new persistence scenario

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/data/db/storage.ets entry/src/main/ets/data/db/local-db.ets entry/src/main/ets/data/db/schema.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: persist local database state"
```

## Chunk 2: Order Flow Completion

### Task 2: Complete the demo-ready order detail flow

**Files:**
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/order.repo.ets`
- Modify: `entry/src/main/ets/constants/config.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests for payment, arrival, completion, and review flow**

```ts
it('order_service_should_complete_demo_trade_flow', 0, () => {
  // create -> pay -> both arrive -> complete -> review
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because one or more flow states or review constraints are not fully reflected in UI/service behavior

- [ ] **Step 3: Write minimal implementation**

```ts
if (order.status === OrderStatus.PENDING_PAYMENT) {
  // expose simulate pay action
}
if (order.status === OrderStatus.READY_HANDOVER) {
  // expose complete action
}
```

Expose clear actions in the order detail page and ensure service methods enforce the intended prototype flow.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the complete trade-flow test

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Order/OrderDetailPage.ets entry/src/main/ets/pages/Order/OrderListPage.ets entry/src/main/ets/services/order.service.impl.ets entry/src/main/ets/repositories/order.repo.ets entry/src/main/ets/constants/config.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: complete order demo flow"
```

## Chunk 3: Basic Admin Management

### Task 3: Fill in essential admin operations

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Modify: `entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets`
- Modify: `entry/src/main/ets/services/announcement.service.impl.ets`
- Modify: `entry/src/main/ets/repositories/announcement.repo.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests for admin announcement deletion and basic governance**

```ts
it('admin_features_should_support_announcement_delete_and_basic_governance', 0, () => {
  // publish announcement -> delete announcement -> verify hidden from list
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: FAIL because delete capability or governance behavior is missing

- [ ] **Step 3: Write minimal implementation**

```ts
deleteAnnouncement(announcementId: string, operatorId: string): OperationResult<Announcement> {
  // admin only soft delete
}
```

Keep admin features intentionally small: view stats, ban/unban users, off-shelf products, publish/delete announcements.

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw.bat --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets`
Expected: PASS for the new admin behavior test

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Admin/AdminDashboardPage.ets entry/src/main/ets/pages/Admin/AdminUsersPage.ets entry/src/main/ets/pages/Admin/AdminProductsPage.ets entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets entry/src/main/ets/services/announcement.service.impl.ets entry/src/main/ets/repositories/announcement.repo.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: complete basic admin management"
```

## Chunk 4: Paper Alignment

### Task 4: Add project documentation for thesis/report alignment

**Files:**
- Create: `docs/thesis-alignment.md`
- Modify: `docs/superpowers/specs/2026-03-11-campus-market-design.md`

- [ ] **Step 1: Write the documentation checklist**

```md
- payment -> simulated payment
- location -> campus location tags
- sync -> simulated collaboration flow
```

- [ ] **Step 2: Review current design doc against the checklist**

Run: `rg -n "支付|地图|定位|分布式|并发|可靠性" docs/superpowers/specs/2026-03-11-campus-market-design.md docs/thesis-alignment.md`
Expected: output only reflects prototype-level wording

- [ ] **Step 3: Write minimal alignment document**

```md
## Paper wording
The system uses simulated payment instead of third-party payment integration.
```

- [ ] **Step 4: Re-run the wording check**

Run: `rg -n "支付|地图|定位|分布式|并发|可靠性" docs/superpowers/specs/2026-03-11-campus-market-design.md docs/thesis-alignment.md`
Expected: wording stays aligned with the low-cost prototype scope

- [ ] **Step 5: Commit**

```bash
git add docs/thesis-alignment.md docs/superpowers/specs/2026-03-11-campus-market-design.md
git commit -m "docs: align thesis wording with prototype scope"
```

Plan complete and saved to `docs/superpowers/plans/2026-03-11-campus-market-plan.md`. Ready to execute?
