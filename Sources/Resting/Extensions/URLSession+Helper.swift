//
//  URLSession+Helper.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation
import Combine

extension URLSession {
    func dataWithURLResponse(for request: URLRequest) async throws -> DataWithURLResponse {
        let (data, response) = try await data(for: request)
        return .init(data: data, urlResponse: response)
    }
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
