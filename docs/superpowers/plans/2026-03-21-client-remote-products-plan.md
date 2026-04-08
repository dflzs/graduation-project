# Client Remote Product Read Integration Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect the client home page and product detail page to the deployed backend product read endpoints.

**Architecture:** Add a small remote product read path that lives alongside the existing local product service. Home and detail pages will load remote data through a focused HTTP client and mapper, leaving local write-oriented flows unchanged for now.

**Tech Stack:** HarmonyOS ArkTS, deployed Node.js backend at `http://49.232.30.147`, existing client `Product` domain model

---

## Chunk 1: Remote Product Contract

### Task 1: Add remote product types

**Files:**
- Create: `entry/src/main/ets/types/product-remote.ets`

- [ ] **Step 1: Write the failing test**

Document the mismatch: current client product code only understands the local `Product` model and has no typed representation of backend product list/detail responses.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect project for `product-remote.ets`
Expected: file does not exist yet

- [ ] **Step 3: Write minimal implementation**

Create backend-aligned response and record types for:

- `RemoteProductItem`
- `RemoteProductListResponse`
- `RemoteProductDetailResponse`

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/types/product-remote.ets`
Expected: backend list/detail response types exist

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/types/product-remote.ets
git commit -m "feat: add remote product response types"
```

### Task 2: Add remote product client and mapper

**Files:**
- Create: `entry/src/main/ets/services/product-remote.client.ets`

- [ ] **Step 1: Write the failing test**

Document the current gap: there is no client code that can request `/api/products` or `/api/products/:id`.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect project for `product-remote.client.ets`
Expected: file does not exist yet

- [ ] **Step 3: Write minimal implementation**

Create a remote product client that:

- calls `GET /api/products`
- calls `GET /api/products/:id`
- maps backend items into the local `Product` model
- returns Chinese errors on fetch/parsing failure

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/services/product-remote.client.ets`
Expected: remote list/detail methods exist and map to `Product`

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/product-remote.client.ets
git commit -m "feat: add remote product client for list and detail"
```

## Chunk 2: Home Page Integration

### Task 3: Connect home page to remote products

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: home page still reads products through local in-memory data instead of the backend.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: page still loads products from local app context only

- [ ] **Step 3: Write minimal implementation**

Update home page to:

- load remote products on appear/show
- keep local keyword/category filtering on the fetched list
- show Chinese error toast on fetch failure
- show Chinese empty-state text when no products exist

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Home/HomePage.ets`
Expected: remote load path is present and local filtering applies to fetched products

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Home/HomePage.ets
git commit -m "feat: load home products from backend"
```

## Chunk 3: Product Detail Integration

### Task 4: Connect product detail page to remote product detail

**Files:**
- Modify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`

- [ ] **Step 1: Write the failing test**

Document the current issue: detail page still resolves the product only from the local product service.

- [ ] **Step 2: Run test to verify it fails**

Run: inspect `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: page still reads detail only from local service

- [ ] **Step 3: Write minimal implementation**

Update detail page to:

- fetch remote detail by route `productId`
- show a Chinese invalid/missing state when needed
- keep current rendering and buy/cart buttons for now

- [ ] **Step 4: Run test to verify it passes**

Run: inspect `entry/src/main/ets/pages/Product/ProductDetailPage.ets`
Expected: remote detail load path is present

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Product/ProductDetailPage.ets
git commit -m "feat: load product detail from backend"
```

## Chunk 4: Verification

### Task 5: Verify remote product browsing end to end

**Files:**
- Verify: `entry/src/main/ets/types/product-remote.ets`
- Verify: `entry/src/main/ets/services/product-remote.client.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Verify: `entry/src/main/ets/pages/Product/ProductDetailPage.ets`

- [ ] **Step 1: Run static inspection**

Run: inspect modified files
Expected: home/detail pages no longer depend solely on the local repository path

- [ ] **Step 2: Run build or preview verification**

Run the available HarmonyOS build/preview flow
Expected: no type errors caused by the remote product integration

- [ ] **Step 3: Verify runtime list loading**

Open the app home page after login.
Expected: server product list appears, including “二手机械键盘”

- [ ] **Step 4: Verify runtime detail loading**

Open the product detail page from the home list.
Expected: detail page shows the same remote product data

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/types/product-remote.ets entry/src/main/ets/services/product-remote.client.ets entry/src/main/ets/pages/Home/HomePage.ets entry/src/main/ets/pages/Product/ProductDetailPage.ets
git commit -m "feat: connect client product browsing to backend"
```
