# Avatar Upload And Publish Copy Design

## Goal

Keep the newly completed product-cover flow stable, restore the publish page from temporary English copy back to product-ready Chinese copy, and add a minimal but complete avatar upload flow for the current user.

## Scope

- Restore Chinese copy in the publish-product page without changing the working cover-upload logic.
- Reuse the existing `/api/upload/image` file-upload endpoint for avatar files.
- Add a current-user profile update endpoint that updates `avatar`.
- Update the local session and user repository after avatar update so the "我的" page refreshes immediately.
- Add the avatar upload entry to the bottom-tab "我的" page in `Index.ets`.
- Keep a simulator-friendly URL fallback for avatar testing, similar to product-cover testing.

## Non-Goals

- No multi-image avatar gallery.
- No image cropping.
- No camera capture flow.
- No redesign of chat, product detail, or admin user list around avatars in this step.

## Approach

### 1. Publish page copy restoration

`PublishProductPage.ets` already has stable upload logic. We will only replace temporary English labels with concise Chinese copy and preserve:

- local album selection
- local cache copy
- remote upload
- simulator URL fallback
- publish-before-review flow

This keeps the most fragile part of the current implementation untouched.

### 2. Avatar upload flow

We will reuse the existing upload transport and split the rest into two responsibilities:

- upload service: returns a usable image URL
- auth/profile update: persists that URL as the current user's avatar

On the frontend, avatar upload will follow this order:

1. Select local image or paste simulator URL
2. If local image exists, upload it first
3. Call current-user update endpoint with the avatar URL
4. Merge returned user into local repository and persisted session
5. Refresh the "我的" tab immediately

### 3. Backend current-user update

The backend already exposes `GET /api/auth/me`. We will add a small authenticated update endpoint in the same auth area:

- `PUT /api/auth/me`

For now it only needs to support:

- `avatar`

This keeps the change small and aligned with the existing auth controller and route structure.

## Data Flow

### Publish page

- UI state updates preview URI
- local file path uploads through `upload-remote.client.ets`
- returned URL goes into `RemoteCreateProductPayload.cover_image`

### Avatar page flow

- UI state updates preview URI in the "我的" tab
- local file path uploads through the same upload client
- returned URL is sent to `PUT /api/auth/me`
- remote user response is merged into local state
- `authStateService.saveSession(...)` persists the updated user

## Files

### Frontend

- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/services/auth-remote.client.ets`
- Modify: `entry/src/main/ets/services/auth.service.impl.ets`
- Modify: `entry/src/main/ets/types/auth-remote.ets`
- Modify: `entry/src/main/ets/types/service-contracts.ets`
- Modify: `entry/src/main/ets/repositories/user.repo.ets`
- Modify: `entry/src/main/ets/app/app-context.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`

### Backend reference files

- Modify: `backend_code/auth.controller.js`
- Modify: `backend_code/auth.routes.js`

## Error Handling

- If upload fails, keep the current preview and show a short toast.
- If avatar update fails after upload, show the backend message and keep the old persisted user untouched.
- If simulator URL is invalid, treat it as empty and do not submit it.
- If the user is not logged in, route to login instead of attempting upload or update.

## Verification

- Product publish page still compiles and shows Chinese copy.
- Product cover upload still works with both album and simulator URL fallback.
- Avatar can be updated from the "我的" page.
- New avatar persists after leaving and reopening the app.
- Existing login/register flows remain unchanged.
