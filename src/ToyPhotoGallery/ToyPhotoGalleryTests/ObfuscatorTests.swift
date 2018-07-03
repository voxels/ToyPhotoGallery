//
//  ObfuscatorTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class ObfuscatorTests: XCTestCase {
    let salt = [NSString.self, NSSet.self]

    func testBytesByObfuscatingStringReturnsExpectedBytes() {
        let testString = "HelloWorld"
        let expected:[UInt8] = [19, 43, 63, 63, 27, 37, 6, 28, 11, 72]
        let obfuscator = Obfuscator(withSalt: salt)
        let actual = obfuscator.bytesByObfuscatingString(testString)
        XCTAssertEqual(expected, actual)
    }
    
    func testRevealReturnsExpectedString() {
        let expected = "HelloWorld"
        let testBytes:[UInt8] = [19, 43, 63, 63, 27, 37, 6, 28, 11, 72]
        let obfuscator = Obfuscator(withSalt: salt)
        let actual = obfuscator.reveal(testBytes)
        XCTAssertEqual(expected, actual)
    }
}
