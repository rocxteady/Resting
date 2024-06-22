//
//  LocalizationTests.swift
//  
//
//  Created by Ulaş Sancak on 11.10.2023.
//

import Foundation
import Testing
@testable import Resting

final class LocalizationTests {
    @Test func testLocalizations() async throws {
        let locales = ["en", "tr"]
        for locale in locales {
            guard let path = Bundle.module.path(forResource: locale, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                Issue.record("Missing localization for \(locale)")
                return
            }

            let restingerrorUrlMalformed = bundle.localizedString(forKey: "restingerror.urlMalformed", value: nil, table: nil)

            #expect(!restingerrorUrlMalformed.isEmpty)
            #expect(restingerrorUrlMalformed != "restingerror.urlMalformed")

            let restingerrorStatusCode = bundle.localizedString(forKey: "restingerror.statusCode", value: nil, table: nil)

            #expect(!restingerrorStatusCode.isEmpty)
            #expect(restingerrorStatusCode != "restingerror.statusCode")

            let restingerrorUnknown = bundle.localizedString(forKey: "restingerror.unknown", value: nil, table: nil)

            #expect(!restingerrorUnknown.isEmpty)
            #expect(restingerrorUnknown != "restingerror.urlMalformed")

            let restingerrorWrongParameterType = bundle.localizedString(forKey: "restingerror.wrongParameterType", value: nil, table: nil)

            #expect(!restingerrorWrongParameterType.isEmpty)
            #expect(restingerrorWrongParameterType != "restingerror.wrongParameterType")
        }
    }
}
