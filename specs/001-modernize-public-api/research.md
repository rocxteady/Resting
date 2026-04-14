# Research: Public API Modernization

**Feature**: `001-modernize-public-api`  
**Date**: 2026-04-14

## Decision 1: Make async/await the canonical execution model and keep Combine as an adapter layer

**Decision**: The new public surface will be designed around async/await
execution first. Combine publishers will remain publicly available, but they
will adapt the same underlying request pipeline instead of driving the design.

**Rationale**: The clarified feature direction explicitly makes async/await the
primary documented API. The current package already exposes async/await and
Combine, but both are treated as peer surfaces. Centering the design on async
execution makes concurrency rules, cancellation, and typed error mapping easier
to express once, then reuse for Combine compatibility.

**Alternatives considered**:
- Keep async/await and Combine as equal-first-class entry points. Rejected
  because it preserves duplicated API-design pressure and makes documentation
  less opinionated.
- Remove Combine entirely. Rejected because the specification requires
  retaining Combine compatibility APIs during modernization.

## Decision 2: Replace untyped request payload configuration with typed request definitions

**Decision**: The redesigned API should move away from `[String: Any]` plus raw
`Data` overloads on a single `RequestConfiguration` shape and instead expose a
typed request definition model with explicit specialized constructors for
query-based, form-encoded, JSON, raw-data, and download-oriented requests.

**Rationale**: The current `RequestConfiguration` stores mixed body state behind
an internal enum and relies on runtime checks like `wrongParameterType`. That
shape is hard to document cleanly and encourages ambiguous usage. Specialized
typed request entry points satisfy the clarification that multiple public
request-construction styles should remain available, while making the choice
between them explicit.

**Alternatives considered**:
- Keep the current overloads and improve documentation only. Rejected because
  the ambiguity is structural, not purely editorial.
- Collapse everything into a single builder. Rejected because the specification
  explicitly preserves multiple specialized request entry points.

## Decision 3: Use one richer public error model across request, decode, and transfer flows

**Decision**: Define a canonical public error enum that covers invalid request
construction, transport failures, invalid or missing HTTP responses,
unacceptable status codes, decoding failures, cancellation, and transfer/file
handling failures.

**Rationale**: The current `RestingError` is too small for a modern public API.
It conflates unrelated failures into `unknown`, treats cancellation outside the
typed failure contract, and leaves decoding failures to surface as unrelated
errors. A richer error model is required by the specification and is necessary
to keep async, Combine, and transfer flows behaviorally aligned.

**Alternatives considered**:
- Continue exposing `Error` publicly from some entry points. Rejected because it
  undermines the requirement for one canonical failure contract.
- Wrap all underlying errors in a single opaque case. Rejected because it
  reduces actionable diagnostics and weakens migration/documentation value.

## Decision 4: Give each transfer its own lifecycle handle

**Decision**: Downloads and other cancellable long-running operations will
return a per-operation handle or task-like abstraction that owns its progress,
completion, and cancellation state independently.

**Rationale**: The current `RestClient` stores one shared download task,
progress callback, and completion callback on the client instance. That design
cannot safely support overlapping operations and directly violates the feature's
concurrency and cancellation requirements. Per-operation ownership removes
hidden global mutable state from the public lifecycle model.

**Alternatives considered**:
- Keep one client-global transfer state and document single-operation limits.
  Rejected because the specification requires concurrent operation isolation.
- Expose raw `URLSessionTask` directly. Rejected because it leaks low-level
  behavior without a clear typed progress and failure contract.

## Decision 5: Reorganize source and tests by public domain, not by helper type

**Decision**: Keep a single package target, but split the codebase into folders
and files that match the public concepts: client, requests, responses,
transfers, errors/support, and localized resources. Mirror those areas in
`Tests/RestingTests`.

**Rationale**: The current codebase is small but flat, with major behaviors
mixed into `Resting.swift` and helper extensions that are hard to map back to
public responsibilities. A domain-first layout improves discoverability for
maintainers without introducing extra targets or speculative abstractions.

**Alternatives considered**:
- Keep the flat layout and only rename files. Rejected because the spec asks for
  maintainable structure improvement, not cosmetic churn.
- Split into many package targets. Rejected because the package is too small to
  justify extra target boundaries right now.

## Decision 6: Treat platform, documentation, and migration work as release requirements

**Decision**: The modernization will include a package-manifest review for
current Apple platform expectations, explicit visionOS evaluation, public API
documentation comments, README usage refresh, breaking-change migration notes,
and localization review for user-facing error strings.

**Rationale**: The constitution makes documentation, tests, platform review, and
English-first localization mandatory. The feature specification also states that
migration guidance is required for any breaking public API redesign. These
deliverables must be planned alongside code, not deferred.

**Alternatives considered**:
- Defer docs and migration notes until after code stabilization. Rejected
  because it would violate both the constitution and the feature requirements.
- Limit platform review to the existing manifest only. Rejected because the
  constitution explicitly requires present-day Apple platform evaluation.
