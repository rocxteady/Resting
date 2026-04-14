import XCTest

final class LocalizationResourceTests: XCTestCase {
    func testAllPublicErrorKeysExistInEnglishAndTurkish() throws {
        let locales = ["en", "tr"]
        let keys = [
            "restingerror.invalidRequest",
            "restingerror.transport",
            "restingerror.invalidResponse",
            "restingerror.statusCode",
            "restingerror.decoding",
            "restingerror.cancelled",
            "restingerror.fileSystem",
        ]

        let resourceBundleURL = try XCTUnwrap(findResourceBundleURL())
        let resourceBundle = try XCTUnwrap(Bundle(url: resourceBundleURL))

        for locale in locales {
            let path = try XCTUnwrap(resourceBundle.path(forResource: locale, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))

            for key in keys {
                let value = bundle.localizedString(forKey: key, value: nil as String?, table: nil as String?)
                XCTAssertFalse(value.isEmpty, "Missing localized value for \(key) in \(locale)")
                XCTAssertNotEqual(value, key, "Missing localized value for \(key) in \(locale)")
            }
        }
    }

    private func findResourceBundleURL() -> URL? {
        let fileManager = FileManager.default
        let candidateRoots = [
            Bundle(for: Self.self).bundleURL.deletingLastPathComponent(),
            Bundle.main.bundleURL.deletingLastPathComponent(),
            URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent(".build", isDirectory: true),
        ]

        for root in candidateRoots {
            guard let enumerator = fileManager.enumerator(at: root, includingPropertiesForKeys: nil) else {
                continue
            }

            if let bundleURL = enumerator
                .compactMap({ $0 as? URL })
                .first(where: { $0.lastPathComponent == "Resting_Resting.bundle" }) {
                return bundleURL
            }
        }

        return nil
    }
}
