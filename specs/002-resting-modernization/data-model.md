# Data Model: Resting Modernization Follow-Up

**Feature**: `002-resting-modernization`  
**Date**: 2026-08-15

## Overview

These are in-memory networking and lifecycle models, not persisted records.
The feature changes their validation and ownership guarantees without adding a
new public model.

## Download Outcome

**Fields**:

- `fileURL`: present only for a validated 2xx response
- `failure`: one `RestingError` when no file URL is produced
- `response`: final optional `URLResponse` used during validation
- `errorData`: optional bytes read from a rejected temporary download

**Relationships**:

- One outcome resolves one `TransferHandle`.
- Response validation creates either the successful file URL or the typed
  failure, never both.

**Validation rules**:

- Only final HTTP status `200..<300` may produce `fileURL`.
- Missing or non-HTTP responses produce `.invalidResponse`.
- Other HTTP statuses produce `.statusCode(code, errorData)`.
- Error-body read failure leaves `errorData` absent and does not replace the
  status failure.
- A rejected temporary file is removed best-effort and no library destination
  is created.

## Response Context

**Fields**:

- `httpResponse`: valid final `HTTPURLResponse` for successful payloads
- `statusCode`: integer carried by status failures
- `bodyData`: optional bytes carried by status and decoding failures
- `underlyingError`: decoding or transport cause when applicable

**Relationships**:

- The internal validator creates validated HTTP response context for async,
  Combine, and download paths.
- Async and Combine decoding use the same raw payload bytes when mapping a
  decoding failure.

**Validation rules**:

- Success acceptance is fixed to `200..<300` and is not consumer-configurable.
- Equivalent fixtures produce the same `RestingError` case and available data
  across async and Combine execution.
- Empty or unavailable error bodies are represented as `nil`.

## Client Session Lifecycle

**Fields**:

- `configuration`: immutable client configuration snapshot
- `session`: one eagerly created `URLSession`
- `delegate`: one private download delegate with no client back-reference
- `transferRegistry`: lock-protected mapping from task identifier to handle

**Relationships**:

- One `RestClient` owns one session and delegate.
- URLSession retains the delegate until invalidation.
- The delegate owns active transfer routing state, not the client.
- A stored Combine publisher retains the client until the publisher and active
  subscription are released.

**Validation rules**:

- Session creation completes before the client is published to concurrent
  callers.
- Concurrent first use observes the same session identity.
- The delegate never retains the client.
- Delayed subscription remains safe after direct client references are released.
- Releasing the final client reference begins graceful session invalidation;
  no consumer shutdown call is required.
- Active operations may keep their required session/delegate state until they
  resolve, after which the session and delegate become releasable.

**State transitions**:

- `initialized -> active` when an operation starts
- `initialized -> invalidating` when an unused client is released
- `active -> invalidating` when the client is released with active work
- `invalidating -> invalidated` after outstanding tasks complete and delegate
  callbacks finish

## Operation State

**Fields**:

- `id`: stable per-handle UUID
- `taskIdentifier`: internal URLSession routing key
- `progress`: progress for this operation only
- `task`: weak reference used for per-operation cancellation
- `result`: one eventual file URL or typed failure
- `state`: initialized, running, completed, failed, or cancelled

**Relationships**:

- One registry entry maps one task identifier to one handle.
- Registration occurs before the task resumes.
- Completion removes only the matching entry and clears only that handle's
  task reference.

**Validation rules**:

- Progress, observer callbacks, cancellation, and result are isolated per
  handle.
- Cancellation calls only the matching task.
- State and result resolve once even when cancellation, validation, file move,
  and completion callbacks race.
- User callbacks and continuations run after internal locks are released.

**State transitions**:

- `initialized -> running`
- `running -> completed`
- `running -> failed`
- `running -> cancelled`
- Any later terminal transition is ignored.
