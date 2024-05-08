//
//  URLSession+AsyncDownload.swift
//
//
//  Created by Ulaş Sancak on 8.05.2024.
//

import Foundation

/// A set of extensions for `URLSession` that provide asynchronous download capabilities.
extension URLSession {
    /// Asynchronously downloads a file for a given `URLRequest`.
    ///
    /// - Parameters:
    ///  - request: The `URLRequest` to be downloaded.
    ///  - Returns: A tuple containing the downloaded file's URL and its associated URL response.
    ///  - Throws: Any errors encountered during the download operation.
    func download(for request: URLRequest) async throws -> (URL, URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            downloadTask(with: request) { url, response, error in
                guard let url, let response else {
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: RestingError.unknown)
                    }
                    return
                }
                continuation.resume(returning: (url, response))
            }
        }
    }
}
