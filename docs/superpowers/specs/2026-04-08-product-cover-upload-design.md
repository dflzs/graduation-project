# Product Cover Upload Design

**Goal**

Add a full single-image product cover upload flow so sellers can choose one image from the album, upload it to the cloud uploads directory, preview it before submission, and publish products with a real remote `cover_image` URL.

**Design Summary**

- Keep the existing product publishing API intact.
- Add a dedicated upload step before product creation.
- Treat image upload as a separate service boundary so product publishing stays simple and stable.
- Scope this pass to one product cover image only. No multi-image gallery, no cropping, no avatar upload in this change.

**Approach**

- Front-end publish flow becomes:
  1. Choose one image from album
  2. Show local preview in publish page
  3. On submit, upload the image first
  4. Receive remote URL
  5. Submit product using the existing `cover_image` field
- Back-end gets one upload endpoint for image files and stores them in the existing `/uploads` directory.

**Front-End**

- The publish page gets a dedicated cover section above the text form.
- That section supports:
  - choose image
  - replace image
  - remove image
  - preview state while waiting to publish
- Publish behavior:
  - if no image is chosen, keep existing behavior
  - if an image is chosen, upload first and block final publish until upload succeeds
- The returned remote URL is written into `RemoteCreateProductPayload.cover_image`.

**Service Boundaries**

- Product publishing remains in `product-remote.client.ets`.
- New upload behavior lives in a separate upload client, so file handling is not mixed into product business requests.
- The upload client returns a stable result shape:
  - `ok`
  - `message`
  - uploaded remote URL

**Back-End**

- Add `POST /api/upload/image`
- Accept one image file
- Save it into the existing uploads directory from `UPLOAD_DIR`
- Return a public path under `/uploads/...`
- Validate:
  - file exists
  - file is image-like
  - file size within a safe limit

**Display Impact**

- No extra page rewrites are required after upload support.
- Existing pages already consume `cover_image` by mapping it into `product.images`.
- Once uploaded products are created, homepage, detail page, order views, and “my published” naturally show the real image.

**Error Handling**

- Album selection canceled: no error toast, just stay on current preview state
- Upload failure: show toast and stop publish
- Publish failure after upload success: keep preview so the seller can retry without selecting again
- Missing login token: reuse existing login redirection

**Scope Limits**

- Single cover image only
- Album picker only, no camera
- No image editing/cropping/compression UI in this pass
- No avatar upload in this pass

**Verification Targets**

- Seller can select one local image
- Preview appears in publish page
- Submit uploads the file and then creates product successfully
- Returned product shows a real cover image in homepage and detail views
- Existing text-only publishing still works
