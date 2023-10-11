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
        XCTAssertEqual(urlMalformed.errorDescription, "URL malformed.", "RestingError messages don't match!")
        let statusCode = RestingError.statusCode(403)
        XCTAssertEqual(statusCode.errorDescription, "HTTP returned unxpected 403 code.", "RestingError messages don't match!")
        let unknown = RestingError.unknown
        XCTAssertEqual(unknown.errorDescription, "Unknown error.", "RestingError messages don't match!")
    }

    func testDataWithURLResponseWithFailure() {
        let dataWithURLResponse = DataWithURLResponse(data: Data(), urlResponse: URLResponse())
        do {
            let _:MockedModel = try dataWithURLResponse.createResponse()
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
        let restClient = RestClient(sessionConfiguration: configuration)
        let configuration = RequestConfiguration(urlString: "http://www.example.com")

        let response: MockedModel = try await restClient.fetch(configuration: configuration)

        XCTAssertEqual(response.title, "Title Example", "Response data don't match the example data!")
    }

    func testPublisher() throws {
        MockedURLService.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "http://www.example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            let exampleString = "{\"title\":\"Title Example\"}"
            let exampleData = exampleString.data(using: .utf8)
            return (response, exampleData)
        }

        let restClient = RestClient(sessionConfiguration: configuration)
        let configuration = RequestConfiguration(urlString: "http://www.example.com")

        let expectation = self.expectation(description: "api")

        let publisher: AnyPublisher<MockedModel, Error> = restClient.publisher(configuration: configuration)
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
        let restClient = RestClient(sessionConfiguration: configuration)
        let configuration = RequestConfiguration(urlString: "http://www.example.com")

        do {
            let _:MockedModel = try await restClient.fetch(configuration: configuration)
            XCTFail("Fetching should have been failed with a status code!!")
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

        let restClient = RestClient(sessionConfiguration: configuration)
        let configuration = RequestConfiguration(urlString: "http://\u{FFFD}\u{FFFE}")

        let expectation = self.expectation(description: "api")

        let publisher: AnyPublisher<MockedModel, Error> = restClient.publisher(configuration: configuration)
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
}
