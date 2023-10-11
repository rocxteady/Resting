//
//  URLSession+Helper.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation
import Combine

extension URLSession {
    /// Asynchronously fetches data for a given `URLRequest` and wraps it into a `DataWithURLResponse` structure.
    ///
    /// This method simplifies the process of obtaining data and its associated URL response using Swift's new async/await mechanism.
    ///
    /// - Parameter request: The `URLRequest` to be fetched.
    /// - Returns: A `DataWithURLResponse` structure containing both the data and its associated URL response.
    /// - Throws: Any errors encountered during the data fetch operation.
    func dataWithURLResponse(for request: URLRequest) async throws -> DataWithURLResponse {
        let (data, response) = try await data(for: request)
        return .init(data: data, urlResponse: response)
    }

    /// Returns a publisher that fetches data for a given `URLRequest` and wraps it into a `DataWithURLResponse` structure.
    ///
    /// This method is useful for those adopting the Combine framework, making it seamless to work with `URLSession` tasks within reactive pipelines.
    ///
    /// - Parameter request: The `URLRequest` to be fetched.
    /// - Returns: A publisher emitting `DataWithURLResponse` objects or an error.
    func dataWithURLResponsePublisher(for request: URLRequest) -> AnyPublisher<DataWithURLResponse, Error> {
        dataTaskPublisher(for: request)
            .map { (data, response) in
                DataWithURLResponse(data: data, urlResponse: response)
            }.mapError {
                $0 as Error
            }
            .eraseToAnyPublisher()
    }
}
