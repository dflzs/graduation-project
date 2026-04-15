# Governance And Trust System Design

**Context**

The current project has already completed the first trust-bearing platform foundations:
- campus identity and student verification
- role/status-based marketplace permission boundaries
- remote-first orders, chat, announcements, admin users, dashboard, and product flows
- the first moderation slice for order complaints and chat reports

That means the project is no longer blocked on "whether governance exists at all." The real gap now is that governance still behaves like a minimum loop, not a mature campus-platform subsystem.

This design upgrades moderation, complaint, appeal, and user-governance work from a narrow vertical slice into a complete governance and trust subsystem that matches the project's broader remediation roadmap.

## Implementation Status

As of 2026-04-15, this design is no longer only forward-looking. The repository already includes:
- full moderation target coverage for product, user, chat, and order
- a richer moderation lifecycle with triage, evidence request, review, appeal, and closure states
- remote-first moderation, appeal, and governance-action services with repository hydration and sync publication
- admin moderation workbench, governance center, and appeal/moderation submission pages
- governance-action linkage into user status, admin user management, and conservative public trust signals

The biggest remaining gaps are no longer frontend product semantics. They are mostly around deployment-side backend bootstrap completion, long-tail polish, and keeping the written docs aligned with the now much larger implemented surface.

## 1. Goal

Turn abnormal-trade handling, user punishment, and trust presentation into a consistent platform capability rather than scattered page actions.

The completed subsystem should let the platform:
- accept reports against all meaningful marketplace targets
- preserve a full moderation lifecycle instead of a one-shot verdict
- connect moderation outcomes to user governance actions
- expose progress, results, and appeal paths to affected users
- surface trust and governance history in a readable, campus-appropriate way

## 2. Non-Goals

To keep the project within thesis and current engineering bounds, this design does not require:
- real-name government identity integration
- automated OCR or AI evidence review
- external complaint systems or legal escalation workflows
- commercial-scale abuse prevention infrastructure
- map-based incident evidence or live location capture

## 3. Design Principles

### 3.1 Full lifecycle over single submit/result

No governance record should stop at "user submitted" or "admin approved/rejected." Every governance flow should have:
- creation
- review intake
- optional evidence supplementation
- decision
- optional appeal
- final closure

### 3.2 One moderation domain, multiple targets

Reports should not be implemented as unrelated custom flows. Product, user, chat, and order incidents should share:
- one record model
- one status model
- one review workbench
- one notification pattern

### 3.3 Governance and trust must be linked

Moderation cannot remain isolated from user status. If a complaint is validated, the platform should be able to:
- warn a user
- apply temporary restrictions
- apply muting or trading restrictions
- ban when necessary

Likewise, user-facing trust presentation should reflect meaningful platform history, not just raw credit score.

### 3.4 Remote-first source of truth

Governance data is platform truth, not UI convenience data. Records, review state, appeals, and governance actions should be remote-first with local cache only as compatibility or offline fallback.

### 3.5 Conservative user experience

When governance state is uncertain, the UI should bias toward:
- clearer explanation
- less misleading interactivity
- stronger readonly and safety messaging

## 4. Domain Model

### 4.1 Moderation target types

The subsystem should support:
- `product_report`
- `user_report`
- `chat_report`
- `order_complaint`

These represent two families:
- content/actor risk: product, user, chat
- trade dispute: order

### 4.2 Moderation record

The current `ModerationRecord` should evolve into a richer structure with at least:
- `id`
- `targetType`
- `targetId`
- `reporterId`
- `reportedUserId?`
- `relatedOrderId?`
- `relatedProductId?`
- `relatedThreadId?`
- `category`
- `reason`
- `description`
- `evidenceItems`
- `status`
- `priority`
- `assignedAdminId?`
- `adminComment?`
- `resolutionCode?`
- `governanceActionId?`
- `createdAt`
- `updatedAt`
- `reviewedAt?`
- `closedAt?`

### 4.3 Moderation statuses

Replace the current narrow result model with lifecycle states:
- `pending`
- `triaging`
- `awaiting_evidence`
- `in_review`
- `resolved_valid`
- `resolved_rejected`
- `resolved_partial`
- `appealed`
- `appeal_reviewing`
- `closed`

The important distinction is that "resolved" and "closed" are not the same:
- `resolved_*` means the platform has made a decision
- `closed` means the entire case lifecycle, including appeal handling, is complete

### 4.4 Governance action

Create a separate governance-action model so punishment history is explicit rather than hidden inside user status:
- `id`
- `userId`
- `sourceType` (`moderation`, `manual_admin`)
- `sourceId`
- `actionType`
- `reason`
- `comment`
- `startAt`
- `endAt?`
- `active`
- `createdBy`
- `createdAt`
- `updatedAt`

Suggested `actionType` values:
- `warning`
- `mute_chat`
- `restrict_trade`
- `temporary_ban`
- `permanent_ban`

### 4.5 Appeal record

Appeal should be first-class, not a note field:
- `id`
- `moderationRecordId`
- `appellantId`
- `reason`
- `description`
- `evidenceItems`
- `status`
- `reviewedBy?`
- `reviewComment?`
- `createdAt`
- `updatedAt`

Suggested statuses:
- `pending`
- `in_review`
- `accepted`
- `rejected`
- `closed`

## 5. User-State Model Upgrade

The current `active/banned` model is too thin for a mature platform. It should evolve toward:
- `active`
- `restricted`
- `muted`
- `suspended`
- `banned`

Behavior expectations:
- `active`: full marketplace use
- `restricted`: can log in and read key history, but cannot trade
- `muted`: can trade, cannot send new chat messages
- `suspended`: strong temporary platform freeze with readonly access
- `banned`: strongest long-term denial state

Existing `banned` behavior can remain backward compatible while the new statuses are introduced incrementally.

## 6. Frontend Product Surface

### 6.1 User entry points

Add report/complaint entry points to:
- product detail: report product, report seller
- profile page or user card: report user
- chat detail: report conversation
- order detail: submit complaint

Entry points should vary by audience:
- guests: redirect to login
- admins: no report entry, route to admin tools
- restricted users: allow viewing existing cases and appeals, but not opening misleading trade actions

### 6.2 Governance center

Add a user-facing governance center page under profile to show:
- submitted reports/complaints
- current status and timeline
- evidence submitted
- decision summaries
- appeal eligibility
- submitted appeals and outcomes

This avoids forcing users to discover case state indirectly through notifications.

### 6.3 Admin moderation workbench

The current admin moderation page should evolve into a fuller review console with:
- filters by target type, status, priority, school, date range
- separate queues for pending, awaiting evidence, appealed, closed
- target snapshots
- reporter and reported user identity context
- governance-action panel
- resolution templates
- appeal handling
- operation timeline

### 6.4 Trust presentation

Trust UI should not only show campus verification. It should gradually include:
- completed order count
- dispute involvement summary
- current governance restrictions
- visible reputation and participation summary

This must stay conservative and readable, not punitive or overexposing private case details.

## 7. Backend And Data Architecture

### 7.1 Required backend modules

Add dedicated backend support for:
- `moderation.controller.js`
- `moderation.routes.js`
- `appeal.controller.js`
- `appeal.routes.js`
- `governance.controller.js`
- optional store/repository helpers if current backend structure needs them

### 7.2 Core endpoints

Required moderation endpoints:
- submit moderation record
- list current user's moderation records
- get moderation detail
- admin list moderation records
- admin review moderation record
- admin request additional evidence
- admin close moderation record

Required appeal endpoints:
- submit appeal
- list current user's appeals
- admin list appeals
- admin review appeal

Required governance endpoints:
- list user governance actions
- create governance action
- cancel/expire governance action
- get user governance summary

### 7.3 Remote-first integration

Client services should continue using the existing pattern:
- remote client
- service layer
- repository hydration
- sync event publishing

Moderation, appeal, and governance actions should publish dedicated sync keys such as:
- `moderation:changed`
- `appeals:changed`
- `governance:changed`

User-state changes that alter permissions must still flow through existing user sync channels too.

## 8. Data Flow

### 8.1 Report / complaint flow

1. User submits report from target page.
2. Client validates identity and target ownership rules.
3. Remote service persists moderation record.
4. Local cache hydrates and publishes sync.
5. User governance center updates.
6. Admin queue receives new pending case.

### 8.2 Review / action flow

1. Admin opens moderation detail.
2. Admin reviews target snapshot, history, evidence, and involved accounts.
3. Admin records decision.
4. Admin optionally applies governance action.
5. Record status updates and notifications are sent.
6. User-facing governance center and trust presentation refresh.

### 8.3 Appeal flow

1. Affected user opens eligible moderation result.
2. User submits appeal with explanation and supplemental evidence.
3. Admin sees appeal in dedicated queue.
4. Admin accepts or rejects appeal.
5. Governance action and user state update if needed.
6. Final closure notification is sent.

## 9. Error Handling And Safety

The subsystem should explicitly handle:
- missing or deleted targets
- duplicate submissions in short windows
- users trying to report their own content in invalid ways
- users trying to appeal ineligible cases
- admin review after record already closed
- stale local cache after user status changes

UI copy should clearly distinguish:
- action forbidden by identity
- record not found
- record already closed
- network failure with local fallback

## 10. Testing Strategy

### 10.1 Domain and service tests

Add tests for:
- target-type validation
- lifecycle status transitions
- remote-first persistence and local fallback
- reporter permissions
- admin review permissions
- appeal eligibility and appeal review
- governance-action creation and expiry effects

### 10.2 UI behavior tests

Add regression coverage for:
- user/report entry visibility by role and status
- admin queue routing
- user governance center audience semantics
- moderation outcome notifications
- appeal entry visibility after eligible decisions

### 10.3 Integration verification

Each tranche must still pass:
- `LocalUnit.test.ets`
- `assembleHap`

## 11. Recommended Execution Boundary

This should not be implemented as one uncontrolled mega-change. The design should be executed as three tightly connected subprojects:

1. full moderation domain and admin workbench
2. appeal flow and user governance center
3. governance action system and trust-signal integration

That still satisfies the user's "do complete work" requirement, but keeps each slice verifiable and reversible.

## 12. Success Criteria

This subsystem should be considered complete only when:
- all four moderation target types are supported
- moderation has a real lifecycle, not just submit/result
- appeals are first-class and reviewable
- governance actions can be applied and traced
- user-facing progress/history exists
- affected permissions and trust displays react consistently
- the whole chain is remote-first and verified by tests and build
