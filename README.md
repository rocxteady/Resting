# Resting

A Swift package offering a simplified interface for HTTP REST requests using both Combine and async/await patterns.

## Features

- Simplified HTTP methods (`GET`, `POST`, `PUT`, `DELETE`)
- Easily customizable request configurations
- Seamless error handling with specific `RestingError` cases
- Asynchronous request handling using Swift's new `async/await` feature
- Reactive request handling with Combine framework publishers
- Handle responses with both `Data`and `Decodable`.

## Installation

You can add the package to the dependencies value of your Package.swift
```
dependencies: [
    .package(url: "https://github.com/rocxteady/Resting.git", .upToNextMajor(from: "0.0.1"))
]
```

## Usage

### 1. Import the package

```
import Resting
```

### 2. Create an instance of the `RestClient`

```
let restClient = RestClient()
```

### 3. Configure your request

```
let requestConfig = RequestConfiguration(
    urlString: "https://api.example.com/data",
    method: .get
)
```

### 4. Make the HTTP call

#### Using async/await:

```
do {
    let data: MockedModel = try await restClient.fetch(with: requestConfig)
    // Handle the data
} catch {
    // Handle the error
}
```

#### Using Combine:

```
let cancellable :AnyPublisher<YourDecodableModel, Error> = restClient.publisher(with: requestConfig)
cancellable.sink { completion in
    // Handle completion or error
} receiveValue: { (data: YourDecodableModel) in
    // Handle the data
}
```

## Error Handling

The package provides a dedicated `RestingError` enum to handle errors gracefully. It includes cases like `.urlMalformed`, `.statusCode`, and `.unknown`. Make sure to incorporate these in your error handling logic.

## Localizations

This package supports the following languages:

- English
- Turkish

If you would like to contribute with translations for other languages, please open a new issue on our GitHub repository or submit a pull request.

## Contribute

We appreciate contributions! If you have any suggestions, feature requests, or bug reports, please open a new issue on our GitHub repository.

## License

This package is available under the MIT license. See the LICENSE file for more info.
