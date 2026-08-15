# Research: Resting Modernization Follow-Up

**Feature**: `002-resting-modernization`  
**Date**: 2026-08-15

## Decision 1: Keep one internal fixed-2xx response validator

**Decision**: Remove `ResponseValidator` from the public API and retain it as a
small internal rule used by async, Combine, and download execution. It accepts
an optional response and obtains error-body data only when a non-2xx status
needs that context.

**Rationale**: The current type is public but its operation is inaccessible,
while its configurable status range conflicts with the fixed `200..<300`
requirement. One internal rule prevents parity drift. Lazy error-body loading
also preserves streaming behavior by never loading a successful download into
memory.

**Alternatives considered**:

- Inline validation in all three execution paths. Rejected because it
  duplicates the contract and invites drift.
- Read every downloaded file before validation. Rejected because successful
  downloads must remain file-based and may be large.
- Add validation configuration to `RestClientConfiguration`. Rejected because
  configurable status validation is explicitly out of scope.

## Decision 2: Validate downloads before moving or resolving their files

**Decision**: In the download delegate callback, validate the final task
response before creating a destination or reporting success. For a non-2xx
response, best-effort read the temporary body for error context, remove the
temporary file, and fail the handle. Missing or non-HTTP responses fail without
reading the body.

**Rationale**: The temporary location is guaranteed during the download
callback. Validation at that point prevents rejected content from becoming a
library-owned file or a successful handle result. The final redirect response
is already represented by the task response.

**Alternatives considered**:

- Validate after moving. Rejected because it creates an avoidable orphan and a
  transient invalid destination.
- Defer validation to task completion. Rejected because the temporary file is
  not guaranteed to remain available there.
- Treat error-body read failure as a file-system error. Rejected because the
  HTTP status remains the primary failure and body context is optional.

## Decision 3: Eagerly create one session with a private delegate proxy

**Decision**: Construct one immutable session and one private download delegate
during client initialization. The delegate owns the lock-protected
task-identifier-to-handle registry and file callbacks, but never references the
client. Client deinitialization requests `finishTasksAndInvalidate()` so active
work may finish before URLSession releases its delegate.

**Rationale**: Eager immutable construction removes the concurrent lazy-first-
use race. Moving callback state to a delegate without a client back-reference
breaks the current `RestClient -> URLSession -> RestClient` ownership cycle.
Graceful invalidation preserves per-operation ownership without a public
shutdown obligation.

**Alternatives considered**:

- Lock the lazy session getter. Rejected because it leaves the delegate retain
  cycle.
- Keep `RestClient` as delegate and invalidate from `deinit`. Rejected because
  the session retains its delegate and prevents that `deinit`.
- Use an actor-isolated client. Rejected because synchronous download, Combine,
  and Objective-C delegate entry points would gain unnecessary hops.
- Use per-operation sessions, `URLSession.shared`, or public shutdown. Rejected
  because each violates the established configuration or lifecycle contract.

## Decision 4: Keep operation state per handle and narrow unsafe concurrency

**Decision**: Preserve `TransferHandle` as the cancellation, progress, state,
and result boundary. Registration occurs before task resume; completion removes
only that task's handle; terminal transition remains exactly once. Use `NSLock`
for synchronous delegate state at the supported deployment minimums. Prefer
checked `Sendable` where Foundation members permit it and confine any necessary
`@unchecked Sendable` to private types with documented lock invariants.

**Rationale**: Existing per-handle ownership already covers overlapping work.
The missing work is safe session creation, callback routing, and explicit
invariants—not another task manager. `Synchronization.Mutex` is unavailable at
the current minimum platforms.

**Alternatives considered**:

- Add a global operation registry or operation protocol. Rejected as
  unnecessary state and abstraction.
- Use `nonisolated(unsafe)`, semaphores, detached tasks, or blanket
  `@preconcurrency`. Rejected because they suppress or complicate the ownership
  model rather than make it safe.
- Cancel the whole session when one handle cancels. Rejected because it breaks
  operation isolation.

## Decision 5: Preserve response data when Combine decoding fails

**Decision**: Map Combine decoding failures with the payload bytes, matching
the existing async executor. Keep the current `RestingError` cases unchanged.

**Rationale**: Combine currently maps the decoding error after discarding the
payload context. A local catch-and-map is sufficient; the error model already
represents decoding context, status failures, invalid responses, cancellation,
transport, and file failures.

**Alternatives considered**:

- Add a decoding service or error wrapper. Rejected because one local parity
  correction solves the verified gap.
- Change generic error mapping to infer response data. Rejected because the
  mapper cannot infer bytes it was not given.

## Decision 6: Use one Swift 6.3 release job and generic platform builds

**Decision**: Raise only `swift-tools-version` to 6.3. Update the existing
GitHub Actions job to a Swift-6.3-capable Xcode on `macos-26`, run `swift test`
once, then compile the `Resting` scheme for macOS and generic iOS, watchOS,
tvOS, and visionOS destinations. Pin the selected Xcode path and print the
toolchain version in the job.

**Rationale**: The manifest establishes the minimum toolchain and Swift 6
language mode without redundant unsafe flags. One SPM test run is authoritative
for behavior; generic destinations prove package compilation without simulator
names, boots, or runtime versions. Current GitHub runner inventory includes
Xcode 26.6, and Xcode 26.4 or newer includes Swift 6.3.

**Alternatives considered**:

- Keep Xcode 15.3 or tools 6.2. Rejected because neither meets the release
  baseline.
- Test on a named simulator matrix. Rejected because it is slower and tied to
  mutable device/runtime names.
- Generate an Xcode project or split identical setup across five jobs. Rejected
  because SPM is authoritative and the extra machinery has no current benefit.
- Add language-mode or strict-concurrency compiler flags. Rejected as redundant
  with the Swift 6.3 manifest baseline.

## Decision 7: Reuse README and existing localizations

**Decision**: Update `README.md` with Swift 6.3 requirements, fixed response and
download validation, async/Combine failure parity, concurrent client ownership,
automatic lifecycle, and `ResponseValidator` removal. Do not create another
migration document. Leave English and Turkish strings unchanged unless the
implementation changes user-facing error copy.

**Rationale**: README is already the package's installation, behavior, and
migration guide. The existing `RestingError` cases and localized descriptions
are sufficient, so translation churn would add risk without changing behavior.

**Alternatives considered**:

- Add a separate migration or changelog file. Rejected as duplicate guidance
  for one explicitly scoped removal.
- Rewrite localized errors for the release. Rejected because no new error case
  or user-facing meaning is required.
