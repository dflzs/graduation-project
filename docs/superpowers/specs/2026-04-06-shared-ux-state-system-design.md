# Shared UX State System Design

## Goal

Standardize empty, loading, and error states across the campus marketplace so key pages feel like one coherent product instead of separate feature screens.

## Why This Matters

The project now has real product flows:

- login and registration
- publish and review
- cart and order flow
- message hub and chat

At this stage, inconsistent page states stand out more sharply than before. Some pages already have empty text, some have ad hoc loading copy, and some surface errors inline without a consistent pattern. For a graduation project, this is a high-leverage polish area because it improves every demo path at once.

## Recommended Approach

Build three reusable ArkUI components and wire them into the highest-value pages first:

- `EmptyState.ets`
- `LoadingState.ets`
- `ErrorState.ets`

Each component should stay intentionally small and presentation-focused. Business pages remain responsible for deciding which state to show and what next action makes sense.

This is better than page-by-page one-off cleanup because:

- copy and visual structure stay consistent
- future pages can reuse the same patterns
- state handling becomes easier to reason about in demos and reviews

## Scope

### First-pass pages

The first pass should cover the pages where empty/loading/error states are most visible in daily flows:

- home page
- message hub
- order list
- my published products
- admin dashboard

### Explicitly out of scope for this pass

- full redesign of detail pages
- changing remote APIs
- adding skeleton shimmer or advanced animation systems
- turning every toast into inline error cards

## Component Design

### EmptyState

Purpose:

- show a calm, product-like empty page or section state
- guide the user toward the most sensible next action

Props:

- title
- description
- optional action text
- optional action handler
- optional compact mode

Behavior:

- supports full-page and section-level usage
- language should sound helpful, not technical
- when an action exists, it should be the single strongest next step

Examples:

- home: no on-sale products yet
- message hub: no reminders or no conversations
- order list: no orders yet
- my published: no published products yet

### LoadingState

Purpose:

- show that the page is still working
- avoid raw text-only placeholders like “正在加载...”

Props:

- title
- optional description
- optional compact mode

Behavior:

- centered and lightweight
- suited for both first load and refresh-like contexts
- copy should explain what is being loaded, not just that “something” is happening

### ErrorState

Purpose:

- surface recoverable errors in a stable and reusable layout
- provide a retry path where retry makes sense

Props:

- title
- description
- optional retry text
- optional retry handler
- optional compact mode

Behavior:

- used for page-level failures, not every inline form validation
- action copy should be specific, usually “重新加载” or a page-relevant equivalent

## Product Copy Direction

The tone should match a real campus second-hand platform:

- clear
- warm
- next-step oriented

Examples of preferred style:

- “这里还没有合适的商品”
- “审核通过后，你发布的商品会显示在首页”
- “先联系卖家，沟通记录会出现在这里”

Avoid:

- developer phrasing
- raw technical errors
- repeated “暂无数据” without context

## Page-by-Page Usage

### Home

Use:

- `LoadingState` while remote/local product feed is being prepared
- `EmptyState` when there are no on-sale products or no matching results
- `ErrorState` only when the page truly cannot recover current content and needs an explicit retry

Notes:

- keep existing toast behavior for transient remote fetch failures if needed
- but the visual page state should remain readable and intentional

### Message Hub

Use:

- `EmptyState` for no reminders and no conversations
- optional compact empty sections for split areas
- keep current login-empty behavior but unify visual structure with the shared component style

### Order List

Use:

- `EmptyState` with a clear action back to browsing
- later can be reused for status-filter empty states if filters are added

### My Published Products

Use:

- `LoadingState` during remote mine-list fetch
- `EmptyState` when the user has not published anything
- `ErrorState` when the remote request fails and there is no safe local substitute

### Admin Dashboard

Use:

- shared states when dashboard stats or governance content are unavailable
- keep admin-facing tone professional but still concise

## Visual Direction

The reusable state components should match the current product tone:

- warm off-white backgrounds
- clear dark titles
- lower-contrast supportive descriptions
- one obvious primary action when present

They should feel consistent with:

- home cards
- order cards
- message hub cards

## Error Handling Strategy

Not every failed request should switch the whole page into error mode.

Use this rule:

- if the page still has valid last-known content, keep content and optionally use toast or small inline hint
- if the page has no usable content, use `ErrorState`

This keeps the product feeling stable instead of overly jumpy.

## Testing and Verification

Verification for this pass should focus on:

- shared components exist and are reused
- major pages no longer rely on scattered ad hoc placeholders
- copy is consistent across empty/loading/error situations
- primary actions from empty/error states lead somewhere sensible

## Result

After this pass, the app should feel more like one finished product:

- page states look related
- user guidance is more human
- demos recover better when pages are empty or partially unavailable
