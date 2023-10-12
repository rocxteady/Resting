// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

/// Represents the configuration for a `RestClient` instance.
///
/// Encapsulates the `URLSessionConfiguration` and `JSONDecoder` to be used by the `RestClient`.
public struct RestClientConfiguration {
    /// The session configuration for network requests.
    let sessionConfiguration: URLSessionConfiguration

    /// The JSON decoder for decoding responses.
    let jsonDecoder: JSONDecoder

    /// Creates a new `RestClientConfiguration` instance with the specified `URLSessionConfiguration` and `JSONDecoder`.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: The session configuration for network requests, defaults to `.default`.
    ///   - jsonDecoder: The JSON decoder for decoding responses, defaults to a new `JSONDecoder` instance.
    public init(sessionConfiguration: URLSessionConfiguration = .default, jsonDecoder: JSONDecoder = .init()) {
        self.sessionConfiguration = sessionConfiguration
        self.jsonDecoder = jsonDecoder
    }
}

/// Represents a client for making RESTful network requests.
/// ///
/// This client utilizes a `RestClientConfiguration` to configure its behavior, including the session configuration and JSON decoding.
public class RestClient {
    private let session: URLSession
    private let clientConfiguration: RestClientConfiguration

    /// Creates a new `RestClient` instance with the specified `RestClientConfiguration`.
    ///
    /// - Parameters:
    ///   - configuration: The configuration used to set up the client, defaults to a new `RestClientConfiguration` instance with a default `URLSessionConfiguration`.
    public init(configuration: RestClientConfiguration = .init(sessionConfiguration: .default)) {
        self.clientConfiguration = configuration
        self.session = URLSession(configuration: configuration.sessionConfiguration)
    }
}

// MARK: Async/Await functionality
extension RestClient {
    /// Fetches raw data based on the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: A `Data` object.
    /// - Throws: Throws an error if the request fails or if the response can't be created.
    public func fetch(with configuration: RequestConfiguration) async throws -> Data {
        let urlRequest = try configuration.createURLRequest()
        let response = try await session.dataWithURLResponse(for: urlRequest)
        return try response.createResponse()
    }
    
    /// Fetches and decodes a `Decodable` model based on the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: A `Decodable` model.
    /// - Throws: Throws an error if the request fails, if the data can't be decoded, or if the response can't be created.
    public func fetch<T: Decodable>(with configuration: RequestConfiguration) async throws -> T {
        let data = try await fetch(with: configuration)
        return try clientConfiguration.jsonDecoder.decode(T.self, from: data)
    }
}

// MARK: Combine-based API functionality
import Combine

extension RestClient {
    /// Returns a publisher that emits the raw data for the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: An `AnyPublisher` that emits `Data` or an error.
    public func publisher(with configuration: RequestConfiguration) -> AnyPublisher<Data, Error> {
        do {
            let urlRequest = try configuration.createURLRequest()
            return session.dataWithURLResponsePublisher(for: urlRequest)
                .tryMap() {
                    return try $0.createResponse()
                }.eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    /// Returns a publisher that emits a `Decodable` model for the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: An `AnyPublisher` that emits a `Decodable` model or an error.
    public func publisher<T: Decodable>(with configuration: RequestConfiguration) -> AnyPublisher<T, Error> {
        let jsonDecoder = clientConfiguration.jsonDecoder
        return publisher(with: configuration)
            .tryMap { data in
                return try jsonDecoder.decode(T.self, from: data)
            }.eraseToAnyPublisher()
    }
}
