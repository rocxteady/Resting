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

    func testDownloadDelegateIgnoresUnknownTasks() throws {
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let orphanTask = client.session.downloadTask(with: URL(string: "https://example.com/orphan.txt")!)
        let orphanLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        client.urlSession(client.session, downloadTask: orphanTask, didFinishDownloadingTo: orphanLocation)
        client.urlSession(client.session, task: orphanTask, didCompleteWithError: nil)
    }

    func testDownloadDelegateMapsFileMoveFailuresToFileSystemError() async throws {
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
        let handle = client.download(.download(url: URL(string: "https://example.com/archive.txt")!))
        let task = try await activeDownloadTask(in: client.session)
        let missingLocation = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        client.urlSession(client.session, downloadTask: task, didFinishDownloadingTo: missingLocation)

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

        task.cancel()
        client.urlSession(client.session, task: task, didCompleteWithError: nil)
    }

    private func activeDownloadTask(in session: URLSession) async throws -> URLSessionDownloadTask {
        try await withCheckedThrowingContinuation { continuation in
            session.getAllTasks { tasks in
                guard let task = tasks.compactMap({ $0 as? URLSessionDownloadTask }).first else {
                    return continuation.resume(throwing: RestingError.invalidRequest(reason: "Expected a download task."))
                }
                continuation.resume(returning: task)
            }
        }
    }
}
