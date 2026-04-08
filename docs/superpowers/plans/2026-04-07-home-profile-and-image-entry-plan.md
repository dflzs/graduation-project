# Home Profile And Image Entry Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the home grid visually consistent, upgrade the profile page into a more polished account surface, and prepare image-related fields and UI affordances for the next upload pass.

**Architecture:** Keep the existing business logic intact while rewriting page composition and visual hierarchy. Reuse the current data flow and only prepare image display fields rather than attempting a risky native picker integration in the same pass.

**Tech Stack:** ArkTS, HarmonyOS ArkUI, existing app context/repository/service layer

---

## Chunk 1: Home Feed Card Consistency

### Task 1: Normalize product card height and internal layout

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] Normalize image, title, description, and footer sections to fixed rhythm.
- [ ] Keep the two-column feed but remove uneven card height.
- [ ] Rebuild the footer into a two-row commerce layout so price, trade context, and detail affordance no longer collide.
- [ ] Preserve navigation and feed filtering behavior.

## Chunk 2: Profile Page Redesign

### Task 2: Replace the button-grid profile layout

**Files:**
- Modify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Modify: `entry/src/main/ets/types/domain.ets`

- [ ] Rebuild the profile page into account summary plus grouped entry cards.
- [ ] Add avatar-ready user structure so future upload/display work has a stable field.
- [ ] Keep existing navigation targets and logout behavior.

## Chunk 3: Verification

### Task 3: ArkTS sanity pass

**Files:**
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`
- Verify: `entry/src/main/ets/pages/Profile/ProfilePage.ets`
- Verify: `entry/src/main/ets/types/domain.ets`

- [ ] Check builders for illegal non-UI statements.
- [ ] Check row/column spacing and fixed-height constraints for layout regressions.
- [ ] Hand off the exact DevEco screens to verify visually.
