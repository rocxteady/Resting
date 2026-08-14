# Resting Modernization Follow-Up

## Spec Kit Specify Prompt

Follow `AGENTS.md` for project skill and tool routing and
`.specify/memory/constitution.md` for mandatory project principles and quality
gates.

Finish the existing Resting modernization by addressing only these verified
release-blocking or material maintainability gaps:

1. Downloads currently move the downloaded file and report success without
   validating the HTTP response. Require download operations to reject
   missing or non-HTTP responses and non-2xx status codes using the same typed
   `RestingError` contract as data requests.

2. `RestClient` is marked `@unchecked Sendable`, but its lazily initialized
   `sessionStorage` is not synchronized. `RestClient` also installs itself as
   `URLSession`'s delegate, creating a retain cycle because `URLSession` retains
   its delegate and `deinit` cannot reliably invalidate the session. Require
   safe concurrent first use and automatic client/session deallocation without
   adding a consumer-managed shutdown requirement.

3. Async and Combine execution do not fully share behavior. Combine duplicates
   response validation and discards response data when mapping decoding
   failures, while async execution retains it. Require equivalent validation
   and `RestingError` context across both APIs through one simple shared
   behavior path.

4. `ResponseValidator` is public, but consumers cannot call its internal
   `validate` method or configure `RestClient` to use it. Unless configurable
   status validation is intentionally added as a supported consumer feature,
   remove this unusable type from the public API and keep default 2xx
   validation internal.

5. `Package.swift` requires Swift tools 6.2 while Swift 6.3 is the selected
   minimum. The GitHub Actions workflow still uses Xcode 15.3 and old simulator
   runtimes, so it cannot validate the modernized package. Require Swift 6.3
   and a compatible CI environment that tests the package and verifies
   compilation for iOS, macOS, watchOS, tvOS, and visionOS without relying on
   brittle named simulator devices.

Preserve the existing async/await-first API, secondary Combine compatibility,
`RequestDefinition` request styles, `ResponsePayload`, `RestingError`,
`TransferHandle` behavior, current Apple deployment minimums, English and
Turkish localization, Swift Package Manager structure, and zero third-party
runtime dependencies.

Add focused deterministic regression coverage for non-2xx and non-HTTP
downloads, overlapping operations, cancellation isolation, `RestClient`
deallocation after session creation, strict-concurrency use, and async/Combine
decoding-error parity. Update affected public documentation and migration
guidance.

Do not redesign the library, add new REST features, introduce dependencies or
speculative abstractions, change deployment minimums, or include cosmetic
naming, formatting, minor style, and low-value coverage work. Success means
Swift 6.3 builds and CI pass, all existing tests remain green, the new
regressions pass, downloads follow the documented response contract,
`RestClient` has no known session race or retain cycle, and async and Combine
expose consistent typed failures.
