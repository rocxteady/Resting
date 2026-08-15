import Foundation

/// Supported HTTP verbs for `RequestDefinition`.
public enum HTTPMethod: String, CaseIterable, Sendable {
    /// The GET method.
    case get = "GET"
    /// The POST method.
    case post = "POST"
    /// The PUT method.
    case put = "PUT"
    /// The PATCH method.
    case patch = "PATCH"
    /// The DELETE method.
    case delete = "DELETE"
    /// The HEAD method.
    case head = "HEAD"
}
