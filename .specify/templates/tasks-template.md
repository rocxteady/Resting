---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Unit tests are REQUIRED. Add integration, contract, or platform
coverage tasks when the feature or specification justifies them.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Swift package sources**: `Sources/Resting/`
- **Swift package tests**: `Tests/RestingTests/`
- **Mocks and fixtures**: `Tests/RestingTests/Mocks/`
- **Localized resources**: `Sources/Resting/Resources/`
- Adjust paths only if the plan explicitly adds a new target or package layout

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/
  
  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment
  
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Update `Package.swift` and package metadata if the feature changes
      platform support, products, or dependencies
- [ ] T002 Create or adjust source and test files under `Sources/Resting/` and
      `Tests/RestingTests/` per the implementation plan
- [ ] T003 [P] Configure or update linting, formatting, and CI steps if the
      feature requires them

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 Establish or extend shared request/response models and supporting
      types in `Sources/Resting/`
- [ ] T005 [P] Add or update deterministic mocks, fixtures, or helpers in
      `Tests/RestingTests/Mocks/`
- [ ] T006 [P] Define availability handling, error mapping, and concurrency
      boundaries needed by all stories
- [ ] T007 Identify public API documentation updates required across the change
- [ ] T008 Confirm localization resource impact in
      `Sources/Resting/Resources/`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Add or update unit tests in
      `Tests/RestingTests/[Feature]Tests.swift`
- [ ] T010 [P] [US1] Add concurrency, cancellation, or availability coverage
      when async behavior or platform gating changes

### Implementation for User Story 1

- [ ] T011 [P] [US1] Implement or update types in `Sources/Resting/[File].swift`
- [ ] T012 [US1] Wire the feature into the request/response flow and error
      handling paths
- [ ] T013 [US1] Add public documentation comments and availability annotations
      for changed public APIs
- [ ] T014 [US1] Update English localization resources if user-facing strings
      change

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 ⚠️

- [ ] T015 [P] [US2] Add or update unit tests in
      `Tests/RestingTests/[Feature]Tests.swift`
- [ ] T016 [P] [US2] Add concurrency, cancellation, or platform coverage if the
      story changes those behaviors

### Implementation for User Story 2

- [ ] T017 [P] [US2] Implement or update types in `Sources/Resting/[File].swift`
- [ ] T018 [US2] Integrate the story with shared request, response, and error
      handling components
- [ ] T019 [US2] Add public documentation comments, availability notes, and
      localization updates required by the story

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 ⚠️

- [ ] T020 [P] [US3] Add or update unit tests in
      `Tests/RestingTests/[Feature]Tests.swift`
- [ ] T021 [P] [US3] Add concurrency, cancellation, or platform coverage if the
      story changes those behaviors

### Implementation for User Story 3

- [ ] T022 [P] [US3] Implement or update types in `Sources/Resting/[File].swift`
- [ ] T023 [US3] Integrate the story with shared request, response, and error
      handling components
- [ ] T024 [US3] Add public documentation comments, availability notes, and
      localization updates required by the story

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in `README.md`, DocC, or public API comments
- [ ] TXXX Code cleanup and refactoring that removes unnecessary abstraction
- [ ] TXXX Performance optimization across affected request paths
- [ ] TXXX [P] Additional unit and platform coverage in `Tests/RestingTests/`
- [ ] TXXX Verify localization resources and supported-platform behavior
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Unit tests MUST be written and FAIL before implementation
- Shared types before higher-level feature wiring
- Core implementation before public API polish and localization updates
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Add or update unit tests in Tests/RestingTests/[Feature]Tests.swift"
Task: "Add concurrency, cancellation, or platform coverage for User Story 1"

# Launch independent implementation tasks for User Story 1 together:
Task: "Implement or update types in Sources/Resting/[File].swift"
Task: "Add public documentation comments and availability annotations"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify unit tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, undocumented public API changes, and
  cross-story dependencies that break independence
