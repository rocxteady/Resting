import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

final class MockURLProtocol: URLProtocol {
    struct Stub {
        var response: URLResponse?
        var data: Data = Data()
        var error: Error?
        var delay: TimeInterval = 0
    }

    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> Stub)?
    private static let handlerLock = NSLock()
    // Protected by handlerLock for synchronous URLProtocol callbacks.
    nonisolated(unsafe) private static var activeRequestCount = 0
    nonisolated(unsafe) private static var maximumActiveRequestCount = 0
    nonisolated(unsafe) private static var cancellationCount = 0

    private let stateLock = NSLock()
    private var isStopped = false
    private var isActive = false
    private var pendingWorkItem: DispatchWorkItem?

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
            guard let handler = Self.handler() else {
                fatalError("MockURLProtocol.requestHandler must be configured before use.")
            }

            let stub = try handler(request)
            let workItem = DispatchWorkItem { [weak self] in
                guard let self, self.beginCompletion() else {
                    return
                }
                defer { Self.didFinishRequest() }

                if let error = stub.error {
                    self.client?.urlProtocol(self, didFailWithError: error)
                    return
                }

                if let response = stub.response {
                    self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if !stub.data.isEmpty {
                    self.client?.urlProtocol(self, didLoad: stub.data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            }

            Self.didStartRequest()
            stateLock.lock()
            isActive = true
            pendingWorkItem = workItem
            stateLock.unlock()

            if stub.delay > 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + stub.delay, execute: workItem)
            } else {
                workItem.perform()
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        stateLock.lock()
        guard !isStopped else {
            stateLock.unlock()
            return
        }
        isStopped = true
        let workItem = pendingWorkItem
        pendingWorkItem = nil
        let wasActive = isActive
        isActive = false
        stateLock.unlock()

        workItem?.cancel()
        if wasActive {
            Self.didFinishRequest()
            Self.didCancelRequest()
            client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
        }
    }

    static func setRequestHandler(_ handler: @escaping (URLRequest) throws -> Stub) {
        handlerLock.lock()
        requestHandler = handler
        handlerLock.unlock()
    }

    static func reset() {
        handlerLock.lock()
        requestHandler = nil
        activeRequestCount = 0
        maximumActiveRequestCount = 0
        cancellationCount = 0
        handlerLock.unlock()
    }

    static var observedMaximumActiveRequestCount: Int {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return maximumActiveRequestCount
    }

    static var observedCancellationCount: Int {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return cancellationCount
    }

    private static func handler() -> ((URLRequest) throws -> Stub)? {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return requestHandler
    }

    private func beginCompletion() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard !isStopped, isActive else {
            return false
        }
        isActive = false
        pendingWorkItem = nil
        return true
    }

    private static func didStartRequest() {
        handlerLock.lock()
        activeRequestCount += 1
        maximumActiveRequestCount = max(maximumActiveRequestCount, activeRequestCount)
        handlerLock.unlock()
    }

    private static func didFinishRequest() {
        handlerLock.lock()
        activeRequestCount = max(0, activeRequestCount - 1)
        handlerLock.unlock()
    }

    private static func didCancelRequest() {
        handlerLock.lock()
        cancellationCount += 1
        handlerLock.unlock()
    }
}
