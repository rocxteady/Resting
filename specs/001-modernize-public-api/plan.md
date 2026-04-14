# Implementation Plan: Public API Modernization

**Branch**: `001-modernize-public-api` | **Date**: 2026-04-14 | **Spec**: [/Users/ulas.sancak/Desktop/Projects/Personal/Resting/specs/001-modernize-public-api/spec.md](/Users/ulas.sancak/Desktop/Projects/Personal/Resting/specs/001-modernize-public-api/spec.md)
**Input**: Feature specification from `/Users/ulas.sancak/Desktop/Projects/Personal/Resting/specs/001-modernize-public-api/spec.md`

## Summary

Modernize `Resting` into a Swift 6.2, strict-concurrency-ready Swift Package
with an async/await-first public API, typed request and error contracts,
per-operation download ownership, clearer source/test organization, and
release-grade documentation plus migration guidance. Keep Combine as a
secondary compatibility surface backed by the same core request execution path.

## Technical Context

**Language/Version**: Swift 6.2 planning target; current package manifest is `swift-tools-version: 5.8` and must be upgraded during implementation  
**Primary Dependencies**: Foundation, FoundationNetworking where required by platform, Combine, XCTest; no third-party runtime dependencies planned  
**Storage**: N/A beyond temporary file handling for download flows and localized string resources in `Sources/Resting/Resources`  
**Testing**: XCTest unit tests with deterministic `URLProtocol` mocks, async/cancellation coverage, request-building assertions, decoding/error-mapping validation, and localization regression checks  
**Target Platform**: Swift Package for Apple platforms; current manifest supports iOS 15+, macOS 12+, watchOS 8+, tvOS 15+ and the modernization must review present-day support plus visionOS compatibility  
**Project Type**: Swift Package library  
**Performance Goals**: Preserve predictable request overhead, eliminate shared mutable operation state, and keep overlapping request/download behavior deterministic under concurrent use  
**Constraints**: Remain SPM-first, keep dependencies minimal, expose async/await as the primary documented surface, retain Combine compatibility APIs, provide English-first localization updates, and document all source-breaking public API changes  
**Scale/Scope**: One library target, one test target, two current localization bundles, six current source files, and a broad public API redesign spanning request construction, execution, transfers, errors, docs, and source organization

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Swift 6.2 + SPM: The plan keeps a single Swift Package product/target and upgrades manifest/toolchain expectations instead of introducing alternate build tooling.
- [x] Strict concurrency: Async-first APIs, explicit cancellation ownership, typed failures, and removal of client-global download state are part of the design baseline.
- [x] Simplicity: The redesign centers on a small set of public domain types and a shared execution pipeline rather than protocol-heavy indirection.
- [x] Public API docs: Public symbol documentation, README updates, and migration guidance are treated as implementation requirements rather than follow-up work.
- [x] Tests, platforms, localization: The plan includes XCTest coverage for request, response, error, and cancellation behavior, reviews Apple platform support including visionOS, and preserves English-first localized messaging.

## Project Structure

### Documentation (this feature)

```text
specs/001-modernize-public-api/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── public-api.md
└── tasks.md
```

### Source Code (repository root)

```text
Package.swift
README.md
Sources/
└── Resting/
    ├── Client/
    ├── Requests/
    ├── Responses/
    ├── Transfers/
    ├── Support/
    └── Resources/
        ├── en.lproj/
        └── tr.lproj/

Tests/
└── RestingTests/
    ├── Client/
    ├── Requests/
    ├── Transfers/
    ├── Errors/
    ├── Localization/
    └── Mocks/
```

**Structure Decision**: Replace the current flat layout (`Resting.swift`,
`RequestConfiguration.swift`, `RestingError.swift`, helper extensions) with
domain-oriented folders that mirror the public API areas. Keep a single library
target, but split request definition, response validation, transfer lifecycle,
and support helpers into separate files so each public behavior maps to one
obvious source area and one obvious test area. Existing localized resources
remain under `Sources/Resting/Resources`, while tests are reorganized around
public behavior instead of legacy file names.

## Complexity Tracking

No constitution violations are expected. If implementation requires a temporary
compatibility shim for old public symbols, it must stay isolated and be
documented in migration guidance rather than changing the overall architecture.
