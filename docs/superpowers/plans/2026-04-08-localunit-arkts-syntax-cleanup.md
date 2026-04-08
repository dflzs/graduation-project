# LocalUnit ArkTS Syntax Cleanup Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `entry/src/test/LocalUnit.test.ets` compile under `UnitTestArkTS` again without changing product behavior.

**Architecture:** Keep this cleanup narrowly scoped to test-only typing issues. Replace ArkTS-disallowed anonymous literals and intersection casts with explicit interfaces/types that already exist in the codebase, and add only the smallest missing test-local types where the production domain model already has a matching shape.

**Tech Stack:** ArkTS, hvigor, Hypium, HarmonyOS UnitTestArkTS

---

## Chunk 1: Reproduce And Type The Current Failures

### Task 1: Reproduce the current UnitTestArkTS errors

**Files:**
- Modify: `docs/superpowers/plans/2026-04-08-localunit-arkts-syntax-cleanup.md`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run the failing unit-test compile**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'
& 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test
```

Expected: `UnitTestArkTS` fails with the known syntax errors around lines `147`, `265`, `294`, `522`, `523`, and `531`.

- [ ] **Step 2: Map each failure to the owning type**

Inspect:

```text
entry/src/test/LocalUnit.test.ets
entry/src/main/ets/types/domain.ets
entry/src/main/ets/types/auth-remote.ets
```

Expected mapping:
- line `147`: anonymous remote auth user object needs an explicit return type
- lines `265`, `294`: intersection type casts should be replaced with `User`
- lines `522+`: cart-item array literal needs `CartItem[]`

## Chunk 2: Fix The Test File With Minimal Surface Area

### Task 2: Replace the anonymous remote auth user literal with an explicit type

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing test expectation**

Use the existing failing compile at line `147` as the red state. No new behavior test is needed because this task is compile-only.

- [ ] **Step 2: Add the explicit type and minimal imports**

Implement:
- import `RemoteAuthUser`
- change `buildRemoteUser(phone: string)` to return `RemoteAuthUser`

- [ ] **Step 3: Re-run test compile**

Run the same `hvigor ... test` command.

Expected: the line `147` error disappears while later errors remain.

### Task 3: Remove intersection-type casts from auth-session tests

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Keep the failing compile as the red state**

Expected current failures reference lines `265` and `294`.

- [ ] **Step 2: Replace intersection casts with the real domain type**

Implement:
- change `as User & Record<string, string>` to `as User`
- change `as User & Record<string, string | boolean>` to `as User`

Rationale:
- `remoteUserId` and `passwordConfigured` already exist on `User` as optional fields

- [ ] **Step 3: Re-run test compile**

Expected: intersection-type errors disappear.

### Task 4: Type the cart-item test literal explicitly

**Files:**
- Modify: `entry/src/test/LocalUnit.test.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Keep the failing compile as the red state**

Expected current failures reference line `522` and the two cart-item objects.

- [ ] **Step 2: Type the literal with the production domain model**

Implement:
- import `CartItem`
- change `const cartItems = [` to `const cartItems: CartItem[] = [`

- [ ] **Step 3: Re-run test compile**

Expected: array/object literal inference errors disappear.

## Chunk 3: Verify The Cleanup And Guard The Main Build

### Task 5: Verify unit-test compile and main app compile

**Files:**
- Modify: none
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Run unit-test compile again**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'
& 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default test
```

Expected: `UnitTestArkTS` succeeds or, if another historical failure remains, the original six syntax errors are gone.

- [ ] **Step 2: Run the normal app compile**

Run:

```powershell
$env:DEVECO_SDK_HOME='D:\develop\DevEco Studio\sdk'
& 'D:\develop\DevEco Studio\tools\node\node.exe' 'D:\develop\DevEco Studio\tools\hvigor\bin\hvigorw.js' --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

Expected: `BUILD SUCCESSFUL`

- [ ] **Step 3: Commit**

```bash
git add entry/src/test/LocalUnit.test.ets entry/src/main/ets/types/auth-remote.ets docs/superpowers/plans/2026-04-08-localunit-arkts-syntax-cleanup.md
git commit -m "test: fix LocalUnit ArkTS syntax errors"
```
