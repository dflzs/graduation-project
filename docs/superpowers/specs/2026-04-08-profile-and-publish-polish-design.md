# Profile And Publish Polish Design

## Goal

Polish the personal-profile page and publish-product page now that both avatar and cover-image flows are working, so they feel more like finished product pages and less like debug panels.

## Scope

- Rebalance the personal-profile page so avatar editing is the primary action and simulator-only URL testing is clearly secondary.
- Improve the publish-product page copy and section hierarchy so the main flow reads naturally in Chinese.
- Make pasted simulator URLs more forgiving by extracting the first valid `http(s)` URL from noisy pasted content.

## Non-Goals

- No backend contract changes.
- No new upload capabilities beyond the existing single-image flow.
- No navigation redesign beyond the already completed “我的 -> 个人资料” entry.

## Approach

### 1. Shared simulator URL cleanup

Both profile and publish pages already rely on `normalizeManualCoverUrl(...)`. We will make that helper more resilient:

- trim whitespace
- accept clean `http://` and `https://` URLs as before
- if extra terminal/debug text is pasted around a URL, extract the first valid `http(s)` URL instead of rejecting the whole input

This gives us a small regression target that protects both pages without adding UI-only tests.

### 2. Personal-profile page polish

The profile page already works, but the simulator debug input is too visually prominent. We will:

- keep the avatar card and nickname field as the primary content
- keep “从相册选择” as the main avatar action
- move draft-reset and simulator URL input into a softer “调试辅助” section
- keep one clear primary action: `保存资料`

The page should read like a real profile center first, and only secondarily expose simulator helpers.

### 3. Publish-product page polish

The publish page still contains awkward copy and a debug URL field mixed into the main flow. We will:

- restore concise, product-facing Chinese copy
- keep cover preview and album selection as the main path
- move the manual URL fallback into a clearly labeled simulator-only section
- tighten labels and helper text so the page reads more like a normal publish form

## Files

### Frontend

- Modify: `entry/src/main/ets/utils/cover-image.ets`
- Modify: `entry/src/test/LocalUnit.test.ets`
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Product/PublishProductPage.ets`

## Verification

- `normalizeManualCoverUrl(...)` accepts a noisy pasted string and extracts the first valid URL.
- Profile page still saves nickname/avatar successfully while the simulator URL area looks less like a debug panel.
- Publish page still supports album upload and simulator fallback, but the layout and copy are easier to understand.
- ArkTS compile remains successful.
