import Foundation

enum DownloadFixture {
    static let text = "download fixture"
    static let data = Data(text.utf8)

    static func readData(from fileURL: URL) throws -> Data {
        try Data(contentsOf: fileURL)
    }

    static func readString(from fileURL: URL) throws -> String {
        String(decoding: try readData(from: fileURL), as: UTF8.self)
    }

    static func removeIfPresent(_ fileURL: URL) throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: fileURL)
    }
}
