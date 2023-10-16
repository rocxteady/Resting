# Resting
[![Swift](https://github.com/rocxteady/Resting/actions/workflows/swift.yml/badge.svg)](https://github.com/rocxteady/Resting/actions/workflows/swift.yml)

A Swift package offering a simplified interface for HTTP REST requests using both Combine and async/await patterns.

## Features

- Simplified HTTP methods (`GET`, `POST`, `PUT`, `DELETE`)
- Easily customizable request configurations
- Seamless error handling with specific `RestingError` cases
- Asynchronous request handling using Swift's new `async/await` feature
- Reactive request handling with Combine framework publishers
- Send parameters as either `Dictionary` or `Data`
- Handle responses with both `Data`and `Decodable`

## Installation

You can add the package to the dependencies value of your Package.swift
```
dependencies: [
    .package(url: "https://github.com/rocxteady/Resting.git", .upToNextMajor(from: "0.0.6"))
]
```

## Usage

### 1. Import the package

```
import Resting
```

### 2. Create an instance of the `RestClient`

```
let clientConfiguration = RestClientConfiguration(sessionConfiguration: .default, jsonDecoder: .init())
let restClient = RestClient(configuration: clientConfiguration)
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
// Decodable as response
do {
    let data: YourDecodableModel = try await restClient.fetch(with: requestConfig)
    // Handle the data
} catch {
    // Handle the error
}

// Data as response
do {
    let data = try await restClient.fetch(with: requestConfig)
    // Handle the data
} catch {
    // Handle the error
}

```

#### Using Combine:

```
// Decodable as response
let cancellable :AnyPublisher<YourDecodableModel, Error> = restClient.publisher(with: requestConfig)
cancellable.sink { completion in
    // Handle completion or error
} receiveValue: { (data: YourDecodableModel) in
    // Handle the data
}

// Data as response
restClient.publisher(with: requestConfig)
.sink { completion in
    // Handle completion or error
} receiveValue: { data in
    // Handle the data
}
```

## Error Handling

The package provides a dedicated `RestingError` enum to handle errors gracefully. It includes cases like `.urlMalformed`, `.statusCode`, `.wrongParameterType` and `.unknown`. Make sure to incorporate these in your error handling logic.

## Localizations

This package supports the following languages:

- English
- Turkish

If you would like to contribute with translations for other languages, please open a new issue on our GitHub repository or submit a pull request.

## Contribute

We appreciate contributions! If you have any suggestions, feature requests, or bug reports, please open a new issue on our GitHub repository.

## License

This package is available under the MIT license. See the LICENSE file for more info.
