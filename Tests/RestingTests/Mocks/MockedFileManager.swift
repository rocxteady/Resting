//
//  MockedFileManager.swift
//  
//
//  Created by Ulaş Sancak on 23.06.2024.
//

import Foundation

class MockedFileManager: FileManager {
    override func moveItem(at srcURL: URL, to dstURL: URL) throws {}
}
