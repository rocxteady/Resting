//
//  LocalizationTests.swift
//  
//
//  Created by Ulaş Sancak on 11.10.2023.
//

import XCTest
@testable import Resting

final class LocalizationTests: XCTestCase {
    func testLocalizations() {
        let locales = ["en", "tr"]
        for locale in locales {
            guard let path = Bundle.module.path(forResource: locale, ofType: "lproj"),
                let bundle = Bundle(path: path) else {
                    XCTFail("Missing localization for \(locale)"); return
            }

            let restingerrorUrlMalformed = bundle.localizedString(forKey: "restingerror.urlMalformed", value: nil, table: nil)

            XCTAssertFalse(restingerrorUrlMalformed.isEmpty)
            XCTAssertNotEqual(restingerrorUrlMalformed, "restingerror.urlMalformed")

            let restingerrorStatusCode = bundle.localizedString(forKey: "restingerror.statusCode", value: nil, table: nil)

            XCTAssertFalse(restingerrorStatusCode.isEmpty)
            XCTAssertNotEqual(restingerrorStatusCode, "restingerror.statusCode")

            let restingerrorUnknown = bundle.localizedString(forKey: "restingerror.unknown", value: nil, table: nil)

            XCTAssertFalse(restingerrorUnknown.isEmpty)
            XCTAssertNotEqual(restingerrorUnknown, "restingerror.urlMalformed")

            let restingerrorWrongParameterType = bundle.localizedString(forKey: "restingerror.wrongParameterType", value: nil, table: nil)

            XCTAssertFalse(restingerrorWrongParameterType.isEmpty)
            XCTAssertNotEqual(restingerrorWrongParameterType, "restingerror.wrongParameterType")
        }
    }
}
