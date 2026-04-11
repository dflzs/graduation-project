# Identity And Campus Foundation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a full campus identity, school/campus, and trade-location foundation so the project behaves like a mature campus second-hand platform instead of a phone-account prototype.

**Architecture:** Introduce complete domain entities for campus identity and structured trade locations first, then connect backend, admin, and frontend in dependency order. Keep legacy data display-compatible while forcing new writes onto the new model.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, current Node backend under `backend_code`, existing local repositories and remote clients, DevEco runtime verification.

---

## Chunk 1: Domain And Contract Foundation

### Task 1: Expand client-side domain types

**Files:**
- Modify: `entry/src/main/ets/types/domain.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests for the new identity and location enums/interfaces**

Add or extend tests in `entry/src/test/LocalUnit.test.ets` to assert the presence and expected value space for:

- `VerificationStatus`
- `VerificationMethod`
- `School`
- `Campus`
- `LocationGroup`
- `TradeLocation`
- `StudentVerification`

- [ ] **Step 2: Run the narrowest available local verification**

Run a targeted local inspection or available test command for the changed test block.  
Expected: the new references fail because the types do not exist yet.

- [ ] **Step 3: Add complete client-side types**

Update `entry/src/main/ets/types/domain.ets` so it includes:

- expanded `User` fields for school, campus, student, verification, and trust summary
- `VerificationStatus` enum or string union
- `VerificationMethod` union
- `School`
- `Campus`
- `LocationGroup`
- `TradeLocation`
- `StudentVerification`

- [ ] **Step 4: Re-run the narrowest local verification**

Expected: type references now resolve.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/types/domain.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: add campus identity domain types"
```

### Task 2: Define backend contract targets and compatibility shape

**Files:**
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/types/product-remote.ets`
- Create: `entry/src/main/ets/types/campus-remote.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests or structural assertions for remote DTO coverage**

Add checks or contract assertions that the client can represent:

- school/campus payloads
- trade location payloads
- verification summary payloads
- profile completion payloads

- [ ] **Step 2: Run verification for contract references**

Expected: fail on missing DTOs or service contract fields.

- [ ] **Step 3: Add complete remote-facing DTOs**

Create `entry/src/main/ets/types/campus-remote.ets` and update existing remote contract files so they can carry:

- school list
- campus list by school
- location group list
- trade location list
- verification request payloads
- verification review payloads
- expanded remote user profile payloads

- [ ] **Step 4: Re-run local verification**

Expected: contract references resolve.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/types/service-contracts.ets entry/src/main/ets/types/auth-remote.ets entry/src/main/ets/types/product-remote.ets entry/src/main/ets/types/campus-remote.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: add campus foundation remote contracts"
```

## Chunk 2: Backend Foundation

### Task 3: Add backend campus and verification storage models

**Files:**
- Modify: `backend_code/auth.controller.js`
- Create: `backend_code/campus.controller.js`
- Create: `backend_code/campus.routes.js`
- Create or Modify: backend-side storage modules for schools, campuses, locations, and verifications under `backend_code`
- Test: syntax verification in `backend_code`

- [ ] **Step 1: Write down the exact backend data responsibilities**

Document in code comments or module boundaries which file owns:

- schools
- campuses
- location groups
- trade locations
- student verification submissions
- verification review actions

- [ ] **Step 2: Run syntax verification to establish baseline**

Run a narrow Node syntax check against the target backend files that already exist.  
Expected: baseline passes before modifications.

- [ ] **Step 3: Implement campus and verification persistence**

Add backend-side data access modules that can:

- list schools
- list campuses by school
- list groups and locations by campus
- create and update trade locations
- create verification applications
- review verification applications
- expose verification summaries for the current user

- [ ] **Step 4: Add campus and verification routes**

Wire new routes so the client can:

- fetch schools/campuses/locations
- submit verification
- fetch current verification state
- admin list and review verification applications
- admin manage schools/campuses/locations

- [ ] **Step 5: Re-run backend syntax verification**

Expected: no syntax errors in edited backend files.

- [ ] **Step 6: Commit**

```bash
git add backend_code
git commit -m "feat: add campus identity backend foundation"
```

## Chunk 3: Client Services And App Context

### Task 4: Add client services for campus data and verification flows

**Files:**
- Create: `entry/src/main/ets/services/campus-remote.client.ets`
- Create: `entry/src/main/ets/services/campus.service.impl.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/main/ets/constants/config.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests for client service availability**

Add tests or assertions that `appContext` can surface a campus/verification service and that the service contract exposes:

- school list loading
- campus list loading
- trade location loading
- submit verification
- review verification

- [ ] **Step 2: Run the narrowest available verification**

Expected: fail because campus client/service does not exist.

- [ ] **Step 3: Implement remote client and service layer**

Add:

- `campus-remote.client.ets` for raw HTTP calls
- `campus.service.impl.ets` for app-facing operations and compatibility mapping

Update `app-context.ets` so the rest of the app can consume the new service cleanly.

- [ ] **Step 4: Remove reliance on hard-coded campus locations where appropriate**

Keep compatibility constants only if needed for fallback, but move the platform source of truth to the new service.

- [ ] **Step 5: Re-run local verification**

Expected: service references resolve.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/services entry/src/main/ets/app/app-context.ets entry/src/main/ets/constants/config.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: add campus foundation client services"
```

## Chunk 4: Admin Configuration And Review Surfaces

### Task 5: Build admin verification review page

**Files:**
- Create: `entry/src/main/ets/pages/Admin/AdminVerificationPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: any admin navigation entry file that should expose the page
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the failing route/navigation expectation**

Add a narrow assertion or documented manual verification target that the admin area now includes a verification review entry point.

- [ ] **Step 2: Build the page**

Implement a page that supports:

- pending review list
- approved list
- rejected list
- application detail view
- approve / reject actions
- reject reason entry

- [ ] **Step 3: Verify the page compiles**

Use the narrowest available local verification or defer final validation to DevEco if local shell validation cannot compile ArkTS pages.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/pages/Admin/AdminVerificationPage.ets entry/src/main/resources/base/profile/main_pages.json entry/src/test/LocalUnit.test.ets
git commit -m "feat: add admin verification review page"
```

### Task 6: Build admin school/campus/location management pages

**Files:**
- Create: `entry/src/main/ets/pages/Admin/AdminCampusConfigPage.ets`
- Create additional helper files if needed under `entry/src/main/ets/utils` or `entry/src/main/ets/components`
- Modify: admin navigation exposure files
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the expected admin scope**

Record the page responsibilities:

- school list
- campus list
- location group list
- trade location list
- enable/disable
- ordering
- safety tip editing

- [ ] **Step 2: Implement the page and any focused helpers**

Keep files small and responsibility-based.  
Do not collapse all configuration UI into one giant file if helpers improve clarity.

- [ ] **Step 3: Verify references and compile surface**

Expected: page compiles or is ready for DevEco validation.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/pages/Admin entry/src/test/LocalUnit.test.ets
git commit -m "feat: add admin campus configuration pages"
```

## Chunk 5: Frontend Identity And Trade Flow Integration

### Task 7: Upgrade profile and verification submission flow

**Files:**
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Auth/RegisterStep*.ets` or current active registration pages as appropriate
- Modify: `entry/src/main/ets/pages/Auth/RegisterVerifyPage.ets`
- Create helpers/components as needed
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write the user-facing state matrix**

List what the profile page should show for:

- unverified user
- pending review user
- verified user
- rejected user
- suspended user

- [ ] **Step 2: Implement verification-aware profile UI**

Add:

- school and campus display
- verification badge
- submit or resubmit verification entry
- reject reason display

- [ ] **Step 3: Integrate registration/profile completion**

Ensure registration and profile completion can collect:

- school
- campus
- student number
- grade year
- college / major
- material submission metadata

- [ ] **Step 4: Re-run verification**

Expected: flows compile and the user state matrix can be manually tested.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Profile/ProfilePage.ets entry/src/main/ets/pages/Auth entry/src/test/LocalUnit.test.ets
git commit -m "feat: add campus verification profile flow"
```

### Task 8: Replace publish and order location handling with structured campus locations

**Files:**
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `entry/src/main/ets/pages/Order/CreateOrderPage.ets`
- Modify: `entry/src/main/ets/pages/Order/OrderDetailPage.ets`
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
- Modify any affected service or utility files
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] **Step 1: Write failing tests or assertions for location compatibility helpers**

Add checks for:

- mapping old `locationTag` to a structured location summary
- choosing valid locations for the current user’s campus
- preventing disabled locations from being used for new writes

- [ ] **Step 2: Replace publish page location source**

The publish page must stop reading from `CAMPUS_LOCATIONS` as its primary source and instead use campus-configured trade locations.

- [ ] **Step 3: Replace order entry and display handling**

The order creation and order detail flows must consume the new location model while remaining able to display legacy text for older orders.

- [ ] **Step 4: Add seller trust markers to product detail**

Expose:

- school name
- campus name
- verification status
- completed order count
- credit summary

- [ ] **Step 5: Re-run verification**

Expected: new location flow works and old data remains display-compatible.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/pages/Product/PublishProductPage.ets entry/src/main/ets/pages/Order/CreateOrderPage.ets entry/src/main/ets/pages/Order/OrderDetailPage.ets entry/src/main/ets/pages/Product/ProductDetailPage.ets entry/src/test/LocalUnit.test.ets
git commit -m "feat: integrate campus locations into trade flow"
```

## Chunk 6: Verification And Handoff

### Task 9: End-to-end verification and cleanup

**Files:**
- Review only: all files touched in this plan

- [ ] **Step 1: Run the narrowest available local verification**

Run any available unit or syntax checks for touched utility and service files.  
If ArkTS page compilation is not available in shell, document that clearly.

- [ ] **Step 2: Run DevEco build verification**

Use DevEco `assembleHap` and confirm:

- no new compile errors
- registration/profile flows open
- admin verification and campus configuration pages open
- publish page uses structured campus locations
- order page displays structured location info

- [ ] **Step 3: Manual scenario verification**

Verify at least:

- new user sees unverified state
- verification submission works
- admin can review an application
- verified identity appears on product detail
- new trade uses configured campus locations

- [ ] **Step 4: Commit final integration**

```bash
git add .
git commit -m "feat: add campus identity and location foundation"
```

Plan complete and saved to `docs/superpowers/plans/2026-04-09-identity-campus-foundation-plan.md`. Ready to execute.
