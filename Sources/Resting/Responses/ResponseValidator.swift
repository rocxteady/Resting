import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

struct ResponseValidator {
    func validate(data: Data, response: URLResponse?) throws -> HTTPURLResponse {
        try validate(response: response) { data.isEmpty ? nil : data }
    }

    func validate(response: URLResponse?, errorData: () -> Data?) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RestingError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RestingError.statusCode(httpResponse.statusCode, errorData())
        }
        return httpResponse
    }
}
