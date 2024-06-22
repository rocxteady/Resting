//
//  RestClientTests.swift
//  
//
//  Created by Ulaş Sancak on 11.10.2023.
//

import XCTest
import Testing
@testable import Resting
import Combine

final class RestClientDownloadTests: XCTestCase {
    private let configuration = URLSessionConfiguration.default
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        configuration.protocolClasses = [MockedDownloadURLService.self]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        configuration.protocolClasses = nil
    }

    func testDownloadAsyncAwait() {
        let exampleString = "Text"
        let exampleData = exampleString.data(using: .utf8)
        MockedDownloadURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration, fileManager: MockedFileManager()))
        let configuration = RequestConfiguration(urlString: "http://www.example.com", parameters: nil)

        let expectation = XCTestExpectation(description: "Downloading file...")

        restClient.download(with: configuration) { url, error in
            guard let url else {
                XCTFail("Downloaded file url should not be nil!")
                return
            }
            guard error == nil else {
                XCTFail("Download shouldn't have been failed!")
                return
            }
            do {
                let responseData = try Data(contentsOf: url)
                XCTAssertEqual(responseData, exampleData, "Downloaded file don't match the example file data!")
            } catch {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    @MainActor
    func testDownloadWithProgressAsyncAwait() {
        let exampleString = "Text"
        let exampleData = exampleString.data(using: .utf8)
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://www.example.com", parameters: nil)

        let expectation = XCTestExpectation(description: "Downloading file...")

        var currentProgress: Double = 0

        restClient.download(with: configuration) { url, error in
            guard let url else {
                XCTFail("Downloaded file url should not be nil!")
                return
            }
            guard error == nil else {
                XCTFail("Download shouldn't have been failed!")
                return
            }
            do {
                let responseData = try Data(contentsOf: url)
                XCTAssertEqual(responseData, exampleData, "Downloaded file don't match the example file data!")
                DispatchQueue.main.async {
                    XCTAssertEqual(currentProgress, 1, "Downloaded progress don't match!")
                }
            } catch {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        } progress: { progress in
            DispatchQueue.main.async {
                currentProgress = progress
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCancellingDownloadAsyncAwait() {
        let exampleString = "Text"
        let exampleData = exampleString.data(using: .utf8)
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://www.example.com", parameters: nil)

        let expectation = XCTestExpectation(description: "Downloading file...")

        restClient.download(with: configuration) { url, error in
            guard let error else {
                XCTFail("Download should have been failed!")
                return
            }
            guard let error = error as? URLError,
                  error.code == .cancelled else {
                XCTFail("Download should have been failed as cancelled!")
                return
            }
            expectation.fulfill()
        }
        restClient.cancel()

        wait(for: [expectation], timeout: 1.0)
    }
}
