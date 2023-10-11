//
//  DataWithURLResponse.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

/// A structure that encapsulates both raw data and its associated URL response.
///
/// This can be useful for handling HTTP responses where both the data and the metadata
/// (like HTTP status codes) from the URL response are important.
struct DataWithURLResponse {
    /// The raw data received in the response.
    let data: Data

    /// The metadata associated with the response.
    let urlResponse: URLResponse

    /// Attempts to validate and return the received data.
    ///
    /// Validation is based on the HTTP status code in the associated `urlResponse`.
    /// If the status code is not in the range 200..<300, it throws an appropriate error.
    ///
    /// - Returns: The received data if validation is successful.
    /// - Throws:
    ///   - `RestingError.unknown`: If the `urlResponse` is not an instance of `HTTPURLResponse`.
    ///   - `RestingError.statusCode`: If the HTTP status code is outside the range 200..<300.
    func createResponse() throws -> Data {
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
              throw RestingError.unknown
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw RestingError.statusCode(httpResponse.statusCode, data)
        }
        return data
    }
}
