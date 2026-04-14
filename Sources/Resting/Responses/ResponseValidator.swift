import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Validates HTTP responses before they are surfaced publicly.
public struct ResponseValidator {
    public var acceptableStatusCodes: Range<Int>

    public init(acceptableStatusCodes: Range<Int> = 200..<300) {
        self.acceptableStatusCodes = acceptableStatusCodes
    }

    func validate(data: Data, response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RestingError.invalidResponse
        }
        guard acceptableStatusCodes.contains(httpResponse.statusCode) else {
            throw RestingError.statusCode(httpResponse.statusCode, data.isEmpty ? nil : data)
        }
        return httpResponse
    }
}
