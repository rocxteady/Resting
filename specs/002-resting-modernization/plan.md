# Implementation Plan: Resting Modernization Follow-Up

**Branch**: `002-resting-modernization` | **Date**: 2026-08-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-resting-modernization/spec.md`

## Summary

Close only the verified modernization gaps: make a fixed internal 2xx validator
the single response contract for async, Combine, and downloads; validate a
download before moving its temporary file; preserve response data on decoding
failures; and replace the racy, self-delegating lazy session with one eagerly
created session plus a private lock-protected download delegate. Upgrade the
manifest and release checks to Swift 6.3 while preserving the existing public
surface except for removal of the unusable `ResponseValidator` type.

## Technical Context

**Language/Version**: Swift 6.3; `Package.swift` currently declares Swift tools 6.2 and will move to 6.3  
**Primary Dependencies**: Foundation, FoundationNetworking where required by platform, Combine, XCTest; no third-party runtime dependencies  
**Storage**: Temporary download files plus localized resources under `Sources/Resting/Resources`; no persistent store  
**Testing**: XCTest with deterministic `URLProtocol` fixtures, async/cancellation/lifetime regressions, Combine parity checks, and generic Apple-platform compilation  
**Target Platform**: iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, and visionOS 1+  
**Project Type**: Swift Package library  
**Performance Goals**: Preserve streaming download behavior, avoid reading successful downloads into memory, and resolve every operation exactly once under overlap or cancellation  
**Constraints**: SPM remains authoritative; fixed `200..<300` validation only; no new shutdown API, runtime dependency, target, product, deployment-minimum change, or named-simulator release dependency  
**Scale/Scope**: One library target, one test target, two localizations, three execution styles, and five Apple platform families

## Constitution Check

*GATE: Passed before Phase 0 research and re-checked after Phase 1 design.*

- [x] **Swift 6.3 and strict concurrency**: The manifest moves to Swift 6.3;
  session creation becomes immutable and race-free; shared delegate and
  transfer state stays behind a compatible lock; Sendable escape hatches are
  limited to private, documented invariants when compiler proof is unavailable.
- [x] **Simplicity over abstraction**: One existing validator is made internal,
  one private delegate owns the state required by URLSession callbacks, and no
  configurable validation, actor facade, operation manager, or new target is
  introduced.
- [x] **Documented public API**: Existing public symbols receive precise
  validation, concurrency, lifecycle, return, and error documentation;
  `ResponseValidator` removal is recorded in the contract and README migration
  guidance.
- [x] **Test-backed behavior**: Deterministic XCTest coverage proves download
  rejection and cleanup, async/Combine parity, concurrent first use,
  cancellation isolation, exactly-once completion, and automatic deallocation.
- [x] **Platform and localization discipline**: CI runs the SPM test suite and
  generic compilation for all five declared platform families. English and
  Turkish resources remain unchanged unless implementation changes error copy,
  in which case both resources and localization tests change together.

**Post-design re-check**: Passed. The data model and public contract introduce
no persistence, dependencies, products, platform changes, user-managed
lifecycle, validation customization, or undocumented public replacement.

## Project Structure

### Documentation (this feature)

```text
specs/002-resting-modernization/
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
.github/workflows/swift.yml
Sources/Resting/
├── Client/
│   ├── RestClient.swift
│   ├── RestClient+Combine.swift
│   └── RestClientConfiguration.swift
├── Responses/
│   ├── ResponsePayload.swift
│   └── ResponseValidator.swift
├── Support/
│   ├── RestingError.swift
│   └── URLSessionExecutor.swift
└── Transfers/
    └── TransferHandle.swift

Tests/RestingTests/
├── Client/
├── Errors/
├── Localization/
├── Mocks/
├── Support/
└── Transfers/
```

**Structure Decision**: Keep the established single-target domain layout.
Implement the private download delegate beside `RestClient` because it exists
only to provide that client's URLSession ownership boundary. Retain
`ResponseValidator.swift` as the internal shared rule rather than duplicating
guards across execution styles. Add no source folder, package target, or
standalone migration document.

## Complexity Tracking

No constitution violations require justification.
