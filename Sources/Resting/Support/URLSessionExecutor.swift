import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

struct URLSessionExecutor {
    private let session: URLSession
    private let validator: ResponseValidator

    init(session: URLSession, validator: ResponseValidator = .init()) {
        self.session = session
        self.validator = validator
    }

    func execute(_ request: URLRequest) async throws -> ResponsePayload<Data> {
        do {
            let (data, response) = try await session.data(for: request)
            let httpResponse = try validator.validate(data: data, response: response)
            return ResponsePayload(value: data, response: httpResponse)
        } catch {
            throw RestingError.map(error)
        }
    }

    func execute<T: Decodable>(
        _ request: URLRequest,
        decoder: JSONDecoder,
        as type: T.Type
    ) async throws -> ResponsePayload<T> {
        let payload = try await execute(request)
        do {
            let decodedValue = try decoder.decode(type, from: payload.value)
            return ResponsePayload(value: decodedValue, response: payload.response)
        } catch {
            throw RestingError.map(error, responseData: payload.value)
        }
    }
}
