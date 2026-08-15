import XCTest
@testable import Resting

final class TransferHandleTests: XCTestCase {
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

    func testDownloadReportsProgressAndMovesFile() async throws {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: DownloadFixture.data
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let handle = client.download(.download(url: URL(string: "https://example.com/archive.txt")!))

        var lastFractionCompleted: Double = 0
        handle.observeProgress { progress in
            lastFractionCompleted = progress.fractionCompleted
        }

        let fileURL = try await handle.value
        defer { try? DownloadFixture.removeIfPresent(fileURL) }

        XCTAssertEqual(try DownloadFixture.readString(from: fileURL), DownloadFixture.text)
        XCTAssertEqual(handle.state, .completed)
        XCTAssertEqual(lastFractionCompleted, 1)
    }

    func testDownloadRejectsNonTwoHundredResponsesWithAvailableBody() async {
        let errorData = Data("service unavailable".utf8)
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 503,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: errorData
            )
        }

        let error = await downloadError(for: "status.txt")
        guard case .statusCode(let statusCode, let data) = error else {
            return XCTFail("Expected status error, got \(String(describing: error))")
        }
        XCTAssertEqual(statusCode, 503)
        XCTAssertEqual(data, errorData)
    }

    func testDownloadRejectsNonTwoHundredResponsesWithoutBody() async {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 404,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
        }

        let error = await downloadError(for: "empty-status.txt")
        guard case .statusCode(let statusCode, let data) = error else {
            return XCTFail("Expected status error, got \(String(describing: error))")
        }
        XCTAssertEqual(statusCode, 404)
        XCTAssertNil(data)
    }

    func testDownloadRejectsNonHTTPResponse() async {
        MockURLProtocol.setRequestHandler { request in
            .init(
                response: URLResponse(
                    url: try XCTUnwrap(request.url),
                    mimeType: nil,
                    expectedContentLength: DownloadFixture.data.count,
                    textEncodingName: nil
                ),
                data: DownloadFixture.data
            )
        }

        let error = await downloadError(for: "non-http.txt")
        guard case .invalidResponse = error else {
            return XCTFail("Expected invalid response, got \(String(describing: error))")
        }
    }

    func testDownloadRejectsMissingResponse() async {
        MockURLProtocol.setRequestHandler { _ in
            .init(response: nil, data: DownloadFixture.data)
        }

        let error = await downloadError(for: "missing-response.txt")
        guard case .invalidResponse = error else {
            return XCTFail("Expected invalid response, got \(String(describing: error))")
        }
    }

    func testRejectedDownloadRemovesItsTemporaryFile() async throws {
        let session = URLSession(configuration: .ephemeral)
        let task = session.downloadTask(with: URL(string: "https://example.com/rejected.txt")!)
        let handle = TransferHandle(task: task)
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try DownloadFixture.data.write(to: temporaryURL)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com/rejected.txt")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        finishDownload(at: temporaryURL, response: response, handle: handle)

        XCTAssertFalse(FileManager.default.fileExists(atPath: temporaryURL.path))
        do {
            _ = try await handle.value
            XCTFail("Rejected download should fail.")
        } catch let error as RestingError {
            guard case .statusCode(500, let data) = error else {
                return XCTFail("Expected status error, got \(error)")
            }
            XCTAssertEqual(data, DownloadFixture.data)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        session.invalidateAndCancel()
    }

    func testCancellingOneTransferDoesNotAffectAnother() async throws {
        MockURLProtocol.setRequestHandler { request in
            let delay: TimeInterval = request.url?.lastPathComponent == "slow.txt" ? 0.25 : 0.01
            let body = Data(request.url!.lastPathComponent.utf8)
            return .init(
                response: HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!,
                data: body,
                delay: delay
            )
        }

        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let slowHandle = client.download(.download(url: URL(string: "https://example.com/slow.txt")!))
        let fastHandle = client.download(.download(url: URL(string: "https://example.com/fast.txt")!))

        slowHandle.cancel()

        let fastFileURL = try await fastHandle.value
        XCTAssertEqual(try DownloadFixture.readString(from: fastFileURL), "fast.txt")
        XCTAssertEqual(fastHandle.state, .completed)

        do {
            _ = try await slowHandle.value
            XCTFail("Cancelled transfer should not succeed.")
        } catch let error as RestingError {
            guard case .cancelled = error else {
                return XCTFail("Expected cancelled error, got \(error)")
            }
        }
    }

    func testImmediateFailureHandleFailsWithoutNetworkWork() async {
        let handle = TransferHandle(immediateFailure: .cancelled)

        XCTAssertEqual(handle.state, .failed)
        XCTAssertEqual(handle.progress.totalUnitCount, 1)
        XCTAssertEqual(handle.progress.completedUnitCount, 1)

        do {
            _ = try await handle.value
            XCTFail("Immediate failure handle should not succeed.")
        } catch let error as RestingError {
            guard case .cancelled = error else {
                return XCTFail("Expected cancelled error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testManualProgressAndTerminalStateTransitionsAreStable() async throws {
        let session = URLSession(configuration: .ephemeral)
        let task = session.downloadTask(with: URL(string: "https://example.com/archive.txt")!)
        let handle = TransferHandle(task: task)
        let completedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        handle.markRunning()
        handle.didWrite(totalBytesWritten: 2, totalBytesExpectedToWrite: 10)

        XCTAssertEqual(handle.state, .running)
        XCTAssertEqual(handle.progress.totalUnitCount, 10)
        XCTAssertEqual(handle.progress.completedUnitCount, 2)

        handle.progress.totalUnitCount = 0
        handle.finish(with: completedURL)
        handle.finish(with: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        handle.fail(with: URLError(.badServerResponse))

        let resolvedURL = try await handle.value
        XCTAssertEqual(resolvedURL, completedURL)
        XCTAssertEqual(handle.state, .completed)
        XCTAssertEqual(handle.progress.completedUnitCount, handle.progress.totalUnitCount)
    }

    func testFailMapsNonCancellationErrorsAndIgnoresRepeatedFailures() async {
        let session = URLSession(configuration: .ephemeral)
        let task = session.downloadTask(with: URL(string: "https://example.com/archive.txt")!)
        let handle = TransferHandle(task: task)

        handle.fail(with: URLError(.badServerResponse))
        handle.fail(with: URLError(.cancelled))

        do {
            _ = try await handle.value
            XCTFail("Failed handle should not succeed.")
        } catch let error as RestingError {
            guard case .transport(let urlError) = error else {
                return XCTFail("Expected transport error, got \(error)")
            }
            XCTAssertEqual(urlError.code, .badServerResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(handle.state, .failed)
    }

    func testCancellationRacingCompletionResolvesExactlyOnce() async {
        let session = URLSession(configuration: .ephemeral)
        let task = session.downloadTask(with: URL(string: "https://example.com/race.txt")!)
        let handle = TransferHandle(task: task)
        let completedURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { handle.finish(with: completedURL) }
            group.addTask { handle.fail(with: URLError(.cancelled)) }
        }

        switch handle.state {
        case .completed:
            do {
                let resolvedURL = try await handle.value
                XCTAssertEqual(resolvedURL, completedURL)
            } catch {
                XCTFail("Completed state must resolve with its file: \(error)")
            }
        case .cancelled:
            do {
                _ = try await handle.value
                XCTFail("Cancelled state must not resolve successfully.")
            } catch let error as RestingError {
                guard case .cancelled = error else {
                    return XCTFail("Expected cancellation, got \(error)")
                }
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        default:
            XCTFail("Race must end in one terminal state, got \(handle.state)")
        }
    }

    private func downloadError(for fileName: String) async -> RestingError? {
        let client = RestClient(
            configuration: RestClientConfiguration(sessionConfiguration: configuration)
        )
        let handle = client.download(
            .download(url: URL(string: "https://example.com/\(fileName)")!)
        )

        do {
            let unexpectedFileURL = try await handle.value
            try? DownloadFixture.removeIfPresent(unexpectedFileURL)
            XCTFail("Rejected download should not return a file URL.")
            return nil
        } catch let error as RestingError {
            XCTAssertEqual(handle.state, .failed)
            return error
        } catch {
            XCTFail("Unexpected error: \(error)")
            return nil
        }
    }
}
