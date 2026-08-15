import Foundation

/// Canonical public failure model for request, response, and transfer operations.
public enum RestingError: Error, LocalizedError {
    /// A request could not be constructed from the supplied input.
    case invalidRequest(reason: String)

    /// The underlying URL loading operation failed.
    case transport(URLError)

    /// The final response was missing or was not an HTTP response.
    case invalidResponse

    /// The final HTTP status was outside `200..<300`.
    case statusCode(Int, Data?)

    /// Response decoding failed, with the original bytes when available.
    case decoding(underlying: Error, data: Data?)

    /// The operation was cancelled.
    case cancelled

    /// A downloaded file could not be moved or otherwise accessed.
    case fileSystem(underlying: Error)

    /// Localized user-facing description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let reason):
            return String(
                format: NSLocalizedString("restingerror.invalidRequest", bundle: .module, comment: ""),
                reason
            )
        case .transport(let error):
            return String(
                format: NSLocalizedString("restingerror.transport", bundle: .module, comment: ""),
                error.localizedDescription
            )
        case .invalidResponse:
            return NSLocalizedString("restingerror.invalidResponse", bundle: .module, comment: "")
        case .statusCode(let code, _):
            return String(
                format: NSLocalizedString("restingerror.statusCode", bundle: .module, comment: ""),
                code
            )
        case .decoding(let underlying, _):
            return String(
                format: NSLocalizedString("restingerror.decoding", bundle: .module, comment: ""),
                underlying.localizedDescription
            )
        case .cancelled:
            return NSLocalizedString("restingerror.cancelled", bundle: .module, comment: "")
        case .fileSystem(let underlying):
            return String(
                format: NSLocalizedString("restingerror.fileSystem", bundle: .module, comment: ""),
                underlying.localizedDescription
            )
        }
    }
}

extension RestingError {
    static func map(_ error: Error, responseData: Data? = nil) -> RestingError {
        if let restingError = error as? RestingError {
            return restingError
        }
        if error is CancellationError {
            return .cancelled
        }
        if let urlError = error as? URLError {
            return urlError.code == .cancelled ? .cancelled : .transport(urlError)
        }
        if let decodingError = error as? DecodingError {
            return .decoding(underlying: decodingError, data: responseData)
        }
        return .invalidRequest(reason: error.localizedDescription)
    }
}
