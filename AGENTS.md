@RTK.md

## Active Technologies
- Swift 6.3 target; `Package.swift` currently uses `swift-tools-version: 6.2` and is upgraded by 002-resting-modernization + Foundation, FoundationNetworking where required by platform, Combine, XCTest; no third-party runtime dependencies planned
- Swift Package Manager is authoritative; storage is limited to temporary download files and localized resources in `Sources/Resting/Resources`

## Skill and Tool Routing
- Use `ios-code-audit` only for explicitly requested broad codebase or release audits, not routine targeted changes.
- Use `swift-api-design-guidelines-skill` for public API additions, removals, renames, and documentation changes.
- Use `swift-concurrency` for `Sendable`, actor or lock isolation, URLSession lifecycle, cancellation, async/Combine boundaries, and data-race work.
- Use `swift-architecture-skill` only for substantial module, ownership, or architectural-boundary changes.
- Use `swift-format-style` when localized or user-facing number, date, duration, measurement, list, or string formatting changes.
- Use `xcodebuildmcp-cli` for Apple-platform builds, tests, debugging, logs, and platform verification instead of raw `xcodebuild`, `xcrun`, or `simctl` commands.
- XcodeGen is available when an Xcode project must be generated, but it MUST NOT replace `Package.swift` as the source of truth.

## Recent Changes
- 002-resting-modernization: Added a focused follow-up specification and automated Spec Kit workflow for verified modernization gaps and the Swift 6.3 upgrade
- 001-modernize-public-api: Completed the Swift 6.2 modernization baseline
