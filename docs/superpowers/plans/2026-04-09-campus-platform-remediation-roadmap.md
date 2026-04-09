# Campus Platform Remediation Roadmap Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the current HarmonyOS campus marketplace prototype into a more mature campus second-hand platform through phased, low-risk remediation work.

**Architecture:** Work in vertical slices instead of scattered page edits. Each phase should complete one trust-bearing platform capability end-to-end across domain model, client flow, backend support, and admin/governance touchpoints. Keep payment simulated, but push all other core behaviors toward a platform-consistent model.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, current Node backend under `backend_code`, existing local repositories and remote clients, DevEco runtime verification.

---

## Phase 0: Baseline Guardrails

**Files:**
- Reference: `docs/superpowers/specs/2026-04-09-campus-platform-gap-analysis-design.md`
- Modify later as needed: `entry/src/test/LocalUnit.test.ets`
- Modify later as needed: `docs/thesis-alignment.md`

- [ ] Confirm the current baseline build still succeeds in DevEco before each new phase.
- [ ] Keep simulated payment, non-map handover, and non-commercial quality targets unchanged unless explicitly re-scoped.
- [ ] Treat each phase below as its own implementation project with its own spec and plan.

## Phase 1: Identity And Campus Location Foundations

**Target outcome:** The platform can express who a student is and where a campus transaction belongs.

- [ ] Extend the domain model to support school, campus, verification status, and structured location entities.
- [ ] Add backend contracts and client contracts for identity/profile completion fields.
- [ ] Replace fixed transaction location tags with school-aware location configuration.
- [ ] Update publish, profile, and order flows to consume the new location model.
- [ ] Add visible trust markers in the UI for campus verification and campus affiliation.
- [ ] Verify that old data can still render gracefully during migration.

## Phase 2: Remote-First Core Transaction Data

**Target outcome:** Orders, chat, announcements, and admin governance stop behaving like local prototype data.

- [ ] Move order creation, payment simulation, cancel, arrival, completion, and review persistence to backend APIs.
- [ ] Move chat thread/message state to backend APIs and align unread handling with server truth.
- [ ] Move announcement CRUD and admin user governance to backend-backed flows.
- [ ] Convert client pages that still depend on local repositories to remote-backed services with cache fallback only where needed.
- [ ] Add regression coverage for refresh timing, ownership checks, and status transitions after the remote shift.

## Phase 3: Report, Complaint, And Appeal Minimum Loop

**Target outcome:** The platform can handle abnormal behavior instead of only ideal-path trades.

- [ ] Define report types for product, user, chat, and order.
- [ ] Add client entry points for report/complaint actions in the relevant pages.
- [ ] Add backend persistence and admin review endpoints for submitted reports.
- [ ] Add minimal appeal records for banned users or disputed moderation outcomes.
- [ ] Surface moderation outcome notifications back to affected users.

## Phase 4: Stronger Campus Trade Flow

**Target outcome:** The transaction flow feels designed for students, not just generic CRUD.

- [ ] Expand order state modeling to cover more realistic campus trade transitions.
- [ ] Add structured handover scheduling hints or fields beyond free-text notes.
- [ ] Add campus safety prompts based on category and transaction stage.
- [ ] Improve chat with trade-specific helper actions, report/block entry points, and order association clarity.

## Phase 5: Listing Quality And Buyer Decision Support

**Target outcome:** Product listings become more trustworthy and easier to compare.

- [ ] Add richer listing fields such as condition, accessory completeness, negotiability, and category-specific metadata.
- [ ] Support stronger media presentation for products.
- [ ] Add buyer support features such as favorites, history, or seller inventory follow-through as needed.
- [ ] Improve filters and discovery around campus-relevant categories and locations.

## Phase 6: Governance And Trust System Deepening

**Target outcome:** User trust becomes explainable and enforceable across the platform.

- [ ] Expand user governance states beyond simple active/banned.
- [ ] Connect reputation or credit signals more clearly to completed platform behavior.
- [ ] Add visible history or summaries that help students judge counterpart reliability.
- [ ] Add admin logs or moderation traceability where appropriate.

## Phase 7: Brand And Productization Pass

**Target outcome:** The app looks and behaves like a product instead of a strong prototype.

- [ ] Design and integrate a real application icon.
- [ ] Replace placeholder package metadata, vendor values, and generic app naming.
- [ ] Remove or hide development-only shortcuts such as admin quick login.
- [ ] Continue the UI polish pass page by page until major flows share one visual language.
- [ ] Add help, safety, rule, or about pages that complete the product surface.

## Recommended Execution Order

- [ ] First implementation tranche: Phase 1 + the order/chat portion of Phase 2.
- [ ] Second tranche: finish Phase 2, then Phase 3.
- [ ] Third tranche: Phase 4 and Phase 5.
- [ ] Fourth tranche: Phase 6 and Phase 7.

## Manual Verification Checklist For Each Future Tranche

- [ ] DevEco `assembleHap` still succeeds.
- [ ] Existing happy-path trade flow still works end to end.
- [ ] Ownership, unread, and status refresh protections still work.
- [ ] New capability is visible in UI and not only present in backend or local model.
- [ ] The change increases platform credibility rather than just adding surface complexity.

Plan complete and saved to `docs/superpowers/plans/2026-04-09-campus-platform-remediation-roadmap.md`. Ready to execute tranche 1 when you are.
