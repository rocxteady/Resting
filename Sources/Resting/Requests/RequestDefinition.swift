import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Canonical description of an outbound REST operation.
public struct RequestDefinition {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let queryItems: [URLQueryItem]
    public let body: RequestBody
    public let timeout: TimeInterval?
    public let cachePolicy: URLRequest.CachePolicy?

    let operation: Operation

    enum Operation {
        case request
        case download
    }

    /// Creates a fully specified request definition.
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
