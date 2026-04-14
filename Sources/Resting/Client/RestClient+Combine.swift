import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif
#if canImport(Combine)
import Combine

extension RestClient {
    /// Executes a request and publishes its validated raw payload.
    public func publisher(for request: RequestDefinition) -> AnyPublisher<ResponsePayload<Data>, RestingError> {
        do {
            let urlRequest = try request.makeURLRequest(
                defaultHeaders: configuration.defaultHeaders,
                encoder: configuration.encoder
            )

            return session.dataTaskPublisher(for: urlRequest)
                .mapError { RestingError.map($0) }
                .tryMap { output in
                    let validator = ResponseValidator()
                    let httpResponse = try validator.validate(data: output.data, response: output.response)
                    return ResponsePayload(value: output.data, response: httpResponse)
                }
                .mapError { RestingError.map($0) }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: RestingError.map(error)).eraseToAnyPublisher()
        }
    }

    /// Executes a request and publishes its raw response data.
    public func dataPublisher(for request: RequestDefinition) -> AnyPublisher<Data, RestingError> {
        publisher(for: request)
            .map(\.value)
            .eraseToAnyPublisher()
    }

    /// Executes a request and publishes its decoded response value.
    public func publisher<T: Decodable>(
        for request: RequestDefinition,
        as type: T.Type = T.self
    ) -> AnyPublisher<T, RestingError> {
        publisher(for: request)
            .tryMap { [self] payload in
                try self.configuration.decoder.decode(type, from: payload.value)
            }
            .mapError { RestingError.map($0) }
                .eraseToAnyPublisher()
    }
}
#endif
