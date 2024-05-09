// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation

/// Represents the configuration for a `RestClient` instance.
///
/// Encapsulates the `URLSessionConfiguration` and `JSONDecoder` to be used by the `RestClient`.
public struct RestClientConfiguration {
    /// The session configuration for network requests.
    let sessionConfiguration: URLSessionConfiguration

    /// The JSON decoder for decoding responses.
    let jsonDecoder: JSONDecoder

    /// Creates a new `RestClientConfiguration` instance with the specified `URLSessionConfiguration` and `JSONDecoder`.
    ///
    /// - Parameters:
    ///   - sessionConfiguration: The session configuration for network requests, defaults to `.default`.
    ///   - jsonDecoder: The JSON decoder for decoding responses, defaults to a new `JSONDecoder` instance.
    public init(sessionConfiguration: URLSessionConfiguration = .default, jsonDecoder: JSONDecoder = .init()) {
        self.sessionConfiguration = sessionConfiguration
        self.jsonDecoder = jsonDecoder
    }
}

/// Represents a client for making RESTful network requests.
/// ///
/// This client utilizes a `RestClientConfiguration` to configure its behavior, including the session configuration and JSON decoding.
public class RestClient: NSObject {
    private lazy var session: URLSession = URLSession(configuration: clientConfiguration.sessionConfiguration, delegate: self, delegateQueue: nil)
    private let clientConfiguration: RestClientConfiguration

    private var downloadCompletion: ((URL?, Error?) -> Void)?
    private var progress: ((Double) -> Void)?
    private var downloadTask: URLSessionDownloadTask?

    /// Creates a new `RestClient` instance with the specified `RestClientConfiguration`.
    ///
    /// - Parameters:
    ///   - configuration: The configuration used to set up the client, defaults to a new `RestClientConfiguration` instance with a default `URLSessionConfiguration`.
    public init(configuration: RestClientConfiguration = .init(sessionConfiguration: .default)) {
        self.clientConfiguration = configuration
        super.init()
    }
}

// MARK: Async/Await functionality
extension RestClient {
    /// Fetches raw data based on the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: A `Data` object.
    /// - Throws: Throws an error if the request fails or if the response can't be created.
    public func fetch(with configuration: RequestConfiguration) async throws -> Data {
        let urlRequest = try configuration.createURLRequest()
        let response = try await session.dataWithURLResponse(for: urlRequest)
        return try response.createResponse()
    }
    
    /// Fetches and decodes a `Decodable` model based on the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: A `Decodable` model.
    /// - Throws: Throws an error if the request fails, if the data can't be decoded, or if the response can't be created.
    public func fetch<T: Decodable>(with configuration: RequestConfiguration) async throws -> T {
        let data = try await fetch(with: configuration)
        return try clientConfiguration.jsonDecoder.decode(T.self, from: data)
    }

    /// Downloads a file based on the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: A `URL` to the downloaded file.
    /// - Throws: Throws an error if the request fails or if the response can't be created.
    public func download(with configuration: RequestConfiguration, completion: @escaping (URL?, Error?) -> Void, progress: ((Double) -> Void)? = nil) {
        self.downloadCompletion = completion
        self.progress = progress
        do {
            let urlRequest = try configuration.createURLRequest()
            downloadTask = session.downloadTask(with: urlRequest)
            downloadTask?.resume()
        } catch {
            completion(nil, error)
            self.downloadCompletion = nil
            self.progress = nil
        }
    }
    
    public func cancel() {
        downloadTask?.cancel()
    }
}

extension RestClient: URLSessionDownloadDelegate {    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        downloadCompletion?(nil, error)
        downloadCompletion = nil
        progress = nil
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        defer {
            self.downloadCompletion = nil
            self.progress = nil
        }
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let savedURL = documentsURL.appendingPathComponent(
                location.lastPathComponent)
            try FileManager.default.moveItem(at: location, to: savedURL)
            downloadCompletion?(savedURL, nil)
        } catch {
            downloadCompletion?(nil, error)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard downloadTask == self.downloadTask else { return }
        let bytesWritten = Double(bytesWritten)
        let totalBytesWritten = Double(totalBytesWritten)
        progress?(bytesWritten/totalBytesWritten)
    }
}

// MARK: Combine-based API functionality
import Combine

extension RestClient {
    /// Returns a publisher that emits the raw data for the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: An `AnyPublisher` that emits `Data` or an error.
    public func publisher(with configuration: RequestConfiguration) -> AnyPublisher<Data, Error> {
        do {
            let urlRequest = try configuration.createURLRequest()
            return session.dataWithURLResponsePublisher(for: urlRequest)
                .tryMap() {
                    return try $0.createResponse()
                }.eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    /// Returns a publisher that emits a `Decodable` model for the provided request configuration.
    ///
    /// - Parameter configuration: The configuration for the network request.
    /// - Returns: An `AnyPublisher` that emits a `Decodable` model or an error.
    public func publisher<T: Decodable>(with configuration: RequestConfiguration) -> AnyPublisher<T, Error> {
        let jsonDecoder = clientConfiguration.jsonDecoder
        return publisher(with: configuration)
            .tryMap { data in
                return try jsonDecoder.decode(T.self, from: data)
            }.eraseToAnyPublisher()
    }
}
