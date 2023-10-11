//
//  URLComponents+Helper.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

extension URLComponents {
    /// A computed property that attempts to retrieve the full `URL` from the `URLComponents` instance.
    ///
    /// This computed property aids in safely obtaining the `URL` object from `URLComponents` by ensuring
    /// that the URL is valid before returning it.
    ///
    /// - Returns: The constructed URL if valid.
    /// - Throws: `RestingError.urlMalformed` if the `URLComponents` instance does not represent a valid URL.
    var fullURL: URL {
        get throws {
            guard let url else {
                throw RestingError.urlMalformed
            }
            return url
        }
    }
}
