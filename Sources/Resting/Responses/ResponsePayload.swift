import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Represents a validated response value with HTTP metadata.
public struct ResponsePayload<Value> {
    /// The raw or decoded response value.
    public let value: Value

    /// The final successful HTTP response.
    public let response: HTTPURLResponse

    /// Returns the validated status code.
    public var statusCode: Int {
        response.statusCode
    }

    /// Returns response headers normalized to strings.
    public var headers: [String: String] {
        response.allHeaderFields.reduce(into: [:]) { result, item in
            result[String(describing: item.key)] = String(describing: item.value)
        }
    }

    init(value: Value, response: HTTPURLResponse) {
        self.value = value
        self.response = response
    }
}
