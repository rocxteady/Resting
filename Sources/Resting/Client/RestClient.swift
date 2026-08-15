import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// A concurrency-safe, async/await-first client for executing typed requests.
///
/// One client may execute overlapping operations. Its networking session is
/// created during initialization and is released automatically after the client
/// and any active work are released.
public final class RestClient: NSObject, @unchecked Sendable {
    /// The immutable configuration snapshot used by this client.
    public let configuration: RestClientConfiguration

    private let downloadDelegate: RestClientDownloadDelegate
    let session: URLSession
    private var executor: URLSessionExecutor {
        URLSessionExecutor(session: session)
    }

    /// Creates a client from a reusable configuration value.
    public init(configuration: RestClientConfiguration = .init()) {
        let downloadDelegate = RestClientDownloadDelegate()
        self.configuration = configuration
        self.downloadDelegate = downloadDelegate
        self.session = URLSession(
            configuration: configuration.sessionConfiguration,
            delegate: downloadDelegate,
            delegateQueue: nil
        )
        super.init()
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    /// Executes a request and returns its validated raw payload.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: Response bytes and final HTTP metadata for a `200..<300` response.
    /// - Throws: A `RestingError` describing request construction, transport,
    ///   cancellation, invalid-response, or status-code failure.
    public func execute(_ request: RequestDefinition) async throws -> ResponsePayload<Data> {
        let urlRequest = try request.makeURLRequest(
            defaultHeaders: configuration.defaultHeaders,
            encoder: configuration.encoder
        )
        return try await executor.execute(urlRequest)
    }

    /// Executes a request and returns its validated raw response data.
    ///
    /// - Parameter request: The request to execute.
    /// - Returns: Response bytes for a `200..<300` response.
    /// - Throws: A `RestingError` describing request construction, transport,
    ///   cancellation, invalid-response, or status-code failure.
    public func executeData(_ request: RequestDefinition) async throws -> Data {
        try await execute(request).value
    }

    /// Executes a request and decodes its validated response body.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - type: The response value type.
    /// - Returns: The decoded response value.
    /// - Throws: A `RestingError` describing request, transport, response,
    ///   cancellation, or decoding failure. Decoding failures retain response bytes.
    public func execute<T: Decodable>(
        _ request: RequestDefinition,
        as type: T.Type = T.self
    ) async throws -> T {
        try await executePayload(request, as: type).value
    }

    /// Executes a request and returns its decoded value with HTTP metadata.
    ///
    /// - Parameters:
    ///   - request: The request to execute.
    ///   - type: The response value type.
    /// - Returns: The decoded value and final `200..<300` HTTP response.
    /// - Throws: A `RestingError` describing request, transport, response,
    ///   cancellation, or decoding failure. Decoding failures retain response bytes.
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

    /// Starts a validated download with isolated progress and cancellation ownership.
    ///
    /// - Parameter request: A request created with `RequestDefinition.download`.
    /// - Returns: A handle whose value is a temporary file only for a final
    ///   `200..<300` response. Rejected temporary files are removed best-effort.
    /// - Note: Errors are delivered through ``TransferHandle/value``. Cancelling
    ///   the returned handle does not affect overlapping operations.
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
            downloadDelegate.register(handle, for: task)
            handle.markRunning()
            task.resume()
            return handle
        } catch {
            return TransferHandle(immediateFailure: RestingError.map(error))
        }
    }

}

extension RestClient: URLSessionDownloadDelegate {
    /// Forwards download progress to the transfer registered for the task.
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        downloadDelegate.urlSession(
            session,
            downloadTask: downloadTask,
            didWriteData: bytesWritten,
            totalBytesWritten: totalBytesWritten,
            totalBytesExpectedToWrite: totalBytesExpectedToWrite
        )
    }

    /// Forwards a downloaded temporary file to the transfer registered for the task.
    public func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        downloadDelegate.urlSession(
            session,
            downloadTask: downloadTask,
            didFinishDownloadingTo: location
        )
    }

    /// Forwards task completion to the transfer registered for the task.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        downloadDelegate.urlSession(session, task: task, didCompleteWithError: error)
    }
}

private final class RestClientDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var transfers: [Int: TransferHandle] = [:]

    func register(_ handle: TransferHandle, for task: URLSessionTask) {
        lock.lock()
        transfers[task.taskIdentifier] = handle
        lock.unlock()
    }

    func urlSession(
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

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let handle = handle(for: downloadTask) else {
            return
        }

        finishDownload(at: location, response: downloadTask.response, handle: handle)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let handle = removeHandle(for: task) else {
            return
        }

        handle.clearTask()

        if let error {
            handle.fail(with: error)
        }
    }

    private func handle(for task: URLSessionTask) -> TransferHandle? {
        lock.lock()
        defer { lock.unlock() }
        return transfers[task.taskIdentifier]
    }

    private func removeHandle(for task: URLSessionTask) -> TransferHandle? {
        lock.lock()
        defer { lock.unlock() }
        return transfers.removeValue(forKey: task.taskIdentifier)
    }

}

func finishDownload(at location: URL, response: URLResponse?, handle: TransferHandle) {
    do {
        _ = try ResponseValidator().validate(response: response) {
            guard let data = try? Data(contentsOf: location), !data.isEmpty else {
                return nil
            }
            return data
        }

        let suggestedName = response?.suggestedFilename ?? UUID().uuidString
        let fileName = suggestedName.isEmpty ? UUID().uuidString : suggestedName
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-\(fileName)")
        try FileManager.default.moveItem(at: location, to: destinationURL)
        if !handle.finish(with: destinationURL) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
    } catch {
        try? FileManager.default.removeItem(at: location)
        handle.fail(with: error is RestingError ? error : RestingError.fileSystem(underlying: error))
    }
}
