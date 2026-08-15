<!--
Sync Impact Report
Version change: 1.0.0 -> 1.0.1
Modified principles:
- I. Swift 6.2 and Strict Concurrency -> I. Swift 6.3 and Strict Concurrency
Added sections:
- None
Removed sections:
- None
Templates requiring updates:
- ✅ reviewed: no template changes required for the toolchain baseline update
Follow-up TODOs:
- None; 002-resting-modernization aligned `Package.swift` and CI with Swift 6.3
-->
# Resting Constitution

## Core Principles

### I. Swift 6.3 and Strict Concurrency
All production and test code MUST target Swift 6.3 in Swift Package Manager and
MUST be designed for the most recent strict concurrency enforcement available in
the toolchain used by the project. Actor isolation, `Sendable` conformance,
cancellation, and async boundaries MUST be explicit in API and implementation
design; any compatibility shim that weakens these guarantees MUST be isolated
and documented. Rationale: this library is a general-purpose REST client, so
concurrency correctness is part of the product contract, not an optional
cleanup task.

### II. Simplicity Over Abstraction
The library MUST prefer small types, direct control flow, and standard
library/Foundation facilities over speculative layers, deep protocol stacks, or
indirection added for hypothetical reuse. New abstractions MUST be introduced
only when at least two concrete use cases require them or when they remove
measurable duplication without hiding behavior. Rationale: maintainability,
readability, and ease of use depend on keeping the design obvious.

### III. Documented Public API
Every public symbol MUST include Swift documentation comments that explain
purpose, parameters, return values, thrown errors, and notable platform or
concurrency behavior. Public API changes MUST preserve naming clarity, default
ergonomics, and straightforward discovery in Xcode code completion; breaking
changes MUST be called out in the specification, plan, and release notes.
Rationale: a library is only easy to use when its public surface is
self-explanatory.

### IV. Test-Backed Behavior
Every feature, fix, and behavioral change MUST add or update unit tests under
`Tests/RestingTests` before merge. Tests MUST cover request construction,
response decoding, error mapping, and async/cancellation edge cases whenever
those behaviors are affected; external live network dependencies in tests are
forbidden, so mocks or deterministic fixtures are required. Rationale:
networking code fails at the edges first, and repeatable tests are the primary
defense against regressions.

### V. Platform and Localization Discipline
The package MUST remain SPM-first and MUST evaluate compatibility for iOS,
macOS, watchOS, tvOS, and visionOS whenever the Apple platform APIs make that
support practical. `defaultLocalization` MUST remain `en`; every new
user-facing or localized string MUST ship with English resources first and MUST
not regress existing locale behavior, while platform-specific code MUST be
availability-gated and kept minimal. Rationale: a general-purpose client
library should have predictable platform reach and predictable language
fallback.

## Technical Standards

- The package manager MUST remain Swift Package Manager, and the primary library
  product MUST remain `Resting` unless a specification justifies adding new
  targets or products.
- Source code MUST live under `Sources/Resting`, tests MUST live under
  `Tests/RestingTests`, and new folders SHOULD mirror public API areas rather
  than implementation fashion.
- Dependencies SHOULD remain minimal and default to Apple-provided frameworks
  unless an external dependency removes clear, recurring complexity.
- English is the authoritative documentation language for code comments,
  developer documentation, and default localized resources.

## Workflow & Quality Gates

- Every implementation plan MUST pass a constitution check covering Swift 6.3,
  strict concurrency, simplicity, public API documentation, tests, platform
  impact, and localization impact.
- Every specification MUST state public API impact, concurrency impact, platform
  impact, and localization impact when behavior changes.
- Every task list MUST include unit-test work, public documentation work for
  changed public APIs, and localization work when strings change.
- Code review MUST reject undocumented public API, unnecessary abstraction,
  hidden mutable global state, and concurrency escapes without written
  justification.
- README and package metadata MUST be updated when installation, platform
  support, or public usage materially changes.

## Governance

This constitution overrides informal project preferences. Amendments MUST be
made in a documented change that updates this file and any affected templates or
guidance in the same change set.

Versioning policy for this constitution follows semantic versioning:
- MAJOR: a principle or governance rule is removed or redefined in a
  backward-incompatible way.
- MINOR: a new principle or materially expanded mandatory guidance is added.
- PATCH: wording is clarified without changing the required behavior.

Compliance review is mandatory for every specification, plan, task list, and
code review. Any temporary deviation MUST be recorded in the relevant plan or
review with the reason, scope, and removal path before implementation proceeds.

**Version**: 1.0.1 | **Ratified**: 2026-04-14 | **Last Amended**: 2026-08-14
