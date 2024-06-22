//
//  RequestConfiguration.swift
//
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

/// HTTP request methods.
public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Represents encoding types for the HTTP request.
public enum HTTPEncoding: Sendable {
    case json, urlEncoded
}

/// Constants for common HTTP header keys.
private enum HTTPHeaderKeys: String {
    case contentType = "Content-Type"
}

/// Constants for common content type values in HTTP headers.
private enum ContentType: String {
    case urlEncoded = "application/x-www--form-urlencoded"
    case json = "application/json"
}

private enum ParameterType {
    case object([String: Any])
    case data(Data)
}

/// Represents the configuration for a RESTful HTTP request.
public struct RequestConfiguration: Sendable {
    let urlString: String
    let method: HTTPMethod
    let headers: [String: String]?
    let encoding: HTTPEncoding

    private let parameterType: ParameterType?

    /// Initializes a new RequestConfiguration instance.
    ///
    /// - Parameters:
    ///   - urlString: The URL string for the request.
    ///   - method: The HTTP method to use. Default is `.get`.
    ///   - parameters: The parameters dictionary to be included in the request. Default is `nil`.
    ///   - headers: Additional HTTP headers to include in the request. Default is `nil`.
    ///   - encofing: The encoding for the request. Default is `.urlEncoded`.
    public init(urlString: String, method: HTTPMethod = .get, parameters: [String: Any]?, headers: [String: String]? = nil, encoding: HTTPEncoding = .urlEncoded) {
        self.urlString = urlString
        self.method = method
        if let parameters {
            self.parameterType = .object(parameters)
        } else {
            self.parameterType = nil
        }
        self.headers = headers
        self.encoding = encoding
    }

    /// Initializes a new RequestConfiguration instance.
    ///
    /// - Parameters:
    ///   - urlString: The URL string for the request.
    ///   - method: The HTTP method to use. Default is `.get`.
    ///   - body: The parameters as `Data` to be included in the reques body. Default is `nil`.
    ///   - headers: Additional HTTP headers to include in the request. Default is `nil`.
    ///   - encofing: The encoding for the request. Default is `.urlEncoded`.
    public init(urlString: String, method: HTTPMethod = .post, body: Data? = nil, headers: [String: String]? = nil, encoding: HTTPEncoding = .urlEncoded) {
        self.urlString = urlString
        self.method = method
        if let body {
            self.parameterType = .data(body)
        } else {
            self.parameterType = nil
        }
        self.headers = headers
        self.encoding = encoding
    }
}

extension RequestConfiguration {
    /// Creates a URLRequest instance based on the current request configuration.
    ///
    /// - Returns: A configured `URLRequest`.
    /// - Throws: Throws a `RestingError.urlMalformed` error if the URL string is malformed.
    func createURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: urlString) else {
            throw RestingError.urlMalformed
        }

        var urlRequest: URLRequest

        if let parameterType = parameterType {
            switch (encoding, method) {
            case (_ , .get):
                guard case .object(let parameters) = parameterType else {
                    throw RestingError.wrongParameterType
                }
                urlComponents.queryItems = parameters.map {
                    URLQueryItem(name: $0.key, value: String(describing: $0.value))
                }
                urlRequest = URLRequest(url: try urlComponents.fullURL)
            case (.json, _):
                urlRequest = URLRequest(url: try urlComponents.fullURL)
                switch parameterType {
                case .object(let parameters):
                    let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                    urlRequest.httpBody = jsonData
                case .data(let body):
                    urlRequest.httpBody = body
                }
                urlRequest.addValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderKeys.contentType.rawValue)
            case (.urlEncoded, _):
                urlRequest = URLRequest(url: try urlComponents.fullURL)
                switch parameterType {
                case .object(let parameters):
                    urlComponents.queryItems = parameters.map {
                        URLQueryItem(name: $0.key, value: String(describing: $0.value))
                    }
                    let bodyString = urlComponents.percentEncodedQuery
                    urlRequest.httpBody = bodyString?.data(using: .utf8)
                case .data(let body):
                    urlRequest.httpBody = body
                }
                urlRequest.addValue(ContentType.urlEncoded.rawValue, forHTTPHeaderField: HTTPHeaderKeys.contentType.rawValue)
            }
        } else {
            urlRequest = URLRequest(url: try urlComponents.fullURL)
        }

        urlRequest.httpMethod = method.rawValue

        // Handle headers
        if let headers = headers {
            for (key, value) in headers {
                urlRequest.addValue(value, forHTTPHeaderField: key)
            }
        }

        return urlRequest
    }
}
