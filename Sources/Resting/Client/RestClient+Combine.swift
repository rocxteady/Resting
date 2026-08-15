import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif
#if canImport(Combine)
import Combine

extension RestClient {
    /// Publishes a request's validated raw payload.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A publisher that emits bytes and HTTP metadata for a
    ///   `200..<300` response or a typed `RestingError`.
    /// - Note: The publisher retains this client while it or an active
    ///   subscription is retained.
    public func publisher(for request: RequestDefinition) -> AnyPublisher<ResponsePayload<Data>, RestingError> {
        do {
            let urlRequest = try request.makeURLRequest(
                defaultHeaders: configuration.defaultHeaders,
                encoder: configuration.encoder
            )

            return session.dataTaskPublisher(for: urlRequest)
                .mapError { RestingError.map($0) }
                .tryMap { [self] output in
                    _ = self
                    let httpResponse = try ResponseValidator().validate(data: output.data, response: output.response)
                    return ResponsePayload(value: output.data, response: httpResponse)
                }
                .mapError { RestingError.map($0) }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: RestingError.map(error)).eraseToAnyPublisher()
        }
    }

    /// Publishes a request's validated raw response data.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: A publisher that emits bytes for a `200..<300` response or a
    ///   typed `RestingError`.
    /// - Note: The publisher retains this client while it or an active
    ///   subscription is retained.
    public func dataPublisher(for request: RequestDefinition) -> AnyPublisher<Data, RestingError> {
        publisher(for: request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    /// Publishes a request's decoded response value.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - type: The response value type.
    /// - Returns: A publisher that emits the decoded value or a typed
    ///   `RestingError`; decoding failures retain the original response bytes.
    /// - Note: The publisher retains this client while it or an active
    ///   subscription is retained.
    public func publisher<T: Decodable>(
        for request: RequestDefinition,
        as type: T.Type = T.self
    ) -> AnyPublisher<T, RestingError> {
        publisher(for: request)
            .tryMap { [self] payload in
                do {
                    return try self.configuration.decoder.decode(type, from: payload.value)
                } catch {
                    throw RestingError.map(error, responseData: payload.value)
                }
            }
            .mapError { RestingError.map($0) }
            .eraseToAnyPublisher()
    }
}
#endif
