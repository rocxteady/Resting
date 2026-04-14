# Contract: Public API Modernization

**Feature**: `001-modernize-public-api`  
**Date**: 2026-04-14

## Contract Scope

This contract defines the intended public package surface for the modernized
`Resting` release. It is a design contract for implementation and task
generation, not a guarantee that the current checked-in code already satisfies
it.

## Public Types

### Client

- The package exposes one primary client type, `RestClient`.
- `RestClient` is initialized with a value-typed `RestClientConfiguration`.
- Client instances may execute multiple overlapping operations safely.

### Request Definitions

- The package exposes a typed request-definition model rather than relying on
  `[String: Any]` payloads as the canonical public API.
- The public API keeps multiple specialized request-construction entry points
  for distinct request styles:
  - Query-based requests
  - Form-encoded requests
  - JSON-body requests
  - Raw-body requests
  - Download-oriented requests
- Each specialized entry point must document when to use it and which headers or
  encodings it applies automatically.

### Error Model

- All public execution paths use the same typed `RestingError` contract.
- Typed failures must cover:
  - Invalid request construction
  - Transport failure
  - Invalid or non-HTTP response
  - Unacceptable status code
  - Decoding failure
  - Cancellation
  - Transfer/file-system failure

## Execution Contracts

### Async Data Execution

- The package exposes an async API for executing a request and returning raw
  data or a response wrapper.
- The async API throws `RestingError` for known package failures.
- Async execution is the primary documented usage path in README and symbol
  documentation.

### Async Decoding Execution

- The package exposes an async API for executing a request and decoding a
  `Decodable` response.
- Decoding failures are mapped into the typed public error model instead of
  surfacing as unclassified errors.

### Combine Compatibility Execution

- The package exposes Combine publisher APIs for raw and decoded execution.
- Publisher-based APIs adapt the same request pipeline and error model as async
  execution.
- Combine remains a secondary compatibility surface, not the primary design
  center for naming or documentation.

### Transfer Execution

- Downloads or other cancellable transfer flows return a per-operation handle.
- The handle owns:
  - Cancellation
  - Progress observation
  - Completion or result retrieval
- Overlapping transfers must not share hidden mutable client state.

## Behavioral Guarantees

- Successful request execution requires an HTTP status code in the 2xx range
  unless the API explicitly documents a different validation strategy.
- Non-HTTP responses are treated as invalid responses.
- Cancelling an operation results in a typed cancellation failure for that
  operation only.
- A failure in one operation must not alter another active operation's progress,
  completion, or cancellation state.

## Documentation and Migration Contracts

- Every public symbol added or changed by this feature must include Swift
  documentation comments.
- The README must document:
  - Installation requirements
  - The primary async request flow
  - Secondary Combine compatibility usage
  - Transfer/cancellation usage
  - Error handling expectations
- Every breaking change from the legacy API must be documented with migration
  guidance before release.

## Migration Notes

- `RequestConfiguration` is replaced by `RequestDefinition`.
- `fetch(with:)` is replaced by `execute(_:)`, `executeData(_:)`, and `execute(_:as:)`.
- Request construction now uses explicit `.query`, `.form`, `.json`, `.jsonData`, `.raw`, and `.download` entry points.
- Client-global download callbacks and cancellation are replaced by per-operation `TransferHandle` instances.
- Legacy error handling based on `urlMalformed`, `wrongParameterType`, and `unknown` is replaced by the canonical `RestingError` contract.

## Release Notes Summary

- Swift tools version upgraded to 6.2 and `visionOS` support reviewed in the package manifest.
- Source and tests reorganized by domain under `Client`, `Requests`, `Responses`, `Transfers`, and `Support`.
- Async/await is now the primary documented API, with Combine maintained as a compatibility layer.
- Downloads now use isolated handles with independent progress and cancellation lifecycles.
- English and Turkish error resources were refreshed to match the new error model.

## Test Contracts

- Unit tests must cover:
  - Request construction for each public request style
  - Successful async raw and decoded execution
  - Successful Combine raw and decoded execution
  - Typed error mapping for transport, status-code, invalid-response, decoding,
    and cancellation failures
  - Concurrent transfer isolation and per-handle cancellation
  - Localization presence for user-facing error text
