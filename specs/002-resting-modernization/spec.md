# Feature Specification: Resting Modernization Follow-Up

**Feature Branch**: `002-resting-modernization`  
**Created**: 2026-08-15  
**Status**: Draft  
**Input**: User description: "Finish the existing modernization by addressing only verified release-blocking download validation, client concurrency and lifecycle, async/Combine parity, public response-validation API, and release-environment gaps while preserving the established product surface."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trust Download Outcomes (Priority: P1)

As a library consumer, I want downloads to obey the same response contract as
data requests so that an error page or invalid response is never reported as a
successful file transfer.

**Why this priority**: Reporting a failed server response as a successful
download can cause applications to persist or process invalid content.

**Independent Test**: Run deterministic download fixtures that return a valid
success response, a non-success HTTP response, and a non-HTTP response, then
verify that only the valid success response yields a file URL and that failures
use the established typed error cases.

**Acceptance Scenarios**:

1. **Given** a download receives a 2xx HTTP response, **When** the transfer
   completes, **Then** the consumer receives the downloaded file through the
   existing transfer handle behavior.
2. **Given** a download receives a non-2xx HTTP response, **When** the transfer
   completes, **Then** the consumer receives the status-code failure with the
   response status and available body data and no success result is reported.
3. **Given** a download has no response or receives a non-HTTP response,
   **When** completion is evaluated, **Then** the consumer receives the
   established invalid-response failure and no success result is reported.

---

### User Story 2 - Use One Client Safely Across Operations (Priority: P1)

As a library consumer, I want one client to support concurrent first use,
overlapping work, and independent cancellation without races or retained
networking resources so that normal application ownership remains safe and
predictable.

**Why this priority**: A concurrency race or ownership cycle can produce
duplicate session state, cross-operation interference, or a client that never
deallocates.

**Independent Test**: Start overlapping operations concurrently on a newly
created client, cancel one operation, complete the others, release the client,
and verify isolated outcomes plus automatic client and session deallocation.

**Acceptance Scenarios**:

1. **Given** a newly created client, **When** two or more operations begin at
   the same time, **Then** all operations use one safely initialized client
   session without a race or duplicated lifecycle state.
2. **Given** multiple active operations, **When** one is cancelled, **Then**
   only that operation reports cancellation and the others can complete
   normally.
3. **Given** a client that has created its session, **When** the consumer
   releases its final reference and no operation requires it, **Then** the
   client and session deallocate automatically without an explicit shutdown
   call.

---

### User Story 3 - Handle Equivalent Failures Across APIs (Priority: P1)

As a consumer maintaining async and Combine call sites, I want both APIs to
validate responses and report typed failure context identically so that error
handling does not depend on the chosen execution style.

**Why this priority**: Divergent validation and missing decoding context make
compatibility APIs unreliable and force duplicate consumer logic.

**Independent Test**: Execute the same deterministic success, invalid-response,
status-failure, and decoding-failure fixtures through async and Combine entry
points and compare the resulting value or typed error, including retained
response data.

**Acceptance Scenarios**:

1. **Given** identical response input, **When** async and Combine execution
   validate it, **Then** both accept and reject the same responses under the
   default 2xx contract.
2. **Given** identical undecodable response data, **When** decoding fails
   through either API, **Then** both expose a decoding failure with equivalent
   underlying error and response-data context.
3. **Given** transport, cancellation, invalid-response, or status-code failure,
   **When** either API reports it, **Then** the same typed failure contract and
   available context are preserved.

---

### User Story 4 - Adopt a Verifiable Modern Release (Priority: P2)

As a package adopter or maintainer, I want the declared minimum toolchain,
public documentation, and automated release checks to agree so that the
published package can be trusted across every supported Apple platform.

**Why this priority**: The behavioral fixes cannot be released confidently if
the declared toolchain and release checks do not exercise the supported package
matrix.

**Independent Test**: From the documented release environment, run the package
test suite and platform compilation checks without selecting named simulator
devices, then review migration guidance for the one public API removal.

**Acceptance Scenarios**:

1. **Given** the repository's supported release environment, **When** automated
   checks run, **Then** the complete test suite passes and the package compiles
   for iOS, macOS, watchOS, tvOS, and visionOS.
2. **Given** an adopter uses the selected minimum toolchain, **When** the package
   manifest is evaluated, **Then** the declared requirement matches the release
   baseline.
3. **Given** a consumer reviews response-validation documentation, **When** they
   inspect the public surface and migration guide, **Then** they see the fixed
   default 2xx behavior and clear guidance that the previously unusable public
   validator type has been removed.

### Edge Cases

- A download callback provides a temporary file but no associated response.
- A download receives an HTTP redirect chain whose final response is non-2xx;
  the final response determines the outcome.
- A non-2xx download has no accessible response body; the status failure still
  reports the status code and permits absent body data.
- Response validation fails after a temporary download file exists; the file
  is not surfaced as a successful result and no library-created orphan remains.
- Several callers access a new client's session-dependent operations at the
  same instant.
- Cancellation races with completion while other operations remain active;
  every transfer resolves once and unrelated work remains unaffected.
- The last external client reference is released after session creation but
  before or after operation completion; no ownership cycle keeps the client and
  session alive indefinitely.
- Decoding fails for empty and non-empty bodies; async and Combine preserve the
  same optional body-data context.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Download operations MUST reject a missing response or a response
  that is not HTTP using `RestingError.invalidResponse`.
- **FR-002**: Download operations MUST reject every final HTTP status outside
  200 through 299 using `RestingError.statusCode`, including the status code and
  available response body data.
- **FR-003**: A rejected download MUST NOT report a file URL as success and MUST
  clean up any temporary or library-created file that is no longer needed.
- **FR-004**: Successful 2xx downloads MUST preserve the existing
  `TransferHandle` result, progress, and per-operation cancellation behavior.
- **FR-005**: Concurrent first use of a single `RestClient` MUST initialize and
  expose one consistent session lifecycle without data races.
- **FR-006**: Session ownership MUST allow `RestClient` and its session to
  deallocate automatically after consumer ownership and active work end; no new
  consumer-managed shutdown step may be required.
- **FR-007**: Overlapping operations MUST retain independent progress,
  cancellation, completion, and error state, including when cancellation and
  completion race.
- **FR-008**: Async and Combine execution MUST use one shared response-validation
  behavior and apply the same default 2xx acceptance rule.
- **FR-009**: Async and Combine execution MUST map equivalent transport,
  cancellation, invalid-response, status-code, and decoding failures to the same
  `RestingError` case with equivalent available context.
- **FR-010**: Decoding failures from both execution styles MUST retain the
  response data when it is available.
- **FR-011**: The unusable public `ResponseValidator` type MUST be removed from
  the consumer API; default 2xx validation MUST remain an internal behavior and
  configurable status validation MUST NOT be added by this feature.
- **FR-012**: The package MUST require Swift 6.3 as its minimum tools baseline
  and MUST satisfy strict-concurrency checking for supported consumer use.
- **FR-013**: Automated release checks MUST run the package tests in a Swift 6.3
  compatible environment and verify compilation for iOS, macOS, watchOS, tvOS,
  and visionOS without depending on named simulator devices.
- **FR-014**: All existing tests MUST remain green, and deterministic regression
  coverage MUST include non-2xx and non-HTTP downloads, concurrent first use,
  overlapping operations, cancellation isolation, client deallocation after
  session creation, strict-concurrency use, and async/Combine decoding parity.
- **FR-015**: Public documentation and migration guidance MUST describe the
  download response contract, error parity, concurrency and lifecycle behavior,
  Swift 6.3 baseline, and removal of `ResponseValidator`.
- **FR-016**: The feature MUST preserve the async/await-first API, secondary
  Combine compatibility, existing `RequestDefinition` styles,
  `ResponsePayload`, `RestingError`, `TransferHandle` behavior, deployment
  minimums, package structure, and absence of third-party runtime dependencies.
- **FR-017**: Existing English and Turkish localized behavior MUST remain
  complete and consistent; any changed user-facing error text MUST be reflected
  in both localizations.

## Compatibility & API Impact *(mandatory)*

- **Public API Impact**: `ResponseValidator` is removed because its validation
  operation was inaccessible and clients could not configure it. No replacement
  customization API is introduced. All other named public surfaces in scope are
  preserved.
- **Migration Impact**: Guidance identifies the removed unusable type and
  explains that all supported execution and download paths use fixed default
  2xx validation.
- **Concurrency Impact**: Concurrent first use, overlapping operations,
  cancellation isolation, and automatic client/session release become verified
  parts of the client contract. Consumers do not gain a shutdown obligation.
- **Platform Impact**: Current deployment minimums remain unchanged. Release
  verification covers iOS, macOS, watchOS, tvOS, and visionOS.
- **Localization Impact**: English remains the default and Turkish remains
  supported. No new user-facing strings are expected unless existing error
  descriptions must change to meet the typed-error contract.

### Key Entities *(include if feature involves data)*

- **Download Outcome**: A transfer result consisting of either a validated file
  URL or one typed failure; it never represents a rejected response as success.
- **Response Context**: The HTTP status and optional body data retained with a
  validation or decoding failure when available.
- **Client Session Lifecycle**: The shared networking lifetime owned behind one
  client, safe to initialize concurrently and able to end without a consumer
  shutdown call.
- **Operation State**: Per-operation progress, cancellation, completion, and
  failure information that remains isolated from other active work.

## Scope Boundaries

- No new REST capabilities, request styles, status-code customization, runtime
  dependencies, products, or targets are added.
- No architectural redesign, speculative abstraction, deployment-minimum
  change, cosmetic rename, formatting sweep, or unrelated style cleanup is in
  scope.
- Coverage is limited to deterministic regressions required to prove the listed
  release blockers and preserve existing behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Across all deterministic download fixtures, 100% of 2xx responses
  succeed, 100% of non-2xx or invalid responses fail with the documented typed
  outcome, and zero rejected responses expose a successful file result.
- **SC-002**: Repeated concurrent-first-use and overlapping-operation checks
  complete with zero races, duplicate resolutions, or cross-operation
  cancellations, and each client/session pair is released after its documented
  lifetime.
- **SC-003**: For every shared failure fixture, async and Combine produce the
  same typed failure case and equivalent available status, underlying-error,
  and body-data context.
- **SC-004**: One automated release run passes 100% of existing and new tests and
  completes compilation checks for all five supported Apple platform families
  without a named-device dependency.
- **SC-005**: Documentation covers 100% of affected public behavior and the
  public API removal, enabling an existing consumer to identify the download
  contract and required migration action without reading source code.
- **SC-006**: The release introduces zero new runtime dependencies, zero new
  REST features, and zero changes to supported deployment minimums.

## Assumptions

- The established `RestingError` cases are sufficient for all required
  failures; this follow-up aligns behavior rather than expanding the error API.
- The final HTTP response controls download validation after standard redirect
  handling.
- Response body data is retained when the execution mechanism makes it
  available; absence of body data is represented by the existing optional
  context.
- Existing operation handles remain the consumer-facing ownership boundary for
  progress and cancellation.
- Platform compilation checks may use generic destinations or equivalent
  platform-level verification because runtime UI behavior is outside this
  package's scope.
