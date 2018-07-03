//
//  ParseInterfaceTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class ParseInterfaceTests: XCTestCase {
    let interface = ParseInterface()
    
    func testConfigurationReturnsExpectedApplicationId() {
        let expected = "expectedAPIKey"
        let serverKey = "serverKey"
        let configuration = ParseInterface.configuration(with: expected, for: serverKey)
        let actual = configuration.applicationId
        XCTAssertEqual(expected, actual)
    }
    
    func testConfigurationReturnsExpectedServerURLString() {
        let applicationId = "applicationId"
        let expected = "serverKey"
        let configuration = ParseInterface.configuration(with: applicationId, for: expected)
        let actual = configuration.server
        XCTAssertEqual(expected, actual)

    }
    
    func testLaunchThrowsMissingRequiredKeyError() {
        let waitExpectation = expectation(description: "Wait for expectation")
        do {
            try interface.launch(with: nil)
        } catch {
            waitExpectation.fulfill()
        }
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testLaunchThrowsDuplicateLaunchError() {
        let applicationId = "applicationId"
        let waitExpectation = expectation(description: "Wait for duplicate launch expectation")
        do {
            try interface.launch(with: applicationId)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        do {
            try interface.launch(with: applicationId)
        } catch {
            switch error {
            case LaunchError.DuplicateLaunch:
                waitExpectation.fulfill()
            default:
                XCTFail("Unexpected Error Received")
            }
        }
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
}
