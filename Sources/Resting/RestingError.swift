//
//  RestingError.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

/// Represents errors related to the `RestClient` operations.
public enum RestingError: LocalizedError {
    /// Represents a malformed URL error.
    case urlMalformed

    /// Represents an unexpected HTTP status code error.
    /// Contains the status code and, optionally, the returned data.
    case statusCode(Int, Data?)

    /// Represents an incorrect parameter type error.
    /// This error is thrown when the parameter type is `Data` on a `GET` request..
    case wrongParameterType

    /// Provides a human-readable description for the error.
    ///
    /// This can be useful for displaying the error message to the user.
    case unknown

    public var errorDescription: String? {
        switch self {
        case .urlMalformed:
            NSLocalizedString("restingerror.urlMalformed", bundle: .module, comment: "")
        case .statusCode(let code, _):
            String(format: NSLocalizedString("restingerror.statusCode", bundle: .module, comment: ""), code)
        case .wrongParameterType:
            NSLocalizedString("restingerror.wrongParameterType", bundle: .module, comment: "")
        case .unknown:
            NSLocalizedString("restingerror.unknown", bundle: .module, comment: "")
        }
    }
}
