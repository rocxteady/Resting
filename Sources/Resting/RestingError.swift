//
//  RestingError.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

enum RestingError: LocalizedError {
    case urlMalformed
    case statusCode(Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .urlMalformed:
            "URL malformed."
        case .statusCode(let code):
            "HTTP returned unxpected \(code) code."
        case .unknown:
            "Unknown error."
        }
    }
}
