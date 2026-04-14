# Quickstart: Public API Modernization

## Prerequisites

- Xcode or Swift toolchain with Swift 6.2 support
- Apple platform SDKs required by the updated `Package.swift`
- Repository checked out on branch `001-modernize-public-api`

## Build and Test

```bash
rtk swift build
rtk swift test
```

## Planned Consumer Usage

### 1. Configure a client

```swift
import Resting

let configuration = RestClientConfiguration(
    sessionConfiguration: .default,
    decoder: JSONDecoder()
)

let client = RestClient(configuration: configuration)
```

### 2. Build a request with an explicit request style

```swift
let request = RequestDefinition.json(
    url: URL(string: "https://api.example.com/articles")!,
    method: .post,
    body: CreateArticleRequest(title: "Modern API"),
    headers: ["Authorization": "Bearer token"]
)
```

### 3. Execute with async/await

```swift
let article: Article = try await client.execute(request, as: Article.self)
```

### 4. Execute with Combine compatibility APIs

```swift
let cancellable = client
    .publisher(for: request, as: Article.self)
    .sink(
        receiveCompletion: { completion in
            // Handle typed RestingError failures
        },
        receiveValue: { article in
            print(article)
        }
    )
```

### 5. Start a download with per-operation ownership

```swift
let request = RequestDefinition.download(
    url: URL(string: "https://example.com/archive.zip")!
)

let handle = client.download(request)

handle.observeProgress { progress in
    print(progress.fractionCompleted)
}

let fileURL = try await handle.value
```

## Maintainer Verification Checklist

- Build succeeds after the Swift 6.2 manifest upgrade.
- Async examples are the primary README flow.
- Combine examples remain available but secondary.
- Request-building documentation distinguishes each specialized request entry
  point clearly.
- Download progress and cancellation are verified with overlapping operations.
- Migration notes exist for renamed or removed legacy public symbols.
