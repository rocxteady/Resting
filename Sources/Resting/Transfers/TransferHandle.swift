import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

/// Represents one in-flight download and its lifecycle.
public final class TransferHandle: @unchecked Sendable {
    /// Current transfer lifecycle state.
    public enum State: Sendable {
        case initialized
        case running
        case completed
        case failed
        case cancelled
    }

    public let id: UUID

    /// `Progress` for this transfer only.
    public let progress: Progress

    private let lock = NSLock()
    private let resultBox = TransferResultBox()
    private weak var task: URLSessionDownloadTask?
    private var observers: [(Progress) -> Void] = []
    private var stateStorage: State

    init(task: URLSessionDownloadTask) {
        self.id = UUID()
        self.progress = task.progress
        self.task = task
        self.stateStorage = .initialized
    }

    init(immediateFailure error: RestingError) {
        self.id = UUID()
        self.progress = Progress(totalUnitCount: 1)
        self.stateStorage = .failed
        self.progress.completedUnitCount = 1
        self.resultBox.resolve(.failure(error))
    }

    /// Current state of this transfer handle.
    public var state: State {
        lock.lock()
        defer { lock.unlock() }
        return stateStorage
    }

    /// Awaits the downloaded file URL for this transfer.
    public var value: URL {
        get async throws {
            try await resultBox.value()
        }
    }

    /// Registers a progress observer for this handle only.
    public func observeProgress(_ observer: @escaping (Progress) -> Void) {
        lock.lock()
        observers.append(observer)
        let currentProgress = progress
        lock.unlock()
        observer(currentProgress)
    }

    /// Cancels this transfer without affecting any other operation.
    public func cancel() {
        lock.lock()
        let currentTask = task
        lock.unlock()
        currentTask?.cancel()
    }
}

extension TransferHandle {
    func markRunning() {
        updateState(.running)
    }

    func didWrite(totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        lock.lock()
        if totalBytesExpectedToWrite > 0 {
            progress.totalUnitCount = totalBytesExpectedToWrite
            progress.completedUnitCount = totalBytesWritten
        }
        let callbacks = observers
        let currentProgress = progress
        lock.unlock()
        callbacks.forEach { $0(currentProgress) }
    }

    func finish(with fileURL: URL) {
        guard transitionToTerminal(.completed) else {
            return
        }

        lock.lock()
        if progress.totalUnitCount <= 0 {
            progress.totalUnitCount = 1
        }
        progress.completedUnitCount = progress.totalUnitCount
        let callbacks = observers
        let currentProgress = progress
        lock.unlock()

        resultBox.resolve(.success(fileURL))
        callbacks.forEach { $0(currentProgress) }
    }

    func fail(with error: Error) {
        let mappedError = RestingError.map(error)
        let terminalState: State = mappedError == .cancelled ? .cancelled : .failed
        guard transitionToTerminal(terminalState) else {
            return
        }

        resultBox.resolve(.failure(mappedError))
    }

    func clearTask() {
        lock.lock()
        task = nil
        lock.unlock()
    }

    private func transitionToTerminal(_ nextState: State) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard stateStorage != .completed, stateStorage != .failed, stateStorage != .cancelled else {
            return false
        }
        stateStorage = nextState
        return true
    }

    private func updateState(_ nextState: State) {
        lock.lock()
        stateStorage = nextState
        lock.unlock()
    }
}

private final class TransferResultBox {
    private let lock = NSLock()
    private var result: Result<URL, Error>?
    private var continuations: [CheckedContinuation<URL, Error>] = []

    func value() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if let result {
                lock.unlock()
                continuation.resume(with: result)
                return
            }
            continuations.append(continuation)
            lock.unlock()
        }
    }

    func resolve(_ result: Result<URL, Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let pendingContinuations = continuations
        continuations.removeAll()
        lock.unlock()

        pendingContinuations.forEach { $0.resume(with: result) }
    }
}

private extension RestingError {
    static func == (lhs: RestingError, rhs: RestingError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled):
            return true
        default:
            return false
        }
    }
}
