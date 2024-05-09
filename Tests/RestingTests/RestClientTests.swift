//
//  RestClientTests.swift
//  
//
//  Created by Ulaş Sancak on 11.10.2023.
//

import XCTest
@testable import Resting
import Combine

final class RestClientTests: XCTestCase {
    private let configuration = URLSessionConfiguration.default
    private var cancellables = Set<AnyCancellable>()
    var xClient: RestClient?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        configuration.protocolClasses = [MockedURLService.self]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        configuration.protocolClasses = nil
    }

    func testErrors() {
        let urlMalformed = RestingError.urlMalformed
        XCTAssertNotNil(urlMalformed.errorDescription, "RestingError case should not be nil!")
        let statusCode = RestingError.statusCode(403, nil)
        XCTAssertNotNil(statusCode.errorDescription, "RestingError case should not be nil!")
        let wrongParameterType = RestingError.wrongParameterType
        XCTAssertNotNil(wrongParameterType.errorDescription, "RestingError case should not be nil!")
        let unknown = RestingError.unknown
        XCTAssertNotNil(unknown.errorDescription, "RestingError case should not be nil!")
    }

    func testDataWithURLResponseWithFailure() {
        let dataWithURLResponse = DataWithURLResponse(data: Data(), urlResponse: URLResponse())
        do {
            _ = try dataWithURLResponse.createResponse()
            XCTFail("Creating response should have been failed!")
        } catch RestingError.unknown {
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAsyncAwait() async throws {
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            let exampleString = "{\"title\":\"Title Example\"}"
            let exampleData = exampleString.data(using: .utf8)
            return (response, exampleData)
        }
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://www.example.com", parameters: nil)

        let response: MockedModel = try await restClient.fetch(with: configuration)

        XCTAssertEqual(response.title, "Title Example", "Response data don't match the example data!")
    }

    func testDownloadAsyncAwait() {
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
                XCTAssertEqual(currentProgress, 1, "Downloaded progress don't match!")
            } catch {
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        } progress: { progress in
            currentProgress = progress
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

    func testPublisher() throws {
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            let exampleString = "{\"title\":\"Title Example\"}"
            let exampleData = exampleString.data(using: .utf8)
            return (response, exampleData)
        }

        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://www.example.com", method: .get)

        let expectation = self.expectation(description: "api")

        let publisher: AnyPublisher<MockedModel, Error> = restClient.publisher(with: configuration)
        publisher
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTAssert(false, error.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    expectation.fulfill()
                    break
                }
            } receiveValue: { response in
                XCTAssertEqual(response.title, "Title Example", "Response data don't match the example data!")
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 0.1)
    }

    func testAsyncAwaitWithFailure() async throws {
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 403, httpVersion: nil, headerFields: nil)
            return (response, nil)
        }
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://www.example.com", method: .get)

        do {
            let _: MockedModel = try await restClient.fetch(with: configuration)
            XCTFail("Downloading should have been failed with a status code!!")
        } catch RestingError.statusCode {
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testPublisherWithPublisherFailure() throws {
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://\u{FFFD}\u{FFFE}")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, nil)
        }

        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://\u{FFFD}\u{FFFE}")

        let expectation = self.expectation(description: "api")

        let publisher: AnyPublisher<MockedModel, Error> = restClient.publisher(with: configuration)
        publisher
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure:
                    expectation.fulfill()
                case .finished:
                    XCTAssert(false, "API returned with success. It should have return with failure!")
                    expectation.fulfill()
                    break
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }
    
    func testHandlingURLConfigurationFailureWithDownload() {
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://\u{FFFD}\u{FFFE}")!, statusCode: 403, httpVersion: nil, headerFields: nil)
            return (response, nil)
        }
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://\u{FFFD}\u{FFFE}", method: .get)

        let expectation = XCTestExpectation(description: "Downloading file...")

        restClient.download(with: configuration) { url, error in
            guard url == nil else {
                XCTFail("Download file url should be nil!")
                return
            }
            guard error != nil else {
                XCTFail("Download should not be nil!")
                return
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
