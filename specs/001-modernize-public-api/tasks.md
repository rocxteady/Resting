# Tasks: Public API Modernization

**Input**: Design documents from `/specs/001-modernize-public-api/`
**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`, `contracts/public-api.md`, `quickstart.md`

**Tests**: Unit tests are REQUIRED for this feature because the specification and constitution require coverage for request construction, async execution, Combine compatibility, typed error mapping, transfer isolation, cancellation, and localization.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when dependencies are already satisfied and the task edits different files
- **[Story]**: User story label for story-specific phases (`[US1]`, `[US2]`, `[US3]`)
- Every task includes exact file paths

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Upgrade the package baseline and create the target source/test layout before shared implementation work begins.

- [ ] T001 Upgrade `Package.swift` to `swift-tools-version: 6.2` and review Apple platform declarations, including `visionOS`, in `Package.swift`
- [ ] T002 Create the domain-oriented source scaffolding in `Sources/Resting/Client/RestClient.swift`, `Sources/Resting/Client/RestClientConfiguration.swift`, `Sources/Resting/Client/RestClient+Combine.swift`, `Sources/Resting/Requests/HTTPMethod.swift`, `Sources/Resting/Requests/RequestDefinition.swift`, `Sources/Resting/Requests/RequestBody.swift`, `Sources/Resting/Responses/ResponsePayload.swift`, `Sources/Resting/Responses/ResponseValidator.swift`, `Sources/Resting/Transfers/TransferHandle.swift`, `Sources/Resting/Support/RestingError.swift`, `Sources/Resting/Support/URLSessionExecutor.swift`, and `Sources/Resting/Support/FoundationNetworkingSupport.swift`
- [ ] T003 [P] Create the reorganized test scaffolding in `Tests/RestingTests/Client/RestClientAsyncTests.swift`, `Tests/RestingTests/Client/RestClientCombineTests.swift`, `Tests/RestingTests/Requests/RequestDefinitionTests.swift`, `Tests/RestingTests/Transfers/TransferHandleTests.swift`, `Tests/RestingTests/Errors/RestingErrorMappingTests.swift`, `Tests/RestingTests/Localization/LocalizationResourceTests.swift`, `Tests/RestingTests/Mocks/MockURLProtocol.swift`, and `Tests/RestingTests/Mocks/DownloadFixture.swift`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared contracts, transport helpers, and migration baseline that all user stories build on.

**⚠️ CRITICAL**: No user story work should begin until this phase is complete.

- [ ] T004 Implement shared transport execution and HTTP response validation in `Sources/Resting/Support/URLSessionExecutor.swift` and `Sources/Resting/Responses/ResponseValidator.swift`
- [ ] T005 [P] Define the canonical typed failure contract in `Sources/Resting/Support/RestingError.swift` and align localized error keys in `Sources/Resting/Resources/en.lproj/Localizable.strings` and `Sources/Resting/Resources/tr.lproj/Localizable.strings`
- [ ] T006 [P] Add request-building support primitives in `Sources/Resting/Requests/HTTPMethod.swift`, `Sources/Resting/Requests/RequestBody.swift`, `Sources/Resting/Responses/ResponsePayload.swift`, and `Sources/Resting/Support/FoundationNetworkingSupport.swift`
- [ ] T007 [P] Build deterministic request/download mocks in `Tests/RestingTests/Mocks/MockURLProtocol.swift` and `Tests/RestingTests/Mocks/DownloadFixture.swift`
- [ ] T008 Establish the legacy-to-modern migration baseline by auditing `Sources/Resting/Resting.swift`, `Sources/Resting/RequestConfiguration.swift`, `Sources/Resting/RestingError.swift`, `Sources/Resting/Extensions/URLSession+Helper.swift`, `Sources/Resting/Extensions/URLComponents+Helper.swift`, and `Sources/Resting/DataWithURLResponse.swift`

**Checkpoint**: Shared contracts, mocks, localization keys, and migration boundaries are in place for story work.

---

## Phase 3: User Story 1 - Modern Client Experience (Priority: P1) 🎯 MVP

**Goal**: Deliver a clear async/await-first request API with specialized request definitions and readable consumer-facing guidance.

**Independent Test**: A consumer can follow `README.md` and `specs/001-modernize-public-api/quickstart.md` to configure a client, build specialized requests, execute async raw and decoded calls, and understand the public naming without reading legacy source files.

### Tests for User Story 1

- [ ] T009 [P] [US1] Add request-construction coverage for query, form, JSON, raw-body, and header-merging flows in `Tests/RestingTests/Requests/RequestDefinitionTests.swift`
- [ ] T010 [P] [US1] Add async raw-data and decoded-response coverage for the modern client surface in `Tests/RestingTests/Client/RestClientAsyncTests.swift`

### Implementation for User Story 1

- [ ] T011 [P] [US1] Implement client configuration defaults and async-first initialization in `Sources/Resting/Client/RestClientConfiguration.swift` and `Sources/Resting/Client/RestClient.swift`
- [ ] T012 [P] [US1] Implement specialized typed request entry points in `Sources/Resting/Requests/RequestDefinition.swift` and `Sources/Resting/Requests/RequestBody.swift`
- [ ] T013 [US1] Wire async raw and decoded execution through `Sources/Resting/Client/RestClient.swift`, `Sources/Resting/Responses/ResponsePayload.swift`, and `Sources/Resting/Responses/ResponseValidator.swift`
- [ ] T014 [US1] Update the primary async usage guidance and symbol docs in `README.md`, `specs/001-modernize-public-api/quickstart.md`, `Sources/Resting/Client/RestClient.swift`, and `Sources/Resting/Requests/RequestDefinition.swift`

**Checkpoint**: User Story 1 is a usable MVP with a documented async-first client experience.

---

## Phase 4: User Story 2 - Broader Public Capability (Priority: P2)

**Goal**: Add typed failure mapping, Combine compatibility, and isolated transfer ownership so common request and download scenarios are covered consistently.

**Independent Test**: A consumer can exercise async, Combine, download, cancellation, and representative failure flows and observe one typed error model plus isolated per-operation transfer behavior.

### Tests for User Story 2

- [ ] T015 [P] [US2] Add typed error-mapping and cancellation coverage in `Tests/RestingTests/Errors/RestingErrorMappingTests.swift`
- [ ] T016 [P] [US2] Add Combine compatibility and overlapping transfer coverage in `Tests/RestingTests/Client/RestClientCombineTests.swift` and `Tests/RestingTests/Transfers/TransferHandleTests.swift`

### Implementation for User Story 2

- [ ] T017 [P] [US2] Implement canonical failure mapping for transport, invalid response, status code, decoding, cancellation, and file handling in `Sources/Resting/Support/RestingError.swift`, `Sources/Resting/Responses/ResponseValidator.swift`, and `Sources/Resting/Client/RestClient.swift`
- [ ] T018 [P] [US2] Implement Combine compatibility APIs on the shared execution pipeline in `Sources/Resting/Client/RestClient+Combine.swift` and `Sources/Resting/Client/RestClient.swift`
- [ ] T019 [P] [US2] Implement per-operation download ownership, progress observation, and cancellation in `Sources/Resting/Transfers/TransferHandle.swift` and `Sources/Resting/Client/RestClient.swift`
- [ ] T020 [US2] Document failure semantics, Combine usage, transfer lifecycle behavior, and localized messaging updates in `README.md`, `specs/001-modernize-public-api/quickstart.md`, `Sources/Resting/Transfers/TransferHandle.swift`, `Sources/Resting/Resources/en.lproj/Localizable.strings`, and `Sources/Resting/Resources/tr.lproj/Localizable.strings`

**Checkpoint**: User Stories 1 and 2 now cover the primary public request, response, download, cancellation, and failure flows.

---

## Phase 5: User Story 3 - Maintainable Package Structure (Priority: P3)

**Goal**: Finalize the domain-oriented package structure, remove legacy naming, and publish migration guidance that makes future maintenance straightforward.

**Independent Test**: A maintainer can map each changed public behavior to one obvious source/test area, verify localization coverage, and review migration guidance without tracing through the old flat layout.

### Tests for User Story 3

- [ ] T021 [P] [US3] Split legacy behavior coverage into domain-aligned suites in `Tests/RestingTests/Client/RestClientAsyncTests.swift`, `Tests/RestingTests/Client/RestClientCombineTests.swift`, `Tests/RestingTests/Requests/RequestDefinitionTests.swift`, and `Tests/RestingTests/Transfers/TransferHandleTests.swift`
- [ ] T022 [P] [US3] Add localization regression coverage for every public error case in `Tests/RestingTests/Localization/LocalizationResourceTests.swift`

### Implementation for User Story 3

- [ ] T023 [P] [US3] Finalize the domain-oriented source layout in `Sources/Resting/Client/RestClient.swift`, `Sources/Resting/Client/RestClientConfiguration.swift`, `Sources/Resting/Client/RestClient+Combine.swift`, `Sources/Resting/Requests/HTTPMethod.swift`, `Sources/Resting/Requests/RequestDefinition.swift`, `Sources/Resting/Requests/RequestBody.swift`, `Sources/Resting/Responses/ResponsePayload.swift`, `Sources/Resting/Responses/ResponseValidator.swift`, `Sources/Resting/Transfers/TransferHandle.swift`, and `Sources/Resting/Support/RestingError.swift`
- [ ] T024 [US3] Remove obsolete legacy files and test suites in `Sources/Resting/Resting.swift`, `Sources/Resting/RequestConfiguration.swift`, `Sources/Resting/RestingError.swift`, `Sources/Resting/Extensions/URLSession+Helper.swift`, `Sources/Resting/Extensions/URLComponents+Helper.swift`, `Sources/Resting/DataWithURLResponse.swift`, `Tests/RestingTests/RestClientTests.swift`, `Tests/RestingTests/RestClientWithFailureTests.swift`, `Tests/RestingTests/RequestConfigurationTests.swift`, and `Tests/RestingTests/LocalizationTests.swift`
- [ ] T025 [US3] Write breaking-change migration guidance and maintainer release notes in `README.md` and `specs/001-modernize-public-api/contracts/public-api.md`

**Checkpoint**: The package structure, naming, tests, and migration notes reflect the modernized public domain cleanly.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish documentation, platform review, localization parity, and end-to-end validation across the completed stories.

- [ ] T026 [P] Refresh installation, upgrade, and migration sections in `README.md` and `specs/001-modernize-public-api/contracts/public-api.md`
- [ ] T027 [P] Verify platform availability and `FoundationNetworking` coverage in `Package.swift`, `Sources/Resting/Client/RestClient.swift`, and `Sources/Resting/Support/FoundationNetworkingSupport.swift`
- [ ] T028 [P] Polish public documentation comments and naming consistency in `Sources/Resting/Client/RestClient.swift`, `Sources/Resting/Requests/RequestDefinition.swift`, `Sources/Resting/Transfers/TransferHandle.swift`, and `Sources/Resting/Support/RestingError.swift`
- [ ] T029 [P] Audit English and Turkish resource parity in `Sources/Resting/Resources/en.lproj/Localizable.strings` and `Sources/Resting/Resources/tr.lproj/Localizable.strings`
- [ ] T030 Run the end-to-end quickstart validation and apply any last documentation fixes in `specs/001-modernize-public-api/quickstart.md` and `README.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup**: No dependencies and can start immediately
- **Phase 2: Foundational**: Depends on Phase 1 and blocks all user story work
- **Phase 3: User Story 1**: Starts after Phase 2 and produces the MVP
- **Phase 4: User Story 2**: Starts after Phase 2; on a single-developer track it is safest after US1 because both stories extend `Sources/Resting/Client/RestClient.swift`
- **Phase 5: User Story 3**: Starts after US1 and US2 because it finalizes the reorganized source/test layout around the implemented public surface
- **Phase 6: Polish**: Starts after all desired user stories are complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Foundational work
- **US2 (P2)**: Depends on Foundational work; shares `Sources/Resting/Client/RestClient.swift` with US1
- **US3 (P3)**: Depends on US1 and US2 because migration notes and legacy-file removal require the final public API to be in place

### Within Each User Story

- Tests must be written and fail before implementation tasks start
- Shared type additions should land before higher-level client wiring
- Public docs and localization updates should happen after the implementation is functionally correct
- Each story must pass its independent validation before moving to the next priority

## Parallel Opportunities

- `T003` can run in parallel with `T002` after `T001`
- `T005`, `T006`, and `T007` can run in parallel after `T004`
- `T009` and `T010` can run in parallel for US1
- `T011` and `T012` can run in parallel for US1 before `T013`
- `T015` and `T016` can run in parallel for US2
- `T017`, `T018`, and `T019` can run in parallel once the shared failure and execution contracts are stable
- `T021` and `T022` can run in parallel for US3
- `T026`, `T027`, `T028`, and `T029` can run in parallel before `T030`

## Parallel Example: User Story 1

```bash
# Write the US1 tests together
Task T009: Tests/RestingTests/Requests/RequestDefinitionTests.swift
Task T010: Tests/RestingTests/Client/RestClientAsyncTests.swift

# Implement the independent US1 building blocks together
Task T011: Sources/Resting/Client/RestClientConfiguration.swift + Sources/Resting/Client/RestClient.swift
Task T012: Sources/Resting/Requests/RequestDefinition.swift + Sources/Resting/Requests/RequestBody.swift
```

## Parallel Example: User Story 2

```bash
# Write the US2 tests together
Task T015: Tests/RestingTests/Errors/RestingErrorMappingTests.swift
Task T016: Tests/RestingTests/Client/RestClientCombineTests.swift + Tests/RestingTests/Transfers/TransferHandleTests.swift

# Implement the main US2 features together
Task T018: Sources/Resting/Client/RestClient+Combine.swift
Task T019: Sources/Resting/Transfers/TransferHandle.swift
```

## Parallel Example: User Story 3

```bash
# Write the US3 validation together
Task T021: domain-aligned test files under Tests/RestingTests/Client/, Requests/, and Transfers/
Task T022: Tests/RestingTests/Localization/LocalizationResourceTests.swift

# Finish the structural cleanup together
Task T023: domain-oriented source files under Sources/Resting/
Task T025: README.md + specs/001-modernize-public-api/contracts/public-api.md
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate the async-first quickstart and request-definition flows before expanding scope

### Incremental Delivery

1. Land Setup + Foundational to stabilize the package structure, mocks, and failure model
2. Deliver US1 as the first public-facing MVP
3. Add US2 to cover Combine, transfer ownership, and richer failure handling
4. Finish US3 to remove legacy structure and publish migration guidance
5. Run Phase 6 polish tasks before release

### Parallel Team Strategy

1. One developer owns package/setup work in `Package.swift` and `Sources/Resting/Support/`
2. One developer owns request/client API work in `Sources/Resting/Client/` and `Sources/Resting/Requests/`
3. One developer owns transfer/error/localization work in `Sources/Resting/Transfers/`, `Sources/Resting/Resources/`, and the corresponding tests

---

## Notes

- MVP scope is **User Story 1** after Setup and Foundational phases complete.
- The legacy flat files remain useful as migration references until `T024` removes them.
- Every task above follows the required checklist format: checkbox, task ID, optional `[P]`, optional story label, and explicit file paths.
