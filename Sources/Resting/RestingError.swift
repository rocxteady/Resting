//
//  RestingError.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

/// Represents errors related to the `RestClient` operations.
enum RestingError: LocalizedError {
    /// Represents a malformed URL error.
    case urlMalformed

    /// Represents an unexpected HTTP status code error.
    /// Contains the status code and, optionally, the returned data.
    case statusCode(Int, Data?)

    /// Provides a human-readable description for the error.
    ///
    /// This can be useful for displaying the error message to the user.
    case unknown

    var errorDescription: String? {
        switch self {
        case .urlMalformed:
            "URL malformed."
        case .statusCode(let code, _):
            "HTTP returned unxpected \(code) code."
        case .unknown:
            "Unknown error."
        }
    }
}
