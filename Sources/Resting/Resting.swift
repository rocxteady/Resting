// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import Combine

public class RestClient {
    private let session: URLSession

    public init(sessionConfiguration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: sessionConfiguration)
    }
}

extension RestClient {
    public func fetch<T: Decodable>(configuration: RequestConfiguration) async throws -> T {
        let urlRequest = try configuration.createURLRequest()
        let response = try await session.dataWithURLResponse(for: urlRequest)
        return try response.createResponse()
    }
}

extension RestClient {
    public func publisher<T: Decodable>(configuration: RequestConfiguration) -> AnyPublisher<T, Error> {
        do {
            let urlRequest = try configuration.createURLRequest()
            return session.dataWithURLResponsePublisher(for: urlRequest)
                .tryMap() {
                    return try $0.createResponse()
                }.eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}
