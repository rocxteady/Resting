import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Async/await-first REST client for executing typed request definitions.
public final class RestClient: NSObject, @unchecked Sendable {
    public let configuration: RestClientConfiguration

    private let transferLock = NSLock()
    private var sessionStorage: URLSession?
    var session: URLSession {
        if let sessionStorage {
            return sessionStorage
        }

        let session = URLSession(
            configuration: configuration.sessionConfiguration,
            delegate: self,
            delegateQueue: nil
        )
        sessionStorage = session
        return session
    }
    private var executor: URLSessionExecutor {
        URLSessionExecutor(session: session)
    }
    private var transfers: [Int: TransferHandle] = [:]

    /// Creates a client from a reusable configuration value.
    public init(configuration: RestClientConfiguration = .init()) {
        self.configuration = configuration
        super.init()
    }

    deinit {
        sessionStorage?.invalidateAndCancel()
    }

    /// Executes a request and returns the validated raw payload.
    public func execute(_ request: RequestDefinition) async throws -> ResponsePayload<Data> {
        let urlRequest = try request.makeURLRequest(
            defaultHeaders: configuration.defaultHeaders,
            encoder: configuration.encoder
        )
        return try await executor.execute(urlRequest)
    }

    /// Executes a request and returns the validated raw response data.
    public func executeData(_ request: RequestDefinition) async throws -> Data {
        try await execute(request).value
    }

    /// Executes a request and decodes its response body.
    public func execute<T: Decodable>(
        _ request: RequestDefinition,
        as type: T.Type = T.self
    ) async throws -> T {
        try await executePayload(request, as: type).value
    }

    /// Executes a request and returns the decoded value with HTTP metadata.
    public func executePayload<T: Decodable>(
        _ request: RequestDefinition,
        as type: T.Type = T.self
    ) async throws -> ResponsePayload<T> {
        let urlRequest = try request.makeURLRequest(
            defaultHeaders: configuration.defaultHeaders,
            encoder: configuration.encoder
        )
        return try await executor.execute(urlRequest, decoder: configuration.decoder, as: type)
    }

    /// Starts a download with isolated progress and cancellation ownership.
    public func download(_ request: RequestDefinition) -> TransferHandle {
        guard request.operation == .download else {
            return TransferHandle(
                immediateFailure: .invalidRequest(reason: "Use RequestDefinition.download(...) for transfer operations.")
            )
        }

        do {
            let urlRequest = try request.makeURLRequest(
                defaultHeaders: configuration.defaultHeaders,
                encoder: configuration.encoder
            )
            let task = session.downloadTask(with: urlRequest)
            let handle = TransferHandle(task: task)
            register(handle, for: task)
            handle.markRunning()
            task.resume()
            return handle
        } catch {
            return TransferHandle(immediateFailure: RestingError.map(error))
        }
    }

    private func register(_ handle: TransferHandle, for task: URLSessionTask) {
        transferLock.lock()
        transfers[task.taskIdentifier] = handle
        transferLock.unlock()
    }

    private func handle(for task: URLSessionTask) -> TransferHandle? {
        transferLock.lock()
        defer { transferLock.unlock() }
        return transfers[task.taskIdentifier]
    }

    private func removeHandle(for task: URLSessionTask) -> TransferHandle? {
        transferLock.lock()
        defer { transferLock.unlock() }
        return transfers.removeValue(forKey: task.taskIdentifier)
    }

    private func makeDownloadedFileURL(response: URLResponse?) -> URL {
        let suggestedName = response?.suggestedFilename ?? UUID().uuidString
        let fileName = suggestedName.isEmpty ? UUID().uuidString : suggestedName
        return FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-\(fileName)")
    }
}

extension RestClient: URLSessionDownloadDelegate {
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        handle(for: downloadTask)?.didWrite(
            totalBytesWritten: totalBytesWritten,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite
        )
    }

    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let handle = handle(for: downloadTask) else {
            return
        }

        let destinationURL = makeDownloadedFileURL(response: downloadTask.response)
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            handle.finish(with: destinationURL)
        } catch {
            handle.fail(with: RestingError.fileSystem(underlying: error))
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handle = removeHandle(for: task) else {
            return
        }

        handle.clearTask()

        if let error {
            handle.fail(with: error)
        }
    }
}
