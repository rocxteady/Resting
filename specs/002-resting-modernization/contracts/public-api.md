# Contract: Resting Modernization Follow-Up

**Feature**: `002-resting-modernization`  
**Date**: 2026-08-15

## Scope

This contract records the affected consumer-visible behavior. It preserves the
existing async-first API, Combine compatibility, request definitions, response
payloads, error cases, transfer handles, package structure, deployment minimums,
and lack of third-party runtime dependencies.

## Response Validation

- Async, Combine, and download execution accept only final HTTP status codes in
  `200..<300`.
- A missing or non-HTTP response fails with `RestingError.invalidResponse`.
- Another HTTP status fails with
  `RestingError.statusCode(statusCode, bodyData)`; body data is optional.
- Redirect handling uses the final response supplied by URLSession.
- Status acceptance is fixed and cannot be configured by consumers.

## Async and Combine Parity

- Equivalent response inputs produce the same success or `RestingError` case.
- Transport and cancellation failures retain their existing typed mapping.
- Status failures retain the same status and available body bytes.
- Decoding failures use `RestingError.decoding(underlying:data:)` and retain the
  raw response bytes when available, including an empty `Data` value for an
  empty successful body.
- Combine remains a secondary compatibility surface backed by the same
  response rule as async execution.

## Download Contract

- `RestClient.download(_:)` continues to return one `TransferHandle` per
  operation.
- A successful 2xx download preserves its existing progress, cancellation,
  destination-file, and async result behavior.
- A rejected response never yields a file URL.
- Validation occurs before a library destination is created.
- A rejected temporary file is removed best-effort; cleanup failure does not
  replace the primary response error.
- For non-2xx downloads, readable non-empty temporary bytes are retained as
  status error data; unavailable or empty bytes are `nil`.

## Concurrency and Lifecycle

- A client creates one session before it becomes available to callers.
- Concurrent first use and overlapping execution share that one session.
- Each transfer's progress, cancellation, state, and result are independent.
- Cancellation affects only the operation represented by the cancelled handle.
- Every handle resolves at most once when cancellation and completion race.
- Releasing the final external client reference requires no shutdown call.
- Client release gracefully invalidates its session; work already requiring the
  session may finish, after which the session and delegate deallocate.

## Public API Change

- `ResponseValidator` is removed from the public module surface.
- No replacement validator, status range, callback, policy protocol, or client
  configuration is introduced.
- Consumers that referenced the type must remove those references and rely on
  fixed default `200..<300` validation.
- All other named public surfaces in feature scope are preserved.

## Documentation and Localization

- Public client, publisher, transfer, response, and error documentation states
  relevant return, failure, concurrency, and lifecycle behavior.
- README is the migration guide for `ResponseValidator` removal and the release
  behavior changes.
- Existing English and Turkish error text remains unchanged unless the
  implementation changes user-facing copy; any such change must update both
  localizations and their regression tests together.

## Verification Contract

- Deterministic tests cover 2xx, non-2xx with and without body data, missing or
  non-HTTP responses, rejected-file cleanup, decoding parity, concurrent first
  use, overlapping operations, cancellation isolation, exactly-once terminal
  resolution, and eventual client/session release.
- The authoritative SPM suite passes under a Swift 6.3 toolchain.
- The package compiles for macOS and generic iOS, watchOS, tvOS, and visionOS
  destinations without selecting a named simulator.
