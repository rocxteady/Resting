// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

/// Represents a client for making RESTful network requests.
public class RestClient {
    private let session: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder

    /// Initializes a new RestClient.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: The configuration used for the `URLSession`. Default is `.default`.
    ///   - jsonEncoder: A `JSONEncoder` instance. Default is a new instance.
    ///   - jsonDecoder: A `JSONDecoder` instance. Default is a new instance.
    public init(
        sessionConfiguration: URLSessionConfiguration = .default,
        jsonEncoder: JSONEncoder = .init(),
        jsonDecoder: JSONDecoder = .init()
    ) {
        self.session = URLSession(configuration: sessionConfiguration)
        self.jsonEncoder = JSONEncoder()
        self.jsonDecoder = JSONDecoder()
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
        return try JSONDecoder().decode(T.self, from: data)
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
        publisher(with: configuration)
            .tryMap { data in
                return try JSONDecoder().decode(T.self, from: data)
            }.eraseToAnyPublisher()
    }
}
