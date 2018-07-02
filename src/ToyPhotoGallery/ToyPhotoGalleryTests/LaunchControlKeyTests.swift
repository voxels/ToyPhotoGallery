//
//  LaunchControllerKeyTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class LaunchControlKeyTests: XCTestCase {
    
    let actualBytes:[UInt8] = [99, 48, 87, 77, 50, 94, 94, 77, 90, 119, 3, 85, 93, 4, 71, 78, 29, 116, 20, 64, 112, 87, 89, 85, 95, 7, 18, 82, 21, 66, 119, 48]
    let obfuscator = Obfuscator(withSalt: [AppDelegate.self, NSString.self, NSSet.self])
    
    func testDecodedReturnsExpectedString() {
        let expectedString = "8d84b61950b91a5735d042508ff79b9c"
        let actual = LaunchControlKey.BugsnagAPIKey.decoded(with: obfuscator)
        XCTAssertEqual(expectedString, actual)
    }
}
