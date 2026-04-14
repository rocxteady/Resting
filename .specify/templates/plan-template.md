# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Swift 6.2 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., Foundation, Combine, XCTest or NEEDS CLARIFICATION]  
**Storage**: [e.g., N/A, files, Keychain or NEEDS CLARIFICATION]  
**Testing**: [e.g., XCTest unit tests, Swift Testing, deterministic mocks or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., iOS 17+, macOS 14+, watchOS 10+, tvOS 17+, visionOS 1+ or NEEDS CLARIFICATION]
**Project Type**: [e.g., Swift Package library, app, service or NEEDS CLARIFICATION]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [ ] Swift 6.2 + SPM: The solution fits the Swift Package layout and does not
      introduce non-SPM tooling without explicit justification.
- [ ] Strict concurrency: Actor isolation, `Sendable`, cancellation, and async
      boundaries are explicit; any escape hatch is isolated and justified.
- [ ] Simplicity: The design avoids speculative abstraction, unnecessary
      indirection, and hidden state; extra complexity is captured below.
- [ ] Public API docs: Every public API addition or change has documentation
      comments and usage notes planned.
- [ ] Tests, platforms, localization: Unit tests are identified, platform impact
      is reviewed for iOS/macOS/watchOS/tvOS/visionOS, and localization impact
      is noted for any user-facing string changes.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Keep the delivered plan aligned with the real Swift Package
  structure used by the repository.
-->

```text
Package.swift
Sources/
└── Resting/
    ├── Extensions/
    └── Resources/
        ├── en.lproj/
        └── tr.lproj/

Tests/
└── RestingTests/
    └── Mocks/
```

**Structure Decision**: [Describe which files in `Sources/Resting` and
`Tests/RestingTests` will change, and justify any new folders or targets]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
