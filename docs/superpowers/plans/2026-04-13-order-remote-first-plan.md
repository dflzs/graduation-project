# Order Remote-First Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the order flow off local-only repositories for the first vertical slice by making order creation, list, and detail read/write go through backend APIs with safe local fallback.

**Architecture:** Keep the current ArkTS service contract stable for pages, but insert a dedicated remote client and remote DTO mapping layer for orders. In this first slice, the frontend should prefer backend order truth for create/list/detail while preserving existing local state transitions and sync semantics as fallback so current pages do not break if the remote path is unavailable.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing `@ohos.net.http` remote client pattern, Node backend controller under `backend_code/order.controller.js`, local repositories as compatibility cache.

---

## Chunk 1: Remote Contract Foundation

### Task 1: Add remote order types and client

**Files:**
- Create: `entry/src/main/ets/types/order-remote.ets`
- Create: `entry/src/main/ets/services/order-remote.client.ets`
- Modify: `entry/src/main/ets/constants/config.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add a focused test covering remote order status mapping and payload parsing. Verify backend statuses such as `pending_payment`, `paid`, `ready_handover`, `completed`, and `canceled` convert to the local `OrderStatus` enum and preserve buyer/seller/product identifiers and arrival flags.

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets --analyze=normal --parallel --incremental --daemon
```

Expected: FAIL because the order remote mapping/client does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create:
- `entry/src/main/ets/types/order-remote.ets`
  Define remote response DTOs for order list/detail/create and remote order item shape.
- `entry/src/main/ets/services/order-remote.client.ets`
  Follow the pattern used by `product-remote.client.ets` and `campus-remote.client.ets`.
  Implement:
  - `mapRemoteOrderItem`
  - `createOrder`
  - `listMyOrders`
  - `getOrderDetail`

Keep only the minimum endpoints for this slice:
- `POST /api/orders`
- `GET /api/orders`
- `GET /api/orders/:id`

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command and confirm the new mapping test passes.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/types/order-remote.ets entry/src/main/ets/services/order-remote.client.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: add order remote client foundation"
```

## Chunk 2: Service-Layer Remote Create/List/Detail

### Task 2: Route order creation through backend first

**Files:**
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/services/auth-state.service.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add tests proving:
- order service prefers remote create when a logged-in session token exists
- remote create result is mapped back to local `Order`
- local repository/cache is updated from remote result so current pages still render
- on remote failure, service falls back to current local implementation

Use a fake remote order client injected into `OrderServiceImpl`.

- [ ] **Step 2: Run test to verify it fails**

Run the unit test command and confirm failure is due to missing remote-first logic.

- [ ] **Step 3: Write minimal implementation**

Modify `OrderServiceImpl` so:
- it can receive `RemoteOrderClient` and `AuthStateService`
- `createOrder` checks current token/session
- when token exists, it calls remote create first
- successful remote result is normalized into the local cache and existing sync events still publish
- if remote create is unavailable or fails, existing local implementation remains as fallback

Do not change page signatures in this step.

- [ ] **Step 4: Run test to verify it passes**

Run the unit test command and confirm green.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/order.service.impl.ets entry/src/main/ets/types/service-contracts.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: route order creation through remote-first service"
```

### Task 3: Route order list/detail reads through backend first

**Files:**
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderListPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add tests proving:
- order list refresh can hydrate local cache from remote list data
- order detail refresh can hydrate local cache from remote detail data
- pages keep their current guards and empty-state behavior after hydration

- [ ] **Step 2: Run test to verify it fails**

Run the unit test command and confirm the new read-path expectations fail before implementation.

- [ ] **Step 3: Write minimal implementation**

Extend the order service with remote-first read helpers for:
- `listMyOrders`
- `getOrderDetail`

Wire page refresh paths so:
- signed-in users with tokens attempt remote hydration
- successful hydration updates local repository and existing `orders:changed` driven UI
- failures gracefully retain current local render behavior

Do not remote-first payment/cancel/arrive/complete/review yet.

- [ ] **Step 4: Run test to verify it passes**

Run the unit test command and confirm green.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/order.service.impl.ets entry/src/main/ets/pages/Order/OrderListPage.ets entry/src/main/ets/pages/Order/OrderDetailPage.ets entry/src/main/ets/app/app-context.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: hydrate order list and detail from backend first"
```

## Chunk 3: Verification

### Task 4: Full tranche verification

**Files:**
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run focused unit tests**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets --analyze=normal --parallel --incremental --daemon
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 2: Run package build**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/types/order-remote.ets entry/src/main/ets/services/order-remote.client.ets entry/src/main/ets/services/order.service.impl.ets entry/src/main/ets/pages/Order/OrderListPage.ets entry/src/main/ets/pages/Order/OrderDetailPage.ets entry/src/main/ets/app/app-context.ets entry/src/test/LocalUnit.test.ets docs/superpowers/plans/2026-04-13-order-remote-first-plan.md
git commit -m "feat: add first remote-first order slice"
```

Plan complete and saved to `docs/superpowers/plans/2026-04-13-order-remote-first-plan.md`. Ready to execute.
