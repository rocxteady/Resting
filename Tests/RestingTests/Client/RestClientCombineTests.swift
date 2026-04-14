import XCTest
@testable import Resting
#if canImport(Combine)
import Combine

final class RestClientCombineTests: XCTestCase {
    private var configuration: URLSessionConfiguration!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        MockURLProtocol.reset()
    }

    override func tearDown() {
        cancellables.removeAll()
        MockURLProtocol.reset()
        configuration = nil
        super.tearDown()
    }

    func testDecodedPublisherUsesSharedExecutionPipeline() async {
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
                data: Data("{\"title\":\"Combine\"}".utf8)
            )
        }

        let expectation = expectation(description: "decoded publisher")
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        client.publisher(for: .query(url: URL(string: "https://example.com/articles")!), as: Article.self)
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected completion failure: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { article in
                XCTAssertEqual(article, Article(title: "Combine"))
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testRawPublisherSurfacesTypedStatusCodeErrors() async {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: Data("service unavailable".utf8)
            )
        }

        let expectation = expectation(description: "raw publisher failure")
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        client.dataPublisher(for: .query(url: URL(string: "https://example.com/articles")!))
            .sink { completion in
                guard case .failure(let error) = completion else {
                    return XCTFail("Expected failure completion.")
                }
                guard case .statusCode(let statusCode, _) = error else {
                    return XCTFail("Expected status code error, got \(error)")
                }
                XCTAssertEqual(statusCode, 503)
                expectation.fulfill()
            } receiveValue: { _ in
                XCTFail("Publisher should not emit a value.")
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testRawPublisherReturnsImmediateInvalidRequestFailureWhenRequestCannotBeBuilt() async {
        let expectation = expectation(description: "invalid request failure")
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        client.publisher(
            for: .raw(
                url: URL(string: "https://example.com/upload")!,
                body: Data("payload".utf8),
                contentType: ""
            )
        )
        .sink { completion in
            guard case .failure(let error) = completion else {
                return XCTFail("Expected failure completion.")
            }
            guard case .invalidRequest(let reason) = error else {
                return XCTFail("Expected invalid request error, got \(error)")
            }
            XCTAssertEqual(reason, "Raw request bodies require a content type.")
            expectation.fulfill()
        } receiveValue: { _ in
            XCTFail("Publisher should not emit a value.")
        }
        .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testDecodedPublisherMapsDecodingFailuresToRestingError() async {
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

        let expectation = expectation(description: "decoded publisher failure")
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        client.publisher(for: .query(url: URL(string: "https://example.com/articles")!), as: Article.self)
            .sink { completion in
                guard case .failure(let error) = completion else {
                    return XCTFail("Expected failure completion.")
                }
                guard case .decoding(let underlying, let data) = error else {
                    return XCTFail("Expected decoding error, got \(error)")
                }
                XCTAssertFalse(underlying.localizedDescription.isEmpty)
                XCTAssertNil(data)
                expectation.fulfill()
            } receiveValue: { _ in
                XCTFail("Publisher should not emit a value.")
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1)
    }
}
#endif
