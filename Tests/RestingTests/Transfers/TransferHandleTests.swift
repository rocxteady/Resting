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

        XCTAssertEqual(try DownloadFixture.readString(from: fileURL), DownloadFixture.text)
        XCTAssertEqual(handle.state, .completed)
        XCTAssertEqual(lastFractionCompleted, 1)
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
}
