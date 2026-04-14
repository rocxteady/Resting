import Foundation
#if canImport(FoundationNetworking)
@preconcurrency import FoundationNetworking
#endif

enum FoundationNetworkingSupport {
    static var isAvailable: Bool { true }
}
