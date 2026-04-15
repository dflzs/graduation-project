# Order Remote Actions Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the current order remote-first slice so payment simulation, cancel, arrival, and completion also prefer backend APIs while preserving the existing local order state machine as fallback.

**Architecture:** Keep the current order page structure and guard semantics, but add remote action endpoints to the order client and let `OrderServiceImpl` hydrate returned remote order truth back into local repositories. When a valid session token is unavailable or a remote action fails, reuse the existing local transition logic and sync events so UI behavior stays stable.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing `@ohos.net.http` order remote client, Node backend `order.controller.js`, local repositories as compatibility cache.

---

## Chunk 1: Remote Action Contract

### Task 1: Extend remote order client with lifecycle actions

**Files:**
- Modify: `entry/src/main/ets/services/order-remote.client.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add focused tests proving the remote order client surface exposes:
- `simulatePay`
- `cancelOrder`
- `markArrived`
- `completeOrder`

Verify the fake client can drive service-layer remote-first behavior for these actions.

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'; $env:OHOS_BASE_SDK_HOME='D:\develop\DevEco Studio\sdk\default\openharmony'; & 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test --testFile=entry/src/test/LocalUnit.test.ets --analyze=normal --parallel --incremental --daemon
```

Expected: FAIL because remote action methods do not exist yet.

- [ ] **Step 3: Write minimal implementation**

Extend `RemoteOrderClient` with:
- `simulatePay(token, orderId)`
- `cancelOrder(token, orderId)`
- `markArrived(token, orderId)`
- `completeOrder(token, orderId)`

Use backend endpoints already present under `/api/orders/:id/...` and reuse the same order response mapping.

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command and confirm green.

## Chunk 2: Service-Layer Remote Actions

### Task 2: Route lifecycle actions through backend first

**Files:**
- Modify: `entry/src/main/ets/services/order.service.impl.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test**

Add tests proving:
- `simulatePay`, `cancelOrder`, `markArrived`, and `completeOrder` prefer remote actions when a valid token exists
- successful remote actions hydrate local order cache
- product lock/sold/on_sale cache changes and sync events remain consistent
- when remote actions fail, the current local state machine path still works

- [ ] **Step 2: Run test to verify it fails**

Run the unit test command and confirm failure is due to missing remote-first action wiring.

- [ ] **Step 3: Write minimal implementation**

Modify `OrderServiceImpl` so the four actions:
- reuse the current permission guards
- resolve a valid viewer token for active normal users
- call the remote client first when possible
- hydrate local order/product cache from returned remote order
- fall back to current local transition logic on remote failure

Update `OrderDetailPage` to await async action results without changing the page’s current empty-state or read-only semantics.

- [ ] **Step 4: Run test to verify it passes**

Run the same unit test command and confirm green.

## Chunk 3: Verification

### Task 3: Verify the remote action tranche

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
