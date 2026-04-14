# Data Model: Public API Modernization

**Feature**: `001-modernize-public-api`  
**Date**: 2026-04-14

## Overview

The feature redesigns the library around a small set of public domain models
instead of loosely coupled overloads and helper extensions. These entities are
contract models for the package API, not persisted storage records.

## Entities

### RestClientConfiguration

**Purpose**: Defines client-wide behavior shared by request execution.

**Fields**:
- `sessionConfiguration`: `URLSessionConfiguration`
- `decoder`: `JSONDecoder`
- `encoder`: `JSONEncoder` if the redesign supports typed encodable request
  bodies
- `defaultHeaders`: optional `[String: String]`

**Validation Rules**:
- Must remain value-typed and safe to reuse across multiple client instances.
- Defaults must be documented and avoid hidden mutable global state.

### RequestDefinition

**Purpose**: Canonical description of an outbound REST operation.

**Fields**:
- `url`: `URL`
- `method`: HTTP method enum
- `headers`: `[String: String]`
- `queryItems`: `[URLQueryItem]`
- `body`: request body enum
- `timeout`: optional request-specific timeout
- `cachePolicy`: optional request-specific cache policy

**Relationships**:
- Created by specialized request constructors or factory methods.
- Consumed by async, Combine, and transfer execution entry points.

**Validation Rules**:
- URL must be valid before execution begins.
- Query-oriented request constructors may not accept raw body payloads.
- Body encoding and `Content-Type` must align.
- Header merges must be deterministic when client defaults and per-request
  headers overlap.

### RequestBody

**Purpose**: Encodes the allowed body strategies without `[String: Any]`.

**Variants**:
- `none`
- `query([URLQueryItem])`
- `form([String: String])`
- `json(Data)`
- `encodable(Encodable)` or equivalent typed wrapper
- `raw(Data, contentType: String)`

**Validation Rules**:
- GET-style helpers should resolve to query items rather than an HTTP body by
  default.
- Encodable payloads must be encoded with the configured encoder before request
  execution.
- Raw bodies require an explicit content type.

### ResponsePayload<Value>

**Purpose**: Represents a successful result with both data and HTTP metadata.

**Fields**:
- `value`: decoded model or raw `Data`
- `response`: `HTTPURLResponse`
- `headers`: normalized response header view
- `statusCode`: `Int`

**Relationships**:
- Returned from async execution APIs.
- Feeds Combine publisher output for compatibility entry points.

**Validation Rules**:
- Only 2xx HTTP responses produce successful payloads by default.
- Non-HTTP responses map to typed failures.
- Decoding failures produce typed public errors with the response context
  retained when available.

### TransferHandle

**Purpose**: Represents one in-flight download or cancellable transfer.

**Fields**:
- `id`: stable operation identifier
- `task`: internal `URLSessionTask` reference or wrapped task state
- `progress`: observable progress channel or callback registration point
- `result`: async completion accessor or completion callback storage
- `state`: lifecycle enum

**Relationships**:
- Created per transfer-start call.
- Owns cancellation independent of the client or other handles.

**Validation Rules**:
- One handle maps to one underlying operation.
- Cancelling one handle must not cancel any unrelated operation.
- Progress updates must originate only from that handle's task.

**State Transitions**:
- `initialized -> running`
- `running -> completed`
- `running -> failed`
- `running -> cancelled`
- Terminal states are immutable once reached.

### RestingError

**Purpose**: Canonical public failure model shared across the package.

**Proposed Cases**:
- `invalidRequest(reason:)`
- `transport(URLError or wrapped Error)`
- `invalidResponse`
- `statusCode(Int, Data?)`
- `decoding(underlying:, Data?)`
- `cancelled`
- `fileSystem(underlying:)`

**Validation Rules**:
- Async, Combine, and transfer APIs must map equivalent failures to the same
  public case.
- Cancellation must not surface as `unknown`.
- Localized descriptions must remain complete in English and reviewed in
  Turkish when strings change.

### MigrationNote

**Purpose**: Documents how existing adopters move from legacy symbols to the
modernized API.

**Fields**:
- `legacySymbol`
- `replacement`
- `behaviorChange`
- `documentationSection`

**Validation Rules**:
- Every renamed or removed public symbol must have a matching migration note.
- Migration guidance must ship with the README/release documentation updates.
