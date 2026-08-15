# Quickstart: Validate Resting Modernization Follow-Up

## Prerequisites

- Repository checked out at a revision containing 002-resting-modernization
- Xcode 26.4 or newer with Swift 6.3 and all declared Apple platform SDKs
- `xcodebuildmcp` available for local package verification

The expected behavior is defined in [contracts/public-api.md](contracts/public-api.md)
and lifecycle entities are defined in [data-model.md](data-model.md).

## 1. Confirm the toolchain baseline

```bash
rtk swift --version
```

Expected: Apple Swift 6.3.x.

## 2. Run the complete package test suite

```bash
rtk xcodebuildmcp swift-package test \
  --package-path /Users/ulas.sancak/Desktop/Projects/Personal/Resting
```

Expected: all existing and feature regression tests pass, including response
parity, download validation and cleanup, concurrent first use, cancellation
isolation, delayed raw-publisher subscription, public delegate compatibility,
and lifecycle release.

## 3. Verify a release package build

```bash
rtk xcodebuildmcp swift-package build \
  --package-path /Users/ulas.sancak/Desktop/Projects/Personal/Resting \
  --configuration release
```

Expected: the `Resting` target compiles without strict-concurrency diagnostics.

## 4. Verify the automated platform matrix

Run the `Swift` GitHub Actions workflow. Its release job must:

1. print the selected Swift version;
2. run the full SPM test suite once; and
3. build the `Resting` scheme for `platform=macOS` plus generic iOS, watchOS,
   tvOS, and visionOS destinations.

Expected: all six checks succeed without a named simulator, runtime version,
or generated Xcode project. Cross-platform generic destination commands remain
in CI because the local `xcodebuildmcp` Swift-package workflow does not expose
watchOS, tvOS, or visionOS destinations.

## 5. Review the consumer contract

Confirm `README.md` states:

- Swift 6.3 is required;
- async, Combine, and downloads use fixed `200..<300` validation;
- rejected downloads never surface a successful file;
- decoding failures preserve available body data across async and Combine;
- one client supports overlapping work and releases its session automatically;
- stored raw and data publishers remain subscribable after direct client release;
- `RestClient` preserves its public download-delegate compatibility surface;
- `ResponseValidator` was removed with no replacement customization API.

Expected: an adopter can understand behavior and migration without inspecting
the implementation.
