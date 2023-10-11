//
//  RequestConfiguration.swift
//
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum HTTPEncoding {
    case json, urlEncoded
}

private enum HTTPHeaderKeys: String {
    case contentType = "Content-Type"
}

private enum ContentType: String {
    case urlEncoded = "application/x-www--form-urlencoded"
    case json = "application/json"
}

public struct RequestConfiguration {
    let urlString: String
    let method: HTTPMethod
    let parameters: [String: Any]?
    let headers: [String: String]?
    let bodyEncoding: HTTPEncoding

    init(urlString: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil, headers: [String: String]? = nil, bodyEncoding: HTTPEncoding = .json) {
        self.urlString = urlString
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.bodyEncoding = bodyEncoding
    }
}

extension RequestConfiguration {
    func createURLRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: urlString) else {
            throw RestingError.urlMalformed
        }

        var urlRequest: URLRequest

        if let parameters = parameters {
            switch (bodyEncoding, method) {
            case (_ , .get):
                urlComponents.queryItems = parameters.map {
                    URLQueryItem(name: $0.key, value: String(describing: $0.value))
                }
                urlRequest = URLRequest(url: try urlComponents.fullURL)
            case (.json, _):
                urlRequest = URLRequest(url: try urlComponents.fullURL)
                let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                urlRequest.httpBody = jsonData
                urlRequest.addValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderKeys.contentType.rawValue)
            case (.urlEncoded, _):
                urlRequest = URLRequest(url: try urlComponents.fullURL)
                urlComponents.queryItems = parameters.map {
                    URLQueryItem(name: $0.key, value: String(describing: $0.value))
                }
                let bodyString = urlComponents.percentEncodedQuery
                urlRequest.httpBody = bodyString?.data(using: .utf8)
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
