import Foundation

/// Supported HTTP verbs for `RequestDefinition`.
public enum HTTPMethod: String, CaseIterable, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
}
