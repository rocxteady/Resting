//
//  MockedURLService.swift
//
//
//  Created by Ulaş Sancak on 11.10.2023.
//

import Foundation

class MockedURLService: URLProtocol {
    static var observer: ((URLRequest) throws -> (URLResponse?, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            guard let (response, data) = try Self.observer?(request) else {
                return
            }

            if let response = response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}

class MockedURLServiceWithFailure: URLProtocol {
    static var observer: ((URLRequest) throws -> (URLResponse?, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: NSError(domain: URLError.errorDomain, code: URLError.badURL.rawValue))
    }

    override func stopLoading() { }
}

class MockedDownloadURLService: URLProtocol {
    static var observer: ((URLRequest) throws -> (URLResponse?, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            guard let (response, data) = try Self.observer?(request) else {
                return
            }

            var modifiedResponse: HTTPURLResponse?

            if let httpResponse = response as? HTTPURLResponse {
                var headers = httpResponse.allHeaderFields as! [String: String]
                // Add or modify headers here
                headers["Content-Length"] = "4"

                modifiedResponse = HTTPURLResponse(
                    url: httpResponse.url!,
                    statusCode: httpResponse.statusCode,
                    httpVersion: nil,
                    headerFields: headers
                )
            } else if let response = response {
                // Create a new HTTPURLResponse with custom headers if needed
                modifiedResponse = HTTPURLResponse(
                    url: response.url!,
                    statusCode: (response as? HTTPURLResponse)?.statusCode ?? 200,
                    httpVersion: nil,
                    headerFields: ["Content-Length": "4"]
                )
            }
            
            client?.urlProtocol(self, didWriteData: 4, totalBytesWritten: 4, totalBytesExpectedToWrite: 4)

            if let response = modifiedResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }

            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
