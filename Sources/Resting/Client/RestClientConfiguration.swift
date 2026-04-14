import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Defines the shared behavior for a `RestClient`.
public struct RestClientConfiguration {
    /// The `URLSessionConfiguration` used when creating the client's session.
    public var sessionConfiguration: URLSessionConfiguration

    /// The decoder used for decoded response helpers.
    public var decoder: JSONDecoder

    /// The encoder used for JSON request bodies.
    public var encoder: JSONEncoder

    /// Headers that are merged into every outgoing request.
    public var defaultHeaders: [String: String]

    /// Creates a reusable client configuration.
    public init(
        sessionConfiguration: URLSessionConfiguration = .default,
        decoder: JSONDecoder = .init(),
        encoder: JSONEncoder = .init(),
        defaultHeaders: [String: String] = [:]
    ) {
        self.sessionConfiguration = sessionConfiguration
        self.decoder = decoder
        self.encoder = encoder
        self.defaultHeaders = defaultHeaders
    }
}
