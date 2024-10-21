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

final class RestClientTestsWithExpectation: XCTestCase {
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

    func testPublisher() async throws {
        MockedURLService.observer = { () -> (URLResponse?, Data?) in
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
                    print(error)
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

        await fulfillment(of: [expectation], timeout: 0.1)
//            waitForExpectations(timeout: 1)
    }

    func testPublisherWithPublisherFailure() async throws {
        MockedURLService.observer = { () -> (URLResponse?, Data?) in
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

        await fulfillment(of: [expectation], timeout: 1)
//            waitForExpectations(timeout: 1)
    }

}
