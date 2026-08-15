import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Canonical description of an outbound REST operation.
public struct RequestDefinition {
    /// The destination URL.
    public let url: URL
    /// The HTTP method.
    public let method: HTTPMethod
    /// Request-specific headers.
    public let headers: [String: String]
    /// Query items appended to the destination URL.
    public let queryItems: [URLQueryItem]
    /// The request body strategy.
    public let body: RequestBody
    /// An optional request timeout override.
    public let timeout: TimeInterval?
    /// An optional cache-policy override.
    public let cachePolicy: URLRequest.CachePolicy?

    let operation: Operation

    enum Operation {
        case request
        case download
    }

    /// Creates a fully specified request definition.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - method: The HTTP method.
    ///   - headers: Request-specific headers.
    ///   - queryItems: Query items appended to `url`.
    ///   - body: The request body strategy.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = [],
        body: RequestBody = .none,
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.operation = .request
    }

    private init(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        queryItems: [URLQueryItem],
        body: RequestBody,
        timeout: TimeInterval?,
        cachePolicy: URLRequest.CachePolicy?,
        operation: Operation
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.timeout = timeout
        self.cachePolicy = cachePolicy
        self.operation = operation
    }

    /// Creates a query-oriented request.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - method: The HTTP method.
    ///   - queryItems: Query items appended to `url`.
    ///   - headers: Request-specific headers.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    /// - Returns: A request definition without body content.
    public static func query(
        url: URL,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> Self {
        .init(
            url: url,
            method: method,
            headers: headers,
            queryItems: queryItems,
            body: .none,
            timeout: timeout,
            cachePolicy: cachePolicy,
            operation: .request
        )
    }

    /// Creates a form-encoded request.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - method: The HTTP method.
    ///   - fields: Fields encoded as `application/x-www-form-urlencoded`.
    ///   - headers: Request-specific headers.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    /// - Returns: A form-encoded request definition.
    public static func form(
        url: URL,
        method: HTTPMethod = .post,
        fields: [String: String],
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> Self {
        .init(
            url: url,
            method: method,
            headers: headers,
            queryItems: [],
            body: .form(fields),
            timeout: timeout,
            cachePolicy: cachePolicy,
            operation: .request
        )
    }

    /// Creates a JSON-body request using the client's configured encoder.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - method: The HTTP method.
    ///   - body: The value encoded when the request is built.
    ///   - headers: Request-specific headers.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    /// - Returns: A JSON request definition.
    public static func json<T: Encodable>(
        url: URL,
        method: HTTPMethod = .post,
        body: T,
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> Self {
        .init(
            url: url,
            method: method,
            headers: headers,
            queryItems: [],
            body: .json(.init(body)),
            timeout: timeout,
            cachePolicy: cachePolicy,
            operation: .request
        )
    }

    /// Creates a JSON-body request from already-encoded JSON data.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - method: The HTTP method.
    ///   - body: The encoded JSON data.
    ///   - headers: Request-specific headers.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    /// - Returns: A JSON-data request definition.
    public static func jsonData(
        url: URL,
        method: HTTPMethod = .post,
        body: Data,
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> Self {
        .init(
            url: url,
            method: method,
            headers: headers,
            queryItems: [],
            body: .jsonData(body),
            timeout: timeout,
            cachePolicy: cachePolicy,
            operation: .request
        )
    }

    /// Creates a raw-body request with an explicit content type.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - method: The HTTP method.
    ///   - body: The raw request bytes.
    ///   - contentType: The body media type.
    ///   - headers: Request-specific headers.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    /// - Returns: A raw-body request definition.
    public static func raw(
        url: URL,
        method: HTTPMethod = .post,
        body: Data,
        contentType: String,
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> Self {
        .init(
            url: url,
            method: method,
            headers: headers,
            queryItems: [],
            body: .raw(body, contentType: contentType),
            timeout: timeout,
            cachePolicy: cachePolicy,
            operation: .request
        )
    }

    /// Creates a download-oriented request.
    ///
    /// - Parameters:
    ///   - url: The destination URL.
    ///   - headers: Request-specific headers.
    ///   - timeout: An optional request timeout override.
    ///   - cachePolicy: An optional cache-policy override.
    /// - Returns: A GET request configured for download execution.
    public static func download(
        url: URL,
        headers: [String: String] = [:],
        timeout: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> Self {
        .init(
            url: url,
            method: .get,
            headers: headers,
            queryItems: [],
            body: .none,
            timeout: timeout,
            cachePolicy: cachePolicy,
            operation: .download
        )
    }
}

extension RequestDefinition {
    func makeURLRequest(
        defaultHeaders: [String: String],
        encoder: JSONEncoder
    ) throws -> URLRequest {
        var resolvedURL = url
        if !queryItems.isEmpty {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw RestingError.invalidRequest(reason: "The request URL could not be decomposed into URL components.")
            }
            var mergedQueryItems = components.queryItems ?? []
            mergedQueryItems.append(contentsOf: queryItems)
            components.queryItems = mergedQueryItems
            guard let rebuiltURL = components.url else {
                throw RestingError.invalidRequest(reason: "The request URL became invalid after applying query items.")
            }
            resolvedURL = rebuiltURL
        }

        let resolvedBody = try body.resolve(using: encoder)
        if resolvedBody.data != nil, method == .get || method == .head {
            throw RestingError.invalidRequest(reason: "\(method.rawValue) requests do not support HTTP body content.")
        }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = method.rawValue
        request.httpBody = resolvedBody.data
        if let timeout {
            request.timeoutInterval = timeout
        }
        if let cachePolicy {
            request.cachePolicy = cachePolicy
        }

        var mergedHeaders = resolvedBody.headers
        defaultHeaders.forEach { mergedHeaders[$0.key] = $0.value }
        headers.forEach { mergedHeaders[$0.key] = $0.value }
        if !mergedHeaders.isEmpty {
            request.allHTTPHeaderFields = mergedHeaders
        }

        return request
    }
}
