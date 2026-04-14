import XCTest
@testable import Resting

final class RestClientAsyncTests: XCTestCase {
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

    func testExecuteReturnsRawPayloadAndMetadata() async throws {
        let expectedData = Data("{\"title\":\"Modern API\"}".utf8)
        MockURLProtocol.setRequestHandler { request in
            XCTAssertEqual(request.httpMethod, "GET")
            return .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["X-Trace": "trace-id"]
                )!,
                data: expectedData
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let payload = try await client.execute(
            .query(url: URL(string: "https://example.com/articles")!)
        )

        XCTAssertEqual(payload.value, expectedData)
        XCTAssertEqual(payload.statusCode, 200)
        XCTAssertEqual(payload.headers["X-Trace"], "trace-id")
    }

    func testExecuteDecodesResponse() async throws {
        struct Article: Decodable, Equatable {
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
                data: Data("{\"title\":\"Decoded\"}".utf8)
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let article = try await client.execute(
            .query(url: URL(string: "https://example.com/articles/1")!),
            as: Article.self
        )

        XCTAssertEqual(article, Article(title: "Decoded"))
    }
}
