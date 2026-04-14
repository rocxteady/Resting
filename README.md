# Resting
[![Swift](https://github.com/rocxteady/Resting/actions/workflows/swift.yml/badge.svg)](https://github.com/rocxteady/Resting/actions/workflows/swift.yml)

`Resting` is an async/await-first Swift package for common REST client work.
It provides typed request definitions, validated HTTP responses, a shared typed
error model, secondary Combine compatibility APIs, and per-operation download
handles with isolated progress and cancellation.

## Requirements

- Swift 6.2
- Apple platforms supported by `Package.swift`: iOS 15+, macOS 12+, watchOS 8+, tvOS 15+, visionOS 1+

## Installation

Add `Resting` to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/rocxteady/Resting.git", branch: "main")
]
```

## Primary Async Flow

Import the package and configure a client:

```swift
import Resting

let configuration = RestClientConfiguration(
    sessionConfiguration: .default,
    decoder: JSONDecoder(),
    encoder: JSONEncoder(),
    defaultHeaders: ["Accept": "application/json"]
)

let client = RestClient(configuration: configuration)
```

Build a request with the request style that matches the operation:

```swift
let request = RequestDefinition.json(
    url: URL(string: "https://api.example.com/articles")!,
    method: .post,
    body: CreateArticleRequest(title: "Modern API"),
    headers: ["Authorization": "Bearer token"]
)
```

Execute raw or decoded responses:

```swift
let rawPayload = try await client.execute(request)
let rawData = rawPayload.value

let article: Article = try await client.execute(
    .query(url: URL(string: "https://api.example.com/articles/1")!),
    as: Article.self
)
```

## Request Styles

Use the specialized constructors instead of a single overloaded request type:

```swift
let search = RequestDefinition.query(
    url: URL(string: "https://api.example.com/articles")!,
    queryItems: [URLQueryItem(name: "page", value: "1")]
)

let form = RequestDefinition.form(
    url: URL(string: "https://api.example.com/login")!,
    fields: ["email": "hello@example.com", "password": "secret"]
)

let json = RequestDefinition.json(
    url: URL(string: "https://api.example.com/articles")!,
    body: CreateArticleRequest(title: "Modern API")
)

let raw = RequestDefinition.raw(
    url: URL(string: "https://api.example.com/upload")!,
    body: Data("payload".utf8),
    contentType: "application/octet-stream"
)
```

## Combine Compatibility

Combine remains available as a secondary surface when an app still needs
publisher-based integration:

```swift
import Combine

let cancellable = client
    .publisher(for: request, as: Article.self)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print(error.localizedDescription)
            }
        },
        receiveValue: { article in
            print(article)
        }
    )
```

## Downloads, Progress, And Cancellation

Each download returns its own `TransferHandle`, so overlapping transfers do not
share hidden mutable client state:

```swift
let handle = client.download(
    .download(url: URL(string: "https://example.com/archive.zip")!)
)

handle.observeProgress { progress in
    print(progress.fractionCompleted)
}

let fileURL = try await handle.value
```

Cancellation is per handle:

```swift
handle.cancel()
```

## Error Handling

All public execution paths use the same `RestingError` model:

- `invalidRequest(reason:)`
- `transport(URLError)`
- `invalidResponse`
- `statusCode(Int, Data?)`
- `decoding(underlying:data:)`
- `cancelled`
- `fileSystem(underlying:)`

Example:

```swift
do {
    let article: Article = try await client.execute(request, as: Article.self)
    print(article)
} catch let error as RestingError {
    switch error {
    case .statusCode(let code, _):
        print("Unexpected status:", code)
    case .cancelled:
        print("Cancelled")
    default:
        print(error.localizedDescription)
    }
}
```

## Migration Guide

This release intentionally introduces source-breaking cleanup to remove the old
flat API.

- Replace `RequestConfiguration` with `RequestDefinition`.
- Replace `fetch(with:)` with `execute(_:)`, `executeData(_:)`, or `execute(_:as:)`.
- Replace ad hoc request payload overloads with `.query`, `.form`, `.json`, `.jsonData`, `.raw`, and `.download`.
- Replace client-global `download(with:completion:progress:)` plus `cancel()` with per-operation `TransferHandle` instances.
- Replace legacy `RestingError.urlMalformed`, `wrongParameterType`, and `unknown` handling with the richer typed error cases listed above.

## Development Standards

Project standards for contributors are tracked in `.specify/memory/constitution.md`.
Public API changes are expected to include tests, docs, and localized
user-facing strings where applicable.

## License

This package is available under the MIT license. See [LICENSE](LICENSE).
