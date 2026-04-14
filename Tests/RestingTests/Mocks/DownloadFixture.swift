import Foundation

enum DownloadFixture {
    static let text = "download fixture"
    static let data = Data(text.utf8)

    static func readString(from fileURL: URL) throws -> String {
        String(decoding: try Data(contentsOf: fileURL), as: UTF8.self)
    }
}
