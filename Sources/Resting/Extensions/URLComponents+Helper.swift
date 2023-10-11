//
//  URLComponents+Helper.swift
//  
//
//  Created by Ulaş Sancak on 10.10.2023.
//

import Foundation

extension URLComponents {
    var fullURL: URL {
        get throws {
            guard let url else {
                throw RestingError.urlMalformed
            }
            return url
        }
    }
}
