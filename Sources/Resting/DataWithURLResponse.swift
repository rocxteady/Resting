//
//  DataWithURLResponse.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

struct DataWithURLResponse {
    let data: Data
    let urlResponse: URLResponse

    func createResponse<T: Decodable>() throws -> T {
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
              throw RestingError.unknown
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw RestingError.statusCode(httpResponse.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
