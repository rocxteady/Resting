import Foundation

/// Represents the supported request body strategies.
public enum RequestBody {
    case none
    case form([String: String])
    case json(JSONBody)
    case jsonData(Data)
    case raw(Data, contentType: String)

    /// Wraps an `Encodable` value so it can be encoded later with the client's encoder.
    public struct JSONBody {
        private let encodeBody: (JSONEncoder) throws -> Data

        /// Stores a typed JSON payload for later encoding.
        public init<T: Encodable>(_ value: T) {
            self.encodeBody = { encoder in
                try encoder.encode(value)
            }
        }

        func encode(using encoder: JSONEncoder) throws -> Data {
            try encodeBody(encoder)
        }
    }
}

extension RequestBody {
    func resolve(using encoder: JSONEncoder) throws -> (data: Data?, headers: [String: String]) {
        switch self {
        case .none:
            return (nil, [:])
        case .form(let fields):
            let bodyString = fields
                .sorted { $0.key < $1.key }
                .map { key, value in
                    "\(key.formURLEncoded())=\(value.formURLEncoded())"
                }
                .joined(separator: "&")
            return (
                bodyString.data(using: .utf8),
                ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"]
            )
        case .json(let body):
            return (
                try body.encode(using: encoder),
                ["Content-Type": "application/json"]
            )
        case .jsonData(let data):
            return (
                data,
                ["Content-Type": "application/json"]
            )
        case .raw(let data, let contentType):
            guard !contentType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw RestingError.invalidRequest(reason: "Raw request bodies require a content type.")
            }
            return (
                data,
                ["Content-Type": contentType]
            )
        }
    }
}

private extension String {
    func formURLEncoded() -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? self
    }
}
