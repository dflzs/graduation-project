# Admin And Home Polish Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring admin pages and the home feed into the same polished top-down product layout used across the improved app surfaces.

**Architecture:** Keep existing data flow and permissions intact while rewriting page composition and card hierarchy. Reuse shared empty/loading/error components where they already fit, and tighten the home feed card structure without changing product behavior.

**Tech Stack:** ArkTS, HarmonyOS ArkUI declarative UI, existing app context/services/repositories

---

## Chunk 1: Admin Surfaces

### Task 1: Rewrite Admin Dashboard Layout

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`

- [ ] Rebuild the page header into a left-aligned title and supporting description.
- [ ] Rework stat cards into a cleaner grid with consistent spacing and accents.
- [ ] Convert entry actions into product-style cards/buttons that visually match the rest of the app.

### Task 2: Rewrite Admin User Management Layout

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`

- [ ] Rebuild the page header and moderation list hierarchy.
- [ ] Promote identity and status information into clearer visual sections.
- [ ] Keep ban/restore behavior unchanged while improving action placement and card rhythm.

### Task 3: Rewrite Admin Product Review Layout

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`

- [ ] Rebuild the page header and review queue spacing.
- [ ] Upgrade product cards with stronger state, price, and metadata hierarchy.
- [ ] Keep approve/reject/off-shelf behavior intact with clearer grouped actions.

### Task 4: Rewrite Admin Announcement Layout

**Files:**
- Modify: `entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets`

- [ ] Split the page into a compose section and a published announcements section.
- [ ] Improve text input rhythm and list card readability.
- [ ] Keep publish/delete behavior unchanged.

## Chunk 2: Home Feed Cards

### Task 5: Polish Home Product Cards

**Files:**
- Modify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] Tighten product card spacing and scan order.
- [ ] Improve image, status, title, description, price, and location hierarchy.
- [ ] Keep the existing feed behavior and navigation intact.

## Chunk 3: Verification

### Task 6: ArkTS Sanity Pass

**Files:**
- Verify: `entry/src/main/ets/pages/Admin/AdminDashboardPage.ets`
- Verify: `entry/src/main/ets/pages/Admin/AdminUsersPage.ets`
- Verify: `entry/src/main/ets/pages/Admin/AdminProductsPage.ets`
- Verify: `entry/src/main/ets/pages/Admin/AdminAnnouncementPage.ets`
- Verify: `entry/src/main/ets/pages/Home/HomePage.ets`

- [ ] Check for invalid non-UI statements inside builders.
- [ ] Check for invalid container usage and layout mistakes that commonly break ArkTS compile.
- [ ] Hand off clear DevEco verification steps for visual review.
