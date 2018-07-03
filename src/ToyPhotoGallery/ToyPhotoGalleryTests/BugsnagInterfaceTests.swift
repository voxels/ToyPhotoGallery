//
//  BugsnagInterfaceTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery
import Bugsnag

class BugsnagInterfaceTests: XCTestCase {
    let interface = BugsnagInterface()
    
    func testConfigurationReturnsExpectedAPIKey() {
        let expected = "expectedAPIKey"
        let configuration = BugsnagInterface.configuration(for: expected, shouldCaptureSessions: false)
        let actual = configuration.apiKey
        XCTAssertEqual(expected, actual)
    }
    
    func testConfigurationReturnsExpectedShouldAutocaptureSessionsFlag() {
        let expected = true
        let configuration = BugsnagInterface.configuration(for: "config", shouldCaptureSessions: expected)
        let actual = configuration.shouldAutoCaptureSessions
        XCTAssertEqual(expected, actual)
    }
    
    func testLaunchThrowsMissingRequiredKeyError() {
        let waitExpectation = expectation(description: "Wait for expectation")
        do {
            try interface.launch(with: nil)
        } catch {
            waitExpectation.fulfill()
        }
        let actual = register(expectations:[waitExpectation], duration:XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testLaunchPostsDidLaunchErrorHandlerNotification() {
        let emptyKey = ""
        let waitExpectation = expectation(forNotification: Notification.Name.DidLaunchErrorHandler, object: nil, handler: nil)
        do {
            try interface.launch(with: emptyKey)
        } catch {
            XCTFail(error.localizedDescription)
        }
        let actual = register(expectations:[waitExpectation], duration:XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
}
