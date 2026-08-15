---

description: "Task list for the Resting modernization follow-up"
---

# Tasks: Resting Modernization Follow-Up

**Input**: Design documents from `/specs/002-resting-modernization/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/public-api.md`, `quickstart.md`

**Tests**: Required by FR-014 and the project constitution. Write each story's regression tests first and confirm they fail before implementation.

**Organization**: Tasks are grouped by user story so each behavior can be implemented and verified as a focused increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches a different file and has no dependency on an incomplete task
- **[Story]**: Maps the task to its user story (`US1` through `US4`)
- Every task names the exact file it changes or validates

## Phase 1: Setup (Shared Test Support)

**Purpose**: Extend only the deterministic fixtures needed by multiple user stories.

- [X] T001 Extend deterministic request fixtures with response, delay, cancellation, and concurrent-request observation needed by lifecycle and parity tests in Tests/RestingTests/Mocks/MockURLProtocol.swift
- [X] T002 [P] Add download body-reading and temporary-file cleanup helpers needed by rejection tests in Tests/RestingTests/Mocks/DownloadFixture.swift

---

## Phase 2: Foundational (Shared Response Contract)

**Purpose**: Establish the one fixed response rule used by async, Combine, and download execution.

**⚠️ CRITICAL**: Complete this phase before user-story implementation.

- [X] T003 Add failing coverage for missing, non-HTTP, 2xx, and non-2xx responses with empty and non-empty body data in Tests/RestingTests/Support/SupportCoverageTests.swift
- [X] T004 Remove the public configurable surface from ResponseValidator, enforce the internal fixed 200..<300 rule, and update its async caller in Sources/Resting/Responses/ResponseValidator.swift and Sources/Resting/Support/URLSessionExecutor.swift

**Checkpoint**: One internal fixed-2xx validator is ready for every execution style.

---

## Phase 3: User Story 1 - Trust Download Outcomes (Priority: P1) 🎯 MVP

**Goal**: Return a file only for a final 2xx HTTP response; return the established typed error and clean up rejected temporary files otherwise.

**Independent Test**: Run deterministic 2xx, non-2xx with and without body bytes, missing-response, and non-HTTP download fixtures; only 2xx yields a readable file URL, while every rejected temporary file is absent after completion.

### Tests for User Story 1

- [X] T005 [US1] Add failing download tests for 2xx success, final non-2xx status/body context, missing and non-HTTP responses, rejected-file cleanup, and no successful file result in Tests/RestingTests/Transfers/TransferHandleTests.swift

### Implementation for User Story 1

- [X] T006 [US1] Validate each download response before creating or moving to a destination, retain readable non-empty error bytes, remove rejected temporary files best-effort, and resolve the handle with the primary typed error in Sources/Resting/Client/RestClient.swift

**Checkpoint**: Downloads independently satisfy the fixed response contract without loading successful files into memory.

---

## Phase 4: User Story 2 - Use One Client Safely Across Operations (Priority: P1)

**Goal**: Make one client safe for concurrent first use and overlapping work while preserving isolated cancellation and automatic client/session release.

**Independent Test**: Concurrently start operations on a fresh client, cancel one overlapping transfer while another completes, race cancellation with completion, release the final client reference, and observe one session lifecycle, one resolution per handle, and eventual client/session/delegate deallocation.

### Tests for User Story 2

- [X] T007 [P] [US2] Add failing concurrent-first-use, shared-session identity, overlapping-operation, and eventual client/session/delegate release regressions in Tests/RestingTests/Client/RestClientAsyncTests.swift
- [X] T008 [P] [US2] Add failing cancellation-isolation and cancellation-versus-completion exactly-once regressions in Tests/RestingTests/Transfers/TransferHandleTests.swift

### Implementation for User Story 2

- [X] T009 [US2] Replace lazy self-delegating session storage with one eagerly initialized URLSession and a private lock-protected download delegate that never retains RestClient, then gracefully invalidate on client release in Sources/Resting/Client/RestClient.swift
- [X] T010 [US2] Keep task attachment, cancellation, terminal transitions, progress callbacks, and continuation resolution per operation and outside held locks under cancellation/completion races in Sources/Resting/Transfers/TransferHandle.swift

**Checkpoint**: A client can be concurrently reused and released without duplicated session state, cross-operation effects, or an ownership cycle.

---

## Phase 5: User Story 3 - Handle Equivalent Failures Across APIs (Priority: P1)

**Goal**: Make async and Combine accept the same responses and preserve equivalent typed failure context.

**Independent Test**: Feed both APIs the same success, invalid-response, status-failure, transport/cancellation, and empty/non-empty decoding-failure fixtures and compare the value or `RestingError` case plus available status, cause, and body bytes.

### Tests for User Story 3

- [X] T011 [P] [US3] Add the async half of the shared success and typed-failure fixture matrix, including empty and non-empty decoding bodies, in Tests/RestingTests/Client/RestClientAsyncTests.swift
- [X] T012 [P] [US3] Add the Combine half of the shared success and typed-failure fixture matrix and assert parity with async outcomes in Tests/RestingTests/Client/RestClientCombineTests.swift

### Implementation for User Story 3

- [X] T013 [US3] Route raw Combine responses through the shared internal validator and map decoding failures with the original payload bytes while preserving existing transport and cancellation mapping in Sources/Resting/Client/RestClient+Combine.swift

**Checkpoint**: Async and Combine independently expose the same fixed validation and typed error context.

---

## Phase 6: User Story 4 - Adopt a Verifiable Modern Release (Priority: P2)

**Goal**: Align the declared Swift baseline, automated platform checks, public documentation, and migration guidance.

**Independent Test**: Under Swift 6.3, run the full SPM suite and release build, then compile for macOS and generic iOS, watchOS, tvOS, and visionOS destinations and verify the README describes every affected contract and the `ResponseValidator` removal.

### Tests and Release Checks for User Story 4

- [X] T014 [P] [US4] Raise only the Swift tools baseline from 6.2 to 6.3 while preserving products, targets, dependencies, localizations, platforms, and deployment minimums in Package.swift
- [X] T015 [P] [US4] Replace named-simulator checks with one Swift 6.3-compatible macOS 26 release job that prints the toolchain, runs SPM tests once, and builds macOS plus generic iOS, watchOS, tvOS, and visionOS destinations in .github/workflows/swift.yml

### Documentation for User Story 4

- [X] T016 [P] [US4] Document fixed validation, download failures, overlapping use, cancellation isolation, automatic lifecycle, returns, and thrown errors on affected public client methods in Sources/Resting/Client/RestClient.swift and Sources/Resting/Client/RestClient+Combine.swift
- [X] T017 [P] [US4] Document affected response, error, and transfer behavior without adding public API in Sources/Resting/Responses/ResponsePayload.swift, Sources/Resting/Support/RestingError.swift, and Sources/Resting/Transfers/TransferHandle.swift
- [X] T018 [US4] Update installation and migration guidance for Swift 6.3, fixed 2xx validation, rejected downloads, async/Combine error parity, safe shared-client lifecycle, and removal of ResponseValidator in README.md

**Checkpoint**: The package baseline, CI matrix, public documentation, and migration guidance agree.

---

## Phase 7: Polish & Cross-Cutting Verification

**Purpose**: Prove the complete release contract without adding scope.

- [X] T019 Verify existing English and Turkish localized error behavior remains complete and unchanged, updating assertions only if affected behavior requires it, in Tests/RestingTests/Localization/LocalizationResourceTests.swift
- [X] T020 Run the complete Swift 6.3 package test, release build, and supported-platform compilation workflow; correct any documented command mismatch in specs/002-resting-modernization/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; T001 and T002 can run in parallel.
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories; T003 must fail before T004 is implemented.
- **US1 (Phase 3)**: Depends on Foundational; T005 must fail before T006.
- **US2 (Phase 4)**: Depends on Foundational and follows US1 in the same client file; T007 and T008 can run in parallel, then T009 and T010 proceed in order.
- **US3 (Phase 5)**: Depends on Foundational; T011 and T012 can run in parallel, then T013 implements the parity fix. Coordinate T011 with US2 because both touch `RestClientAsyncTests.swift`.
- **US4 (Phase 6)**: Package and CI tasks can start after Foundational; documentation should be finalized after US1-US3 behavior stabilizes.
- **Polish (Phase 7)**: Depends on all selected user stories.

### User Story Completion Order

```text
Setup -> Foundational -> US1 (MVP)
                      -> US2
                      -> US3
US1 + US2 + US3 ------> US4 documentation -> Polish
```

- **US1 (P1)**: First deliverable because rejected downloads can surface invalid content.
- **US2 (P1)**: Logically independent after Foundational, but scheduled after US1 to avoid simultaneous edits to `RestClient.swift`.
- **US3 (P1)**: Logically independent after Foundational and can proceed alongside US1/US2 with file coordination.
- **US4 (P2)**: Manifest and CI work can proceed independently; final documentation depends on the stabilized P1 behavior.

### Within Each User Story

- Add regression tests and confirm they fail before implementation.
- Keep validation shared rather than duplicating guards in callers.
- Register operations before resume and resolve terminal state at most once.
- Complete implementation before final documentation and release verification.

## Parallel Execution Examples

### User Story 1

US1 is intentionally sequential because its regression and implementation both cover the single download path:

```text
T005 tests -> T006 implementation
```

### User Story 2

```text
Task T007: Client/session concurrency and lifecycle tests in RestClientAsyncTests.swift
Task T008: Cancellation and exactly-once tests in TransferHandleTests.swift
```

### User Story 3

```text
Task T011: Async parity matrix in RestClientAsyncTests.swift
Task T012: Combine parity matrix in RestClientCombineTests.swift
```

### User Story 4

```text
Task T014: Swift 6.3 manifest baseline in Package.swift
Task T015: Generic-platform release workflow in .github/workflows/swift.yml
Task T016: Client API documentation in RestClient source files
Task T017: Response, error, and transfer documentation in their source files
```

## Implementation Strategy

### MVP First (User Story 1)

1. Complete T001-T004 for deterministic fixtures and the shared fixed validator.
2. Complete T005-T006 for validated download outcomes and cleanup.
3. Stop and run the US1 deterministic fixtures independently.

### Incremental Delivery

1. Deliver US1 download safety.
2. Add US2 client concurrency, cancellation isolation, and automatic release.
3. Add US3 async/Combine failure parity.
4. Align US4 package metadata, CI, and documentation.
5. Complete T019-T020 as the release gate.

### Parallel Team Strategy

After Foundational completes, separate contributors may run US2 test work, US3 parity work, and US4 manifest/CI work in parallel. Serialize tasks that touch `RestClient.swift`, `RestClientAsyncTests.swift`, or shared documentation.

## Notes

- `[P]` means different files and no dependency on an incomplete task.
- No configurable validator, actor facade, operation manager, shutdown API, dependency, target, product, named simulator, or separate migration document is included.
- Existing localized strings stay untouched unless implementation changes user-facing copy; T019 verifies that constraint.
- Commit after each task or coherent task group if desired.
