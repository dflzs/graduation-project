# Deprecated UIContext Cleanup Design

## Goal

Reduce the current ArkTS deprecated warnings by replacing global `router` and `promptAction` usage with `UIContext` router/prompt access, without changing page behavior.

## Why

- The current build is green, but warning output is noisy and makes real regressions harder to spot.
- Harmony has already deprecated the global navigation and toast APIs we use across the app.
- We now have enough product flow stability to do an engineering-quality cleanup pass without blocking feature work.

## Approach

Use a very small shared helper around `this.getUIContext()` so page code does not need to repeat the new ArkUI access pattern everywhere.

The helper should support:

- `pushUrl`
- `replaceUrl`
- `back`
- `getParams`
- `showToast`

This keeps migration edits mechanical and reduces the chance of one page using a slightly different pattern from another.

## Scope

Included in this round:

- Add one shared UIContext helper in `entry/src/main/ets/utils`
- Add focused unit tests for the helper with fake host/router/prompt objects
- Migrate the first batch of high-traffic pages and components
- Re-run compile verification and record the remaining warning surface

Excluded from this round:

- Capability warnings for `photoAccessHelper` and `fileIo`
- Any behavior redesign
- Non-warning refactors unrelated to navigation or toasts

## Migration Strategy

### Batch 1

Migrate the pages/components that are used most often in demos and that currently produce many warnings:

- auth login/register flow pages
- home and index shell
- profile and publish pages
- cart and order detail
- admin dashboard/products/announcement/users

### Batch 2

Follow with the remaining product/chat/order pages once the helper pattern is verified by compile output.

## Risk Management

- Navigation changes can silently alter page flow, so the helper must be thin and behavior-preserving.
- `getParams` and `back` should be replaced with direct `UIContext` router calls, not rewritten into a different navigation model.
- We should not mix this cleanup with API behavior changes or UI redesign in the same patch.

## Verification

- Add helper-focused unit tests in `LocalUnit.test.ets`
- Run `hvigor test`
- Run `assembleHap`
- Compare warning count before and after the first migration batch
