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

    func testStoredRawPublisherRetainsClientUntilDelayedSubscriptionCompletes() async {
        let expectedData = Data("delayed".utf8)
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: expectedData,
                delay: 0.05
            )
        }

        let expectation = expectation(description: "delayed raw publisher")
        weak var weakClient: RestClient?
        weak var weakSession: URLSession?
        var client: RestClient? = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        var publisher = client?.dataPublisher(
            for: .query(url: URL(string: "https://example.com/delayed")!)
        )
        weakClient = client
        weakSession = client?.session
        client = nil

        XCTAssertNotNil(weakClient)
        publisher?
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected completion failure: \(error)")
                }
                expectation.fulfill()
            } receiveValue: { data in
                XCTAssertEqual(data, expectedData)
            }
            .store(in: &cancellables)
        publisher = nil

        await fulfillment(of: [expectation], timeout: 1)
        cancellables.removeAll()

        for _ in 0..<100 where weakClient != nil || weakSession != nil {
            await pauseForLifecycleCallbacks()
        }

        XCTAssertNil(weakClient)
        XCTAssertNil(weakSession)
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

    func testPublisherFailureMatrixMatchesAsyncTypedContract() async {
        MockURLProtocol.setRequestHandler { request in
            switch request.url?.lastPathComponent {
            case "invalid":
                return .init(
                    response: URLResponse(
                        url: try XCTUnwrap(request.url),
                        mimeType: nil,
                        expectedContentLength: 0,
                        textEncodingName: nil
                    )
                )
            case "cancelled":
                return .init(response: nil, error: URLError(.cancelled))
            default:
                return .init(response: nil, error: URLError(.notConnectedToInternet))
            }
        }

        let expectations = ["invalid", "transport", "cancelled"].map { path in
            expectation(description: "\(path) publisher failure")
        }
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        for (index, path) in ["invalid", "transport", "cancelled"].enumerated() {
            client.dataPublisher(for: .query(url: URL(string: "https://example.com/\(path)")!))
                .sink { completion in
                    guard case .failure(let error) = completion else {
                        return XCTFail("Expected \(path) failure.")
                    }
                    switch path {
                    case "invalid":
                        guard case .invalidResponse = error else {
                            return XCTFail("Expected invalid response, got \(error)")
                        }
                    case "cancelled":
                        guard case .cancelled = error else {
                            return XCTFail("Expected cancellation, got \(error)")
                        }
                    default:
                        guard case .transport(let urlError) = error,
                              urlError.code == .notConnectedToInternet else {
                            return XCTFail("Expected transport error, got \(error)")
                        }
                    }
                    expectations[index].fulfill()
                } receiveValue: { _ in
                    XCTFail("Failure fixture should not emit a value.")
                }
                .store(in: &cancellables)
        }

        await fulfillment(of: expectations, timeout: 1)
    }

    func testDecodedPublisherMapsDecodingFailuresToRestingError() async {
        struct Article: Decodable {
            let title: String
        }

        let responseData = Data("{\"wrong\":\"shape\"}".utf8)
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: responseData
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
                XCTAssertEqual(data, responseData)
                expectation.fulfill()
            } receiveValue: { _ in
                XCTFail("Publisher should not emit a value.")
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testDecodedPublisherPreservesEmptyResponseDataOnFailure() async {
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
                )
            )
        }

        let expectation = expectation(description: "empty decoded publisher failure")
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        client.publisher(for: .query(url: URL(string: "https://example.com/empty")!), as: Article.self)
            .sink { completion in
                guard case .failure(let error) = completion else {
                    return XCTFail("Expected failure completion.")
                }
                guard case .decoding(_, let data) = error else {
                    return XCTFail("Expected decoding error, got \(error)")
                }
                XCTAssertEqual(data, Data())
                expectation.fulfill()
            } receiveValue: { _ in
                XCTFail("Publisher should not emit a value.")
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1)
    }

    private func pauseForLifecycleCallbacks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                continuation.resume()
            }
        }
    }
}
#endif
