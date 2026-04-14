import XCTest
@testable import Resting

final class RestingErrorMappingTests: XCTestCase {
    private var configuration: URLSessionConfiguration!

    override func setUp() {
        super.setUp()
        configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        configuration = nil
        super.tearDown()
    }

    func testTransportErrorsMapToTypedFailure() async {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                error: URLError(.notConnectedToInternet)
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        do {
            _ = try await client.executeData(.query(url: URL(string: "https://example.com/articles")!))
            XCTFail("Request should have failed.")
        } catch let error as RestingError {
            guard case .transport(let urlError) = error else {
                return XCTFail("Expected transport error, got \(error)")
            }
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidResponsesMapToTypedFailure() async {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: URLResponse(
                    url: try XCTUnwrap(request.url),
                    mimeType: "text/plain",
                    expectedContentLength: 0,
                    textEncodingName: nil
                )
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        do {
            _ = try await client.executeData(.query(url: URL(string: "https://example.com/articles")!))
            XCTFail("Request should have failed.")
        } catch let error as RestingError {
            guard case .invalidResponse = error else {
                return XCTFail("Expected invalid response error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStatusCodeFailuresRetainStatusCodeAndBody() async {
        let responseBody = Data("{\"error\":\"missing\"}".utf8)
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: responseBody
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        do {
            _ = try await client.executeData(.query(url: URL(string: "https://example.com/articles")!))
            XCTFail("Request should have failed.")
        } catch let error as RestingError {
            guard case .statusCode(let statusCode, let data) = error else {
                return XCTFail("Expected status code error, got \(error)")
            }
            XCTAssertEqual(statusCode, 404)
            XCTAssertEqual(data, responseBody)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDecodingFailuresMapToTypedFailure() async {
        struct Article: Decodable {
            let title: String
        }

        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: Data("{\"wrong\":\"shape\"}".utf8)
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        do {
            let _: Article = try await client.execute(
                .query(url: URL(string: "https://example.com/articles")!),
                as: Article.self
            )
            XCTFail("Decoding should have failed.")
        } catch let error as RestingError {
            guard case .decoding = error else {
                return XCTFail("Expected decoding error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDownloadCancellationMapsToTypedFailure() async {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: DownloadFixture.data,
                delay: 0.25
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let handle = client.download(.download(url: URL(string: "https://example.com/cancel.txt")!))
        handle.cancel()

        do {
            _ = try await handle.value
            XCTFail("Cancelled handle should not succeed.")
        } catch let error as RestingError {
            guard case .cancelled = error else {
                return XCTFail("Expected cancelled error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
