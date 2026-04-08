# Campus Market Remediation Roadmap Design

## 1. Document Purpose

This document is the development baseline for improving the current HarmonyOS campus second-hand trading platform project. It is not a paper-oriented summary. It is a technical remediation roadmap that answers four questions:

1. What the project is right now
2. Where the current framework is insufficient
3. What a credible target system should look like
4. In what order the system should be improved

All later feature work, refactoring, persistence work, testing work, and interface alignment should be judged against this document.

## 2. Current Project Positioning

The current project is a campus second-hand trading platform prototype built with HarmonyOS ArkTS. It already contains the major business areas required for a graduation project:

- user authentication
- product listing and browsing
- shopping cart and order creation
- simulated payment and completion
- review and credit score logic
- announcement management
- an admin-facing management surface

This is enough to demonstrate an end-to-end transaction story. However, the project still behaves more like a local demo framework than a production-like campus trading platform.

The core gap is not the lack of page count. The gap is that the framework is still weak in:

- persistence
- business rule completeness
- security and permissions
- module boundaries
- testing realism
- HarmonyOS-specific value expression inside the architecture

The project therefore needs structured remediation rather than isolated patching.

## 3. Existing Architecture Snapshot

The current codebase uses a practical four-layer shape:

- pages: ArkUI screens under `entry/src/main/ets/pages`
- services: business logic under `entry/src/main/ets/services`
- repositories: CRUD-style data access under `entry/src/main/ets/repositories`
- data: local data container under `entry/src/main/ets/data`

This is a reasonable starting point. It is not the architecture itself that is failing. The main problems are:

- boundaries are not strict enough
- persistence is incomplete
- some layers are demo-oriented instead of system-oriented
- platform capabilities are not yet leveraged as design drivers

This means the project should evolve from "simple layered prototype" to "stable client architecture with explicit business boundaries".

## 4. High-Level Diagnosis

The current framework has seven major classes of weakness:

1. Authentication and session management are functional but shallow.
2. Data persistence is incomplete and mostly in-memory.
3. Transaction rules are simplified to a local state-machine demo.
4. Platform security and permission boundaries are too weak.
5. Product, order, and user governance rules are thin.
6. Testing exists but is not deep enough to guarantee system credibility.
7. HarmonyOS is being used as a runtime, but not yet as a system design advantage.

The sections below expand each problem and define the improvement direction.

## 5. Current Deficiencies and Improvement Directions

### 5.1 Authentication System

#### Current deficiencies

The project now supports:

- phone-code login
- phone-password login
- phone registration
- admin code login

This is enough for a demo flow, but the framework is still weak in several ways:

- phone validation is simplistic and only checks `^1\\d{10}$`
- validation logic is duplicated between UI and service entry points
- password policy is minimal
- verification code policy is weak
- there is no retry throttling
- there is no account lock strategy
- there is no device/session strategy
- there is still a hard-coded admin login path
- auth state is process-memory-first rather than persistent-session-first

#### Why this is a framework problem

For a campus trading platform, authentication is not just "can the user enter the app". It is the basis for:

- identity trust
- order ownership
- admin privilege isolation
- user behavior tracing
- later credit and report systems

If auth remains a shallow flow wrapper, all later modules inherit weak identity assumptions.

#### Improvement direction

The authentication framework should evolve into a structured identity module with:

- unified validator rules in one place
- transport DTO validation separate from domain validation
- per-scenario auth policies:
  - send code
  - verify code
  - password login
  - register
  - admin login
- session persistence and restoration
- token or session abstraction that does not depend only on in-memory state
- removal or strict isolation of the current hard-coded admin backdoor
- security event recording:
  - login success
  - login failure
  - code request
  - privilege escalation attempt

#### HarmonyOS-oriented design value

This part should not just mimic Android login pages. In HarmonyOS, the auth module should be designed so it can later support:

- shared identity context across phone and tablet variants
- consistent ArkUI multi-page flow with clean state restoration
- future distributed or cross-device continuation of onboarding flows

The immediate implementation does not need full distributed auth, but the architecture should stop blocking it.

### 5.2 Session and State Persistence

#### Current deficiencies

The project currently stores auth state in a lightweight in-memory snapshot. Local business entities are also kept in a memory-backed local DB object seeded on startup.

That means:

- app restart loses reliable session continuity
- data durability is weak
- user trust is weak
- state recovery cannot be convincingly demonstrated
- debugging can become misleading because seed state reappears

#### Why this is a framework problem

Persistence is foundational. Without it:

- orders are not credible
- admin governance is not credible
- user behavior history is not credible
- platform operation cannot be explained coherently

A second-hand trading platform must preserve at least:

- users
- products
- cart
- orders
- reviews
- announcements
- auth/session metadata

#### Improvement direction

The framework should adopt a lightweight but explicit persistence strategy:

- define a persistent storage adapter layer
- define a serializable schema for all local entities
- load persistent state on startup
- flush state after repository mutations
- design error fallback when storage read/write fails
- separate seed-data initialization from persistent restore

The target is not to build a cloud backend first. The target is to make the client framework stable and stateful.

#### HarmonyOS-oriented design value

This is one of the strongest places to reflect HarmonyOS advantage in practice:

- device-side persistence and lifecycle handling can be integrated cleanly with ArkTS
- later versions can add multi-device sync or distributed continuation on top of a proper local persistence model

If persistence remains loose, the project looks like a generic mobile demo. If persistence becomes robust, the project starts to look like a platform application.

### 5.3 User Model and Identity Governance

#### Current deficiencies

The current user model supports role, status, credit score, and some remote auth fields. This is a good base, but governance is weak:

- role transitions are not tightly controlled
- banned users are only partially handled
- there is no audit trail
- there is no report/appeal path
- there is no identity completeness model
- there is no concept of user trust level

#### Improvement direction

The user framework should move toward:

- explicit user lifecycle:
  - registered
  - active
  - restricted
  - banned
- explicit role lifecycle:
  - user
  - admin
  - future moderator if needed
- user governance metadata:
  - last login time
  - failed login count
  - ban reason
  - manual admin notes
- compatibility with future campus identity features:
  - school verification flag
  - campus area or location grouping
  - student identity completion status

This keeps the project realistic while still staying within graduation-project scope.

### 5.4 Product Domain

#### Current deficiencies

The product framework is usable, but not yet realistic enough for a campus trading platform:

- title validation is minimal
- description validation is minimal
- image constraints are absent
- category consistency is thin
- price rules are weak
- status transitions are too loose
- moderation hooks are missing
- no anti-duplicate publication strategy exists

#### Why this matters

In second-hand trading, the product domain is the center of trust. Poor product governance leads to:

- spam
- fake listings
- misleading descriptions
- impossible states
- unconvincing admin behavior

#### Improvement direction

The product framework should gain:

- stronger create/update validation
- explicit status transitions:
  - draft
  - on_sale
  - reserved
  - sold
  - off_shelf
  - deleted
- seller ownership enforcement
- admin force-off-shelf path
- duplicate-content heuristics
- optional moderation metadata
- richer search filter dimensions:
  - category
  - keyword
  - price range
  - freshness
  - location tag

#### HarmonyOS-oriented design value

HarmonyOS advantage here is not just UI. Product browsing and publication should be architected so they scale naturally across:

- phone and tablet layouts
- responsive ArkUI experiences
- later device collaboration such as reviewing listings on one device and finalizing actions on another

That means keeping product state and product UI interaction models clean and declarative.

### 5.5 Order and Transaction Framework

#### Current deficiencies

This is one of the most important gaps.

The current order service already includes:

- create order
- simulate pay
- cancel
- mark arrived
- complete
- review

This is excellent for a prototype. But it is still too local and too idealized:

- no product reservation mechanism
- no concurrent buyer conflict strategy
- no timeout strategy
- no settlement abstraction
- no refund/after-sale model
- no dispute model
- no order operation log
- no user-visible transaction timeline
- no anti-repeat action protection

#### Why this matters

The transaction module is where a campus second-hand project becomes more than a CRUD system. Without a stronger order framework, the platform cannot convincingly explain:

- how one listing is protected from multi-buyer conflicts
- how no-show or breach is handled
- how both sides confirm fulfillment
- how trust is established around a face-to-face trade

#### Improvement direction

The order framework should evolve in phases:

##### Phase A: robust prototype rules

- reserve product after order creation or simulated payment
- prevent repeated active orders on the same sale item
- add order timeline events
- improve transition constraints
- improve review eligibility rules

##### Phase B: platform-grade simulation

- add auto-cancel for unpaid timeout
- add no-show or breach classification
- support order dispute state
- support refund-request simulation
- support admin intervention into problematic orders

##### Phase C: defensible architecture

- split payment simulation from order state logic
- introduce transaction policy objects or transaction coordinator
- keep state transition logic centralized and testable

#### HarmonyOS-oriented design value

This is where HarmonyOS can help the project look more differentiated:

- status updates can be designed as event-driven UI refreshes
- distributed or synchronized order-state updates can later become a real project highlight
- multi-device notification and transaction continuity can be layered on top once the state model is solid

The immediate task is not "implement distributed transactions". The immediate task is "make the order framework clean enough that HarmonyOS capabilities can be added naturally later".

### 5.6 Credit and Trust System

#### Current deficiencies

The existing project already includes credit-score calculation, which is an excellent thematic fit for a campus second-hand platform. However, it is still too formula-only and not deeply integrated with platform behavior.

Current weaknesses include:

- limited behavior inputs
- no penalty event classification
- no trust level display strategy
- no permission coupling
- no explanation surface for users

#### Improvement direction

The trust framework should become a first-class subsystem:

- define credit events:
  - completed order
  - positive review
  - cancellation
  - no-show
  - confirmed violation
- define score calculation rules with clear weights
- expose trust level tiers:
  - excellent
  - normal
  - risky
- use trust level inside platform policy:
  - restrict repeated publication
  - restrict high-value order creation
  - require more review visibility

This module can become one of the strongest "campus scenario" innovations in the whole project.

### 5.7 Admin and Governance Framework

#### Current deficiencies

The admin side exists, but governance depth is still limited:

- user ban/unban is basic
- product off-shelf is basic
- announcements are basic
- no report center exists
- no rule-violation workflow exists
- no operation log exists

#### Improvement direction

The admin framework should move toward:

- dashboard with platform health metrics
- user governance:
  - view user state
  - ban/unban
  - inspect trust level and order history summary
- product governance:
  - off-shelf
  - review flagged items
- content governance:
  - publish/update/delete announcements
- future-ready moderation workflow:
  - reports
  - review queue
  - operator notes

#### HarmonyOS-oriented design value

The management side can benefit from HarmonyOS adaptive UI. Admin operations are a natural area to show:

- wider layouts on larger screens
- cleaner dashboard composition with ArkUI declarative layout
- higher-quality presentation than a phone-only Android-style page stack

This should be reflected in later UI refinement phases.

### 5.8 Search, Discovery, and Recommendation

#### Current deficiencies

The current platform can search by keyword and category. That is functional, but weak for a marketplace:

- no sorting strategy
- no multi-condition filters
- no recommendation model
- no popularity or freshness ranking
- no browsing history usage

#### Improvement direction

The discovery framework should be improved in levels:

- basic:
  - sort by newest
  - sort by price
  - filter by campus location
  - filter by category
- intermediate:
  - recently viewed
  - related products
  - same seller recommendations
- advanced prototype:
  - rule-based recommendation, not necessarily ML

Even a simple recommendation layer will make the project look much more complete.

### 5.9 Messaging and Negotiation

#### Current deficiencies

The data layer already references chat data, but messaging is not yet a real subsystem.

For a campus second-hand platform, this is a major missing pillar. Buyers and sellers need:

- asking questions
- negotiating price
- confirming meeting place
- coordinating time

Without messaging, the current project is structurally missing one of the most realistic marketplace behaviors.

#### Improvement direction

The messaging subsystem should include:

- conversation list
- product-bound chat thread
- unread state
- simple negotiation messages
- quick send templates:
  - still available?
  - can lower the price?
  - where to meet?
- moderation hooks:
  - block
  - report

#### HarmonyOS-oriented design value

Messaging is one of the best areas to embody HarmonyOS platform direction later:

- notifications
- multi-device continuation
- adaptive layouts for chat on larger screens

Again, the immediate goal is not to over-build. The immediate goal is to stop the architecture from excluding these capabilities.

### 5.10 Notification and Event Framework

#### Current deficiencies

The project has a sync service abstraction, but user-facing event and notification strategy is still weak.

Missing items include:

- order event notification policy
- product status notification policy
- announcement notification policy
- unread counts
- local reminder strategy

#### Improvement direction

The framework should support:

- event publication from services
- event subscription from pages
- notification mapping by business type
- local user-visible reminders for:
  - order created
  - payment simulated
  - both parties arrived
  - order completed
  - new announcement

This will also strengthen the case that HarmonyOS is being used for more than page rendering.

### 5.11 UI and Interaction Consistency

#### Current deficiencies

The project already has usable ArkUI pages, but the experience is still closer to a collection of feature screens than a unified platform product.

Main issues:

- inconsistent copy language
- inconsistent component behavior
- inconsistent empty states
- weak loading/error feedback
- forms are functional but not systematized
- page structure is sometimes flow-first, not product-first

#### Improvement direction

The UI framework should standardize:

- form patterns
- list patterns
- detail-page layout patterns
- empty state patterns
- loading and submission feedback
- reusable action bars
- responsive layout rules

HarmonyOS advantage should appear through:

- cleaner declarative ArkUI composition
- responsive presentation across device sizes
- future readiness for multi-device presentation

### 5.12 Testing and Verification Framework

#### Current deficiencies

The project has a useful unit test file and fake remote auth client. This is better than many student projects. But the framework is still under-tested in a system sense:

- tests focus on service logic, not complete flow credibility
- no interface contract verification against real responses
- no page-level behavior checks
- no persistence recovery verification at scale
- no resilience tests for bad data or failed storage

#### Improvement direction

Testing should be layered:

- unit tests:
  - validators
  - state machine
  - auth transformations
  - credit rules
- repository tests:
  - persistence write/read
  - update consistency
- flow tests:
  - login
  - register
  - product publication
  - order completion
- failure tests:
  - invalid input
  - disabled users
  - missing remote fields
  - storage write failures

The goal is not "enterprise test coverage". The goal is "the framework can defend its critical flows".

### 5.13 Observability and Debuggability

#### Current deficiencies

Right now logs are mostly ad hoc `console.info` lines. That is useful during development but weak as a framework practice.

#### Improvement direction

The framework should adopt:

- business-tagged logs
- auth logs
- order lifecycle logs
- admin action logs
- storage failure logs
- clear user-facing error mapping

For a graduation project, this improves both maintainability and demonstration clarity.

## 6. Target Architecture After Remediation

The project should not become over-engineered. The target is still a manageable client-side campus platform prototype. The ideal target architecture is:

- pages:
  - focused on presentation and interaction
- application services:
  - coordinate use cases
- domain policies:
  - validation
  - transition rules
  - trust rules
- repositories:
  - storage-facing entity operations
- infrastructure:
  - persistence
  - remote auth
  - sync
  - notifications

The most important architectural improvement is not adding more layers. It is making responsibilities explicit.

## 7. Phased Remediation Strategy

The system should be improved in stages, not all at once.

### Phase 1: Foundation Stabilization

Goal: make the project stateful and technically stable.

Includes:

- local persistence framework
- session restore improvement
- validator consolidation
- auth policy cleanup
- removal or isolation of insecure admin shortcuts
- critical bug cleanup

Deliverable standard:

- app restart does not destroy core business state
- authentication rules are centralized
- critical flows remain available

### Phase 2: Transaction Credibility

Goal: make the project feel like a true trading platform rather than a page demo.

Includes:

- better product rules
- product status governance
- stronger order and reservation rules
- timeline and transaction event visibility
- stronger review eligibility rules
- better trust score integration

Deliverable standard:

- one complete trade flow is stable, coherent, and defensible
- no obvious impossible state remains

### Phase 3: Governance and Admin Strengthening

Goal: make the platform governable.

Includes:

- admin dashboard enhancement
- user ban and governance metadata
- product moderation path
- announcement management completion
- report/moderation skeleton

Deliverable standard:

- admin side can convincingly manage users, products, and information

### Phase 4: User Experience and Discovery Upgrade

Goal: improve product quality and presentation quality.

Includes:

- UI consistency pass
- search/filter improvement
- recommendation basics
- stronger form feedback
- empty/loading/error states

Deliverable standard:

- end-user experience feels like a coherent platform

### Phase 5: HarmonyOS Differentiation Pass

Goal: ensure the project is not just a generic mobile CRUD app built on HarmonyOS.

Includes:

- adaptive layouts for larger screens
- event-driven update patterns
- notification strategy
- infrastructure hooks for future distributed or multi-device behavior

Deliverable standard:

- the project visibly benefits from HarmonyOS design and runtime characteristics

## 8. Priority Order

The recommended implementation priority is:

1. persistence and session framework
2. auth hardening
3. product and order rule hardening
4. credit and governance integration
5. admin management completion
6. search/recommendation/message expansion
7. HarmonyOS differentiation polish

This order is deliberate:

- persistence first, because all other modules depend on durable state
- auth second, because identity underpins all later rules
- transaction rules third, because they define the project’s real business credibility

## 9. Risks and Control Strategy

### Risk 1: Overbuilding beyond graduation scope

Control:

- keep each phase prototype-appropriate
- prefer believable simulation over costly real integration

### Risk 2: Endless UI tweaking without architectural gains

Control:

- do not prioritize cosmetic work before persistence, auth, and order credibility

### Risk 3: Breaking existing demo flows while improving structure

Control:

- preserve end-to-end smoke paths during each phase
- add targeted tests for every critical flow

### Risk 4: HarmonyOS value becoming slogan-only

Control:

- ensure HarmonyOS value appears in actual design choices:
  - adaptive UI
  - event-driven synchronization
  - lifecycle-safe persistence
  - multi-device-ready architecture

## 10. Acceptance Criteria for the Remediation Program

This remediation effort should be considered successful only if the project reaches the following state:

- authentication is reliable, consistent, and persistent enough for repeated demo use
- local data survives restart and remains coherent
- product and order flows no longer allow obvious unrealistic states
- trust and governance are integrated into platform behavior
- admin functions are meaningful rather than decorative
- UI flows feel unified
- test coverage protects core business rules
- HarmonyOS is reflected in architecture and interaction design, not just in runtime choice

## 11. Development Principle Going Forward

All future work on this project should follow these principles:

- prioritize structural credibility over cosmetic breadth
- preserve demo usability while improving architecture
- prefer clear module boundaries over shortcut coupling
- use HarmonyOS where it meaningfully strengthens the project
- do not add features that cannot be explained, tested, or demonstrated

This document is the baseline. Future implementation plans should refine it into executable phases without changing its core priorities casually.
