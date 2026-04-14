import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

final class MockURLProtocol: URLProtocol {
    struct Stub {
        var response: URLResponse
        var data: Data = Data()
        var error: Error?
        var delay: TimeInterval = 0
    }

    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> Stub)?
    private static let handlerLock = NSLock()

    private var isStopped = false
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
                guard let self, !self.isStopped else {
                    return
                }

                if let error = stub.error {
                    self.client?.urlProtocol(self, didFailWithError: error)
                    return
                }

                self.client?.urlProtocol(self, didReceive: stub.response, cacheStoragePolicy: .notAllowed)
                if !stub.data.isEmpty {
                    self.client?.urlProtocol(self, didLoad: stub.data)
                }
                self.client?.urlProtocolDidFinishLoading(self)
            }

            pendingWorkItem = workItem

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
        isStopped = true
        pendingWorkItem?.cancel()
        client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
    }

    static func setRequestHandler(_ handler: @escaping (URLRequest) throws -> Stub) {
        handlerLock.lock()
        requestHandler = handler
        handlerLock.unlock()
    }

    static func reset() {
        handlerLock.lock()
        requestHandler = nil
        handlerLock.unlock()
    }

    private static func handler() -> ((URLRequest) throws -> Stub)? {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return requestHandler
    }
}
