//
//  RequestConfigurationTests.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation
import Testing
@testable import Resting

final class RequestConfigurationTests {
    @Test func testCreatingURLComponentsWithFailure() throws {
        var urlComponents = URLComponents(string: "")
        urlComponents?.path = "//"
        do {
            _ = try urlComponents?.fullURL
        } catch RestingError.urlMalformed {
        } catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func testCreatingURLConfigırationWithURLFailure() throws {
        let requestConfiguration: RequestConfiguration = .init(urlString: "http://\u{FFFD}\u{FFFE}")
        do {
            _ = try requestConfiguration.createURLRequest()
            Issue.record("Creating URL Configuration should have been failed!")
        } catch RestingError.urlMalformed {
        } catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func testCreatingURLConfigurationWithParameterTypeFailure() throws {
        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .get, body: Data())
        do {
            _ = try requestConfiguration.createURLRequest()
            Issue.record("Creating URL Configuration should have been failed!")
        } catch RestingError.wrongParameterType {
        } catch {
            Issue.record("\(error.localizedDescription)")
        }
    }

    @Test func testCreatingURLRequestWithGet() throws {
        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .get)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.httpBody == nil)
        #expect(request.url?.scheme == "http")
        #expect(request.url?.host == "www.example.com")
    }

    @Test func testCreatingURLRequestWithPUT() throws {
        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .put)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.httpMethod == "PUT")
    }

    @Test func testCreatingURLRequestWithDelete() throws {
        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .delete)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.httpMethod == "DELETE")
    }

    @Test func testCreatingURLRequestWithHeaders() throws {
        let headers = ["key": "value", "d": "d", "b": "b", "c": "c", "a": "a", "e": "e", "some_key": "ş"]
        let headerArray = headers.map {
            "\($0.key)=\($0.value)"
        }.sorted()

        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .get, headers: headers)
        let request = try requestConfiguration.createURLRequest()

        let headerArrayFromRequest = request.allHTTPHeaderFields?.map {
            "\($0.key)=\($0.value)"
        }.sorted()

        #expect(headerArrayFromRequest == headerArray)
    }

    @Test func testCreatingURLRequestWithGetWithParameters() throws {
        let parameters = ["key": "value", "d": "d", "b": "b", "c": "c", "a": "a", "e": "e", "some_key": "ş"]
        let queryArray = parameters.map {
            "\($0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        }.sorted()

        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .get, parameters: parameters)
        let request = try requestConfiguration.createURLRequest()

        let queryArrayFromRequest = request.url?.query?.components(separatedBy: "&").sorted()
        #expect(queryArrayFromRequest == queryArray)
    }

    @Test func testCreatingURLRequestWithPostWithURLEncoding() throws {
        let parameters = ["key": "value", "d": "d", "b": "b", "c": "c", "a": "a", "e": "e", "some_key": "ş"]
        let queryArray = parameters.map {
            "\($0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        }.sorted()

        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .post, parameters: parameters, encoding: .urlEncoded)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/x-www--form-urlencoded")
        #expect(request.httpBody != nil)
        let queryArrayFromRequest = String(data: request.httpBody!, encoding: .utf8)?.components(separatedBy: "&").sorted()
        #expect(queryArrayFromRequest == queryArray)
    }

    @Test func testCreatingURLRequestWithPostWithJSONEncoding() throws {
        let parameters: [String: Any] = ["key": "value", "some_key": "ş"]
        let queryArray = parameters.map {
            "\($0.key)=\($0.value)"
        }.sorted()

        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .post, parameters: parameters, encoding: .json)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/json")
        #expect(request.httpBody != nil )
        let parametersFromRequest = (try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any])
            .map {
                "\($0.key)=\($0.value)"
            }.sorted()

        #expect(parametersFromRequest == queryArray)
    }

    @Test func testCreatingURLRequestWithURLEncodedData() throws {
        let parameters = ["key": "value", "d": "d", "b": "b", "c": "c", "a": "a", "e": "e", "some_key": "ş"]
        let queryArray = parameters.map {
            "\($0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        }.sorted()
        let data = queryArray.joined(separator: "&").data(using: .utf8)

        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .post, body: data, encoding: .urlEncoded)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/x-www--form-urlencoded")
        #expect(request.httpBody != nil )
        let queryArrayFromRequest = String(data: request.httpBody!, encoding: .utf8)?.components(separatedBy: "&").sorted()
        #expect(queryArrayFromRequest == queryArray)
    }

    @Test func testCreatingURLRequestiWithJSONData() throws {
        let parameters: [String: Any] = ["key": "value", "some_key": "ş"]
        let data = try JSONSerialization.data(withJSONObject: parameters)
        let queryArray = parameters.map {
            "\($0.key)=\($0.value)"
        }.sorted()

        let requestConfiguration: RequestConfiguration = .init(urlString: "http://www.example.com", method: .post, body: data, encoding: .json)
        let request = try requestConfiguration.createURLRequest()

        #expect(request.allHTTPHeaderFields?["Content-Type"] == "application/json")
        #expect(request.httpBody != nil )
        let parametersFromRequest = (try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any])
            .map {
                "\($0.key)=\($0.value)"
            }.sorted()

        #expect(parametersFromRequest == queryArray)
    }
}
