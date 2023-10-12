//
//  RestClientWithFailure.swift
//  
//
//  Created by Ulaş Sancak on 11.10.2023.
//

import XCTest
@testable import Resting
import Combine

final class RestClientWithFailure: XCTestCase {

    private let configuration = URLSessionConfiguration.default
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        configuration.protocolClasses = [MockedURLServiceWithFailure.self]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        configuration.protocolClasses = nil
    }

    func testPublisherWithFailure() throws {
        let restClient = RestClient(configuration: .init(sessionConfiguration: configuration))
        let configuration = RequestConfiguration(urlString: "http://www.example.com")

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
}
