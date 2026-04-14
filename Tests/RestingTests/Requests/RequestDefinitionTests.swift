import XCTest
@testable import Resting

final class RequestDefinitionTests: XCTestCase {
    func testQueryRequestBuildsQueryItemsAndMethod() throws {
        let request = RequestDefinition.query(
            url: URL(string: "https://example.com/articles")!,
            method: .get,
            queryItems: [
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "sort", value: "recent"),
            ],
            headers: ["Accept": "application/json"]
        )

        let urlRequest = try request.makeURLRequest(defaultHeaders: [:], encoder: JSONEncoder())

        XCTAssertEqual(urlRequest.httpMethod, "GET")
        XCTAssertEqual(urlRequest.url?.query, "page=1&sort=recent")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertNil(urlRequest.httpBody)
    }

    func testFormRequestEncodesBodyAndContentType() throws {
        let request = RequestDefinition.form(
            url: URL(string: "https://example.com/login")!,
            fields: [
                "email": "hello@example.com",
                "password": "p@ss word",
            ]
        )

        let urlRequest = try request.makeURLRequest(defaultHeaders: [:], encoder: JSONEncoder())
        let bodyString = try XCTUnwrap(String(data: XCTUnwrap(urlRequest.httpBody), encoding: .utf8))

        XCTAssertEqual(urlRequest.httpMethod, "POST")
        XCTAssertEqual(
            bodyString,
            "email=hello%40example.com&password=p%40ss%20word"
        )
        XCTAssertEqual(
            urlRequest.value(forHTTPHeaderField: "Content-Type"),
            "application/x-www-form-urlencoded; charset=utf-8"
        )
    }

    func testJSONRequestUsesConfiguredEncoder() throws {
        struct CreateArticleRequest: Encodable {
            let title: String
            let createdAt: Date
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let request = RequestDefinition.json(
            url: URL(string: "https://example.com/articles")!,
            body: CreateArticleRequest(
                title: "Modern API",
                createdAt: Date(timeIntervalSince1970: 0)
            )
        )

        let urlRequest = try request.makeURLRequest(defaultHeaders: [:], encoder: encoder)
        let bodyData = try XCTUnwrap(urlRequest.httpBody)
        let bodyObject = try JSONSerialization.jsonObject(with: bodyData) as? [String: String]

        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(bodyObject?["title"], "Modern API")
        XCTAssertEqual(bodyObject?["createdAt"], "1970-01-01T00:00:00Z")
    }

    func testRawRequestRequiresExplicitContentType() {
        let request = RequestDefinition.raw(
            url: URL(string: "https://example.com/upload")!,
            body: Data("payload".utf8),
            contentType: ""
        )

        XCTAssertThrowsError(
            try request.makeURLRequest(defaultHeaders: [:], encoder: JSONEncoder())
        ) { error in
            guard case RestingError.invalidRequest = error else {
                return XCTFail("Expected invalid request error, got \(error)")
            }
        }
    }

    func testRequestHeadersOverrideDefaultsAndAutomaticHeaders() throws {
        let request = RequestDefinition.jsonData(
            url: URL(string: "https://example.com/articles")!,
            body: Data("{}".utf8),
            headers: [
                "Authorization": "Bearer request-token",
                "Content-Type": "application/vnd.api+json",
            ]
        )

        let urlRequest = try request.makeURLRequest(
            defaultHeaders: [
                "Authorization": "Bearer default-token",
                "Accept": "application/json",
            ],
            encoder: JSONEncoder()
        )

        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Authorization"), "Bearer request-token")
        XCTAssertEqual(urlRequest.value(forHTTPHeaderField: "Content-Type"), "application/vnd.api+json")
    }
}
