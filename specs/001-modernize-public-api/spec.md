# Feature Specification: Public API Modernization

**Feature Branch**: `001-modernize-public-api`  
**Created**: 2026-04-14  
**Status**: Draft  
**Input**: User description: "Make a general observation based on the requirements in the constitution. You need to update the library for the most recent technologies. While doing this you should also observe for possible refactoring with the code and the folder structure even with the syntax and code namings. The library should be more powerful for public use."

## Clarifications

### Session 2026-04-14

- Q: Which concurrency model should the modernized public API treat as the primary long-term surface? → A: Make `async/await` the primary documented API, while keeping Combine publishers as secondary compatibility APIs.
- Q: What should be the canonical public request-construction model after modernization? → A: Keep multiple specialized public request entry points for different body and transport styles.
- Q: How aggressive should this modernization be about source-breaking public API changes? → A: Prioritize a clean redesign even if it introduces broad source-breaking changes across the public API.
- Q: What should the modernized public error model optimize for? → A: Use a richer typed public error model that becomes the canonical failure contract across async, Combine, and transfer flows.
- Q: How should the modernized API handle download progress and cancellation ownership? → A: Use per-operation handles or task objects so each download or request manages its own progress and cancellation independently.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modern Client Experience (Priority: P1)

As an application developer evaluating Resting for a production app, I want a
clear and modern public API for common REST workflows so that I can adopt the
library quickly without working around outdated naming, inconsistent request
configuration, or unclear behavior.

**Why this priority**: Public adoption depends first on whether the library
feels current, understandable, and trustworthy at the call site.

**Independent Test**: A developer can complete a basic data request, a request
with headers and body content, and a decoded response flow using the published
API and documentation without consulting internal source files.

**Acceptance Scenarios**:

1. **Given** a developer starting from the README and API docs, **When** they
   configure and execute a standard REST request, **Then** the steps and public
   naming are coherent and require no knowledge of internal implementation.
2. **Given** a developer using different request styles, **When** they compare
   request-building entry points, **Then** the available options follow one
   consistent mental model rather than overlapping or conflicting patterns.

---

### User Story 2 - Broader Public Capability (Priority: P2)

As a library consumer with real-world networking needs, I want the library to
cover common public REST client scenarios more completely so that I can rely on
one package for routine request, response, transfer, and failure-handling use
cases.

**Why this priority**: A cleaner API is not enough if the package still feels
too limited for everyday adoption beyond simple requests.

**Independent Test**: A consumer can exercise representative request, response,
download, cancellation, and failure flows and confirm that each flow has a
clear supported path and predictable outcome.

**Acceptance Scenarios**:

1. **Given** a consumer making typical REST calls, **When** they configure
   request metadata, body content, and response handling, **Then** the library
   supports those flows without forcing ad hoc workarounds.
2. **Given** a consumer handling failures or interrupted work, **When** a
   request fails, is cancelled, or returns an unexpected response, **Then** the
   library reports the outcome in a clear and consistent way.

---

### User Story 3 - Maintainable Package Structure (Priority: P3)

As a maintainer of Resting, I want the package structure, naming, and source
organization to reflect the public domain clearly so that future changes are
easy to review, document, and extend without accumulating accidental
complexity.

**Why this priority**: Long-term public quality depends on keeping the internal
shape of the package as understandable as the external API.

**Independent Test**: A maintainer can identify where a public behavior belongs,
update the related documentation and tests, and review naming consistency
without tracing through unrelated files or legacy terminology.

**Acceptance Scenarios**:

1. **Given** a maintainer reviewing the package, **When** they inspect the
   source and test layout, **Then** related behaviors are grouped clearly and
   names match the public concepts they support.
2. **Given** a maintainer preparing a public release, **When** they review the
   changed surface, **Then** renamed or reorganized elements have a documented
   rationale and migration guidance where behavior changed.

### Edge Cases

- Concurrent operations MUST remain isolated from one another; starting one
  request or transfer MUST NOT overwrite progress, cancellation, or completion
  state for another active operation.
- Cancellation after partial progress MUST resolve through the shared typed
  public error model, and cancellation of one operation MUST NOT affect other
  active operations.
- Empty, malformed, partially decodable, or semantically invalid responses MUST
  map to explicit typed failure cases with consistent behavior across async,
  Combine, and transfer-related APIs.
- Renamed capabilities, removed ambiguities, and changed defaults MUST be
  documented with migration guidance for every affected public API change.
- If user-facing strings change, English resources MUST be updated completely
  and existing localized resources MUST be reviewed for consistency drift.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST present a modernized public surface for common
  REST client tasks, including configuring requests, executing operations, and
  consuming results, with clear and consistent naming.
- **FR-002**: The system MUST support the library's existing core user value in
  a more coherent form, including standard request workflows, decoded response
  handling, download-related flows, and deterministic failure reporting.
- **FR-003**: The system MUST identify and remove or consolidate public-facing
  ambiguity in naming, syntax, or overlapping usage patterns that make the
  library harder to learn.
- **FR-004**: The system MUST improve the package's suitability for general
  public use by covering the most common real-world client scenarios expected of
  a general-purpose REST client library.
- **FR-005**: The system MUST reorganize source, tests, and public-facing
  terminology where needed so that the structure reflects the domain clearly and
  remains easy to maintain.
- **FR-006**: The system MUST preserve stable behavior where possible and MUST
  provide explicit migration guidance for any behavioral or naming changes that
  affect existing adopters.
- **FR-007**: The system MUST provide complete public documentation for every
  changed public capability, including purpose, inputs, outputs, and failure
  expectations.
- **FR-008**: The system MUST keep user-visible messaging and package guidance
  aligned with the default English experience and review other existing
  localizations for consistency when shared strings change.
- **FR-009**: The system MUST present `async/await` as the primary concurrency
  model in the public API and documentation, while retaining Combine publisher
  entry points as secondary compatibility APIs during this modernization.
- **FR-010**: The system MUST preserve multiple specialized public request
  entry points for distinct body or transport styles, while making the naming
  and guidance for choosing among them explicit and non-overlapping.
- **FR-011**: The system MUST prioritize a clean and coherent public redesign
  over source compatibility when the two conflict, and MUST document every
  breaking change and migration path needed for existing adopters.
- **FR-012**: The system MUST define a richer typed public error model as the
  canonical failure contract across async, Combine, and transfer APIs, with
  consistent mapping from transport, decoding, cancellation, and validation
  failures.
- **FR-013**: The system MUST expose per-operation lifecycle ownership for
  downloads and other cancellable work, including independent progress and
  cancellation handles so overlapping operations do not share hidden mutable
  state.

## Compatibility & API Impact *(mandatory)*

- **Public API Impact**: The feature is expected to review and potentially
  rename, regroup, or simplify core public entry points so the library reads as
  a coherent product rather than a collection of legacy additions.
- **Compatibility Direction**: This modernization may introduce broad
  source-breaking public API changes when needed to achieve a substantially
  cleaner long-term design, with migration guidance treated as a release
  requirement rather than optional follow-up.
- **Request Construction Direction**: The public API will continue to expose
  multiple specialized request-construction paths for different body or
  transport styles rather than collapsing all request setup into a single
  canonical builder.
- **Platform Impact**: The modernization applies to the full Apple platform
  audience targeted by the package, and the release must review whether the
  current support matrix still reflects present-day public expectations.
- **Concurrency Impact**: Public operations must behave predictably when
  requests overlap, are cancelled, or complete out of order, and the library
  must avoid exposing unclear concurrency behavior to consumers.
- **Concurrency Surface Direction**: `async/await` is the primary long-term
  public concurrency model; Combine remains available as a secondary
  compatibility layer rather than an equal-first-class design center.
- **Operation Ownership Direction**: Each started transfer or cancellable
  request owns its own progress and cancellation lifecycle through a
  per-operation handle or task-like abstraction rather than client-global
  mutable state.
- **Failure Contract Direction**: Public APIs share one typed failure model so
  consumers can handle transport, decoding, cancellation, and response
  validation outcomes consistently regardless of which supported entry point
  they use.
- **Localization Impact**: English remains the default user-facing language; any
  revised error text or consumer guidance must be complete in English and
  checked against existing localized resources for consistency.

### Key Entities *(include if feature involves data)*

- **Client Surface**: The set of public entry points consumers use to configure
  work, start operations, observe results, and handle failures.
- **Request Definition**: The consumer-supplied description of an outbound REST
  operation, including destination, intent, metadata, and payload information.
- **Operation Outcome**: The result of a request or transfer, including success,
  failure, cancellation, and any response information needed for caller
  decisions.
- **Public Error Model**: The typed set of public failure cases exposed by the
  library for transport, decoding, cancellation, validation, and related
  request outcome errors.
- **Migration Guidance**: Release-facing documentation that explains renamed
  concepts, preserved behaviors, and any adoption steps for existing consumers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new consumer can complete the primary documented request flow
  from package guidance in under 10 minutes without reading internal source
  files.
- **SC-002**: The release documentation covers 100% of changed public
  capabilities and explicitly identifies every breaking or behavior-changing
  upgrade step.
- **SC-003**: Reviewers can map every changed public capability to a single
  obvious source area and a single obvious test area without ambiguity.
- **SC-004**: The modernized release supports the package's baseline request,
  response, transfer, and failure scenarios with no undocumented gaps in the
  published user guidance.

## Assumptions

- Existing consumers still need the current request, decoding, and download
  value propositions, but they expect a clearer and more capable public product.
- The feature may include breaking renames or reorganizations if they remove
  confusing legacy behavior and are accompanied by migration guidance.
- "More powerful for public use" is interpreted as covering common REST client
  scenarios better, not as expanding into highly specialized networking domains.
- Documentation, tests, localization review, and package metadata updates are in
  scope whenever the public release experience changes.
