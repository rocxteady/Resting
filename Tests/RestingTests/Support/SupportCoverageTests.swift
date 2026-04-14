import Foundation
import XCTest
@testable import Resting

final class SupportCoverageTests: XCTestCase {
    func testRestingErrorDescriptionsIncludeRelevantContext() throws {
        let decodingError = try makeDecodingError()
        let fileSystemError = NSError(
            domain: "RestingTests",
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "disk full"]
        )
        let transportError = URLError(.notConnectedToInternet)

        XCTAssertDescription(
            RestingError.invalidRequest(reason: "bad input"),
            contains: "bad input"
        )
        XCTAssertDescription(
            RestingError.transport(transportError),
            contains: transportError.localizedDescription
        )
        XCTAssertNonEmptyDescription(RestingError.invalidResponse)
        XCTAssertDescription(
            RestingError.statusCode(418, nil),
            contains: "418"
        )
        XCTAssertDescription(
            RestingError.decoding(underlying: decodingError, data: nil),
            contains: decodingError.localizedDescription
        )
        XCTAssertNonEmptyDescription(RestingError.cancelled)
        XCTAssertDescription(
            RestingError.fileSystem(underlying: fileSystemError),
            contains: fileSystemError.localizedDescription
        )
    }

    func testRestingErrorMapCoversPassthroughCancellationAndFallbackPaths() throws {
        let existing = RestingError.invalidRequest(reason: "already typed")

        guard case .invalidRequest(let reason) = RestingError.map(existing) else {
            return XCTFail("Expected existing RestingError to pass through unchanged.")
        }
        XCTAssertEqual(reason, "already typed")

        guard case .cancelled = RestingError.map(CancellationError()) else {
            return XCTFail("Expected CancellationError to map to .cancelled.")
        }

        guard case .cancelled = RestingError.map(URLError(.cancelled)) else {
            return XCTFail("Expected cancelled URLError to map to .cancelled.")
        }

        let genericError = NSError(
            domain: "RestingTests",
            code: 9,
            userInfo: [NSLocalizedDescriptionKey: "fallback message"]
        )

        guard case .invalidRequest(let reason) = RestingError.map(genericError) else {
            return XCTFail("Expected generic errors to map to invalid request.")
        }
        XCTAssertEqual(reason, "fallback message")
    }

    func testResponseValidatorOmitsEmptyErrorBodies() throws {
        let validator = ResponseValidator()
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/articles")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!

        XCTAssertThrowsError(
            try validator.validate(data: Data(), response: response)
        ) { error in
            guard case .statusCode(let statusCode, let data) = error as? RestingError else {
                return XCTFail("Expected status code error, got \(error)")
            }
            XCTAssertEqual(statusCode, 404)
            XCTAssertNil(data)
        }
    }

    func testResponseValidatorRespectsCustomAcceptableStatusCodes() throws {
        let validator = ResponseValidator(acceptableStatusCodes: 300..<400)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/articles")!,
            statusCode: 304,
            httpVersion: nil,
            headerFields: nil
        )!

        let validated = try validator.validate(data: Data(), response: response)
        XCTAssertEqual(validated.statusCode, 304)
    }

    func testFoundationNetworkingSupportReportsAvailability() {
        XCTAssertTrue(FoundationNetworkingSupport.isAvailable)
    }

    private func makeDecodingError() throws -> DecodingError {
        struct Article: Decodable {
            let title: String
        }

        do {
            _ = try JSONDecoder().decode(Article.self, from: Data("{}".utf8))
            XCTFail("Decoding should have failed.")
            throw RestingError.invalidRequest(reason: "unreachable")
        } catch let error as DecodingError {
            return error
        }
    }

    private func XCTAssertDescription(
        _ error: RestingError,
        contains expectedSubstring: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let description = try? XCTUnwrap(error.errorDescription, file: file, line: line)
        XCTAssertNotNil(description, file: file, line: line)
        XCTAssertTrue(
            description?.localizedCaseInsensitiveContains(expectedSubstring) == true,
            "Expected '\(description ?? "nil")' to contain '\(expectedSubstring)'.",
            file: file,
            line: line
        )
    }

    private func XCTAssertNonEmptyDescription(
        _ error: RestingError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let description = try? XCTUnwrap(error.errorDescription, file: file, line: line)
        XCTAssertNotNil(description, file: file, line: line)
        XCTAssertFalse(description?.isEmpty ?? true, file: file, line: line)
    }
}
