# Product Cover Upload Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real single-image product cover upload flow that uploads one album-selected image to the cloud uploads directory and then publishes the product with the resulting remote image URL.

**Architecture:** Keep product publishing and file uploading as separate service boundaries. The front-end publish page first obtains a local image URI, then uploads it through a dedicated upload client, then submits the existing create-product payload with `cover_image` populated. The back-end exposes a dedicated image-upload endpoint that stores the file in `UPLOAD_DIR` and returns a public `/uploads/...` path.

**Tech Stack:** ArkTS, HarmonyOS ArkUI, existing remote product client, Node.js/Express back-end reference code, existing `/uploads` static file directory

---

## Chunk 1: Upload Contract

### Task 1: Define the upload response contract and front-end client boundary

**Files:**
- Create: `entry/src/main/ets/types/upload-remote.ets`
- Create: `entry/src/main/ets/services/upload-remote.client.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] Add upload result types with explicit ArkTS-friendly classes/interfaces.
- [ ] Add a dedicated upload client that accepts a local image URI and returns an uploaded remote URL.
- [ ] Add at least one unit-level contract test or helper test for upload response mapping.

## Chunk 2: Publish Page Integration

### Task 2: Add album selection, preview, and upload-before-publish flow

**Files:**
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `entry/src/main/ets/types/product-remote.ets`
- Test: `entry/src/test/LocalUnit.test.ets`

- [ ] Add single-image cover state to the publish page.
- [ ] Add a visible cover section with choose/replace/remove actions.
- [ ] On submit, upload the chosen image first and only then call create-product with `cover_image`.
- [ ] Keep existing text-only publish flow working when no image is selected.
- [ ] Add test coverage for payload creation that includes `cover_image`.

## Chunk 3: Back-End Reference Upload Endpoint

### Task 3: Add image upload endpoint to local reference back-end code

**Files:**
- Create: `backend_code/upload.controller.js`
- Create: `backend_code/upload.routes.js`
- Modify: `backend_code/云服务器后端代码.md`
- Test/Verify: `backend_code/upload.controller.js`

- [ ] Add one upload endpoint that stores image files in `UPLOAD_DIR`.
- [ ] Return a stable remote path under `/uploads/...`.
- [ ] Document the exact cloud sync commands and route wiring for the deployed server.
- [ ] Run `node -c` validation on any changed Node files.

## Chunk 4: Verification

### Task 4: Static verification and handoff

**Files:**
- Verify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Verify: `entry/src/main/ets/services/upload-remote.client.ets`
- Verify: `backend_code/upload.controller.js`
- Verify: `backend_code/upload.routes.js`

- [ ] Verify ArkTS builders contain only valid UI syntax.
- [ ] Verify upload flow preserves existing publish behavior when no image is chosen.
- [ ] Verify Node reference files pass `node -c`.
- [ ] Hand off exact DevEco and cloud sync validation steps.
