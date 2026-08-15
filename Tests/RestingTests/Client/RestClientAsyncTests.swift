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

    func testExecutePayloadUsesSharedDecoderAndReturnsMetadata() async throws {
        struct Article: Decodable, Equatable {
            let title: String
            let createdAt: Date
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        MockURLProtocol.setRequestHandler { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Default"), "configured")
            return .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 201,
                    httpVersion: nil,
                    headerFields: ["X-Trace": "trace-id"]
                )!,
                data: Data("{\"title\":\"Configured\",\"createdAt\":\"1970-01-01T00:00:00Z\"}".utf8)
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(
                sessionConfiguration: configuration,
                decoder: decoder,
                defaultHeaders: ["X-Default": "configured"]
            )
        )
        let payload = try await client.executePayload(
            .query(url: URL(string: "https://example.com/articles/1")!),
            as: Article.self
        )

        XCTAssertEqual(payload.value, Article(title: "Configured", createdAt: Date(timeIntervalSince1970: 0)))
        XCTAssertEqual(payload.statusCode, 201)
        XCTAssertEqual(payload.headers["X-Trace"], "trace-id")
    }

    func testAsyncDecodingFailuresPreserveEmptyAndNonEmptyResponseData() async {
        struct Article: Decodable {
            let title: String
        }

        for responseData in [Data(), Data("{\"wrong\":\"shape\"}".utf8)] {
            MockURLProtocol.setRequestHandler { request in
                .init(
                    response: HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    ),
                    data: responseData
                )
            }

            let client = RestClient(
                configuration: RestClientConfiguration(sessionConfiguration: configuration)
            )
            do {
                let _: Article = try await client.execute(
                    .query(url: URL(string: "https://example.com/async-decoding")!)
                )
                XCTFail("Invalid JSON should fail decoding.")
            } catch let error as RestingError {
                guard case .decoding(_, let data) = error else {
                    return XCTFail("Expected decoding error, got \(error)")
                }
                XCTAssertEqual(data, responseData)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testAsyncFailureMatrixPreservesTypedResponseAndTransportContext() async {
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
            case "status":
                return .init(
                    response: HTTPURLResponse(
                        url: try XCTUnwrap(request.url),
                        statusCode: 429,
                        httpVersion: nil,
                        headerFields: nil
                    ),
                    data: Data("retry later".utf8)
                )
            case "cancelled":
                return .init(response: nil, error: URLError(.cancelled))
            default:
                return .init(response: nil, error: URLError(.notConnectedToInternet))
            }
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )

        await assertExecuteFailure(client, path: "invalid") {
            guard case .invalidResponse = $0 else { return false }
            return true
        }
        await assertExecuteFailure(client, path: "status") {
            guard case .statusCode(429, let data) = $0 else { return false }
            return data == Data("retry later".utf8)
        }
        await assertExecuteFailure(client, path: "transport") {
            guard case .transport(let error) = $0 else { return false }
            return error.code == .notConnectedToInternet
        }
        await assertExecuteFailure(client, path: "cancelled") {
            guard case .cancelled = $0 else { return false }
            return true
        }
    }

    func testDownloadRejectsNonDownloadRequestsImmediately() async {
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let handle = client.download(.query(url: URL(string: "https://example.com/articles")!))

        XCTAssertEqual(handle.state, .failed)

        do {
            _ = try await handle.value
            XCTFail("Non-download request should fail immediately.")
        } catch let error as RestingError {
            guard case .invalidRequest(let reason) = error else {
                return XCTFail("Expected invalid request error, got \(error)")
            }
            XCTAssertTrue(reason.contains("RequestDefinition.download"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDownloadDelegateMapsFileMoveFailuresToFileSystemError() async throws {
        let session = URLSession(configuration: .ephemeral)
        let task = session.downloadTask(with: URL(string: "https://example.com/archive.txt")!)
        let handle = TransferHandle(task: task)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/archive.txt")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let missingLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        finishDownload(at: missingLocation, response: response, handle: handle)

        do {
            _ = try await handle.value
            XCTFail("Moving a missing file should fail.")
        } catch let error as RestingError {
            guard case .fileSystem(let underlying) = error else {
                return XCTFail("Expected file system error, got \(error)")
            }
            XCTAssertFalse(underlying.localizedDescription.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        session.invalidateAndCancel()
    }

    func testConcurrentFirstUseSharesOneSessionAndOverlapsRequests() async throws {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: Data("ok".utf8),
                delay: 0.05
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let sessionIdentifiers = try await withThrowingTaskGroup(of: ObjectIdentifier.self) { group in
            for index in 0..<20 {
                group.addTask {
                    _ = try await client.executeData(
                        .query(url: URL(string: "https://example.com/request-\(index)")!)
                    )
                    return ObjectIdentifier(client.session)
                }
            }

            return try await group.reduce(into: Set<ObjectIdentifier>()) { $0.insert($1) }
        }

        XCTAssertEqual(sessionIdentifiers.count, 1)
        XCTAssertGreaterThan(MockURLProtocol.observedMaximumActiveRequestCount, 1)
    }

    func testClientSessionAndDelegateEventuallyDeallocateWithoutShutdown() async throws {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: Data("ok".utf8)
            )
        }

        weak var weakClient: RestClient?
        weak var weakSession: URLSession?
        weak var weakDelegate: AnyObject?

        do {
            var client: RestClient? = RestClient(
                configuration: RestClientConfiguration(sessionConfiguration: configuration)
            )
            weakClient = client
            weakSession = client?.session
            weakDelegate = client?.session.delegate as AnyObject?
            _ = try await client?.executeData(
                .query(url: URL(string: "https://example.com/lifecycle")!)
            )
            client = nil
        }

        for _ in 0..<100 where weakClient != nil || weakSession != nil || weakDelegate != nil {
            await pauseForLifecycleCallbacks()
        }

        XCTAssertNil(weakClient)
        XCTAssertNil(weakSession)
        XCTAssertNil(weakDelegate)
    }

    private func pauseForLifecycleCallbacks() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
                continuation.resume()
            }
        }
    }

    private func assertExecuteFailure(
        _ client: RestClient,
        path: String,
        matches: (RestingError) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await client.executeData(
                .query(url: URL(string: "https://example.com/\(path)")!)
            )
            XCTFail("Expected \(path) request to fail.", file: file, line: line)
        } catch let error as RestingError {
            XCTAssertTrue(matches(error), "Unexpected error: \(error)", file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

}
