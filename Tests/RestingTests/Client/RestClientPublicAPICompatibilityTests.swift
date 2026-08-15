import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif
import XCTest
import Resting

final class RestClientPublicAPICompatibilityTests: XCTestCase {
    func testRestClientPreservesPublicDownloadDelegateSurface() {
        let client = RestClient()
        let delegate: any URLSessionDownloadDelegate = client
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let task = session.downloadTask(with: URL(string: "https://example.com/archive.txt")!)

        client.urlSession(
            session,
            downloadTask: task,
            didWriteData: 1,
            totalBytesWritten: 1,
            totalBytesExpectedToWrite: 2
        )
        client.urlSession(
            session,
            downloadTask: task,
            didFinishDownloadingTo: FileManager.default.temporaryDirectory
        )
        client.urlSession(session, task: task, didCompleteWithError: nil)

        XCTAssertTrue((delegate as AnyObject) === client)
    }
}
