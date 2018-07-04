//
//  ParseInterfaceTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
import Parse
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
    
    func testFindTableCallsExpectedCompletion() {
        let waitExpectation = expectation(description: "Wait for expectation")
        let interface = TestParseInterface()
        let errorHandler = TestErrorHandler()
        interface.find(table: .Resource, sortBy: nil, skip: 0, limit: 0, errorHandler: errorHandler) { (objects) in
            waitExpectation.fulfill()
        }
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testFindTableCallsFindQuery() {
        let waitExpectation = expectation(description: "Wait for expectation")
        let interface = TestParseInterface()
        let errorHandler = TestErrorHandler()
        interface.find(table: .Resource, sortBy: nil, skip: 0, limit: 0, errorHandler: errorHandler) { (objects) in
            XCTAssertTrue(interface.didFindQuery)
            waitExpectation.fulfill()
        }
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testParseFindCompletionReturnsWrappedCompletion() {
        let waitExpectation = expectation(description: "Wait for expectation")

        let findCompletion:FindCompletion = { (objects) in
            waitExpectation.fulfill()
        }
        
        let interface = TestParseInterface()
        let errorHandler = TestErrorHandler()
        let parseFindCompletion = interface.parseFindCompletion(with:errorHandler, for: findCompletion)
        parseFindCompletion(nil, nil)
        
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testParseFindCompletionReturnsEmptyArrayForNoResults() {
        func testParseFindCompletionReturnsWrappedCompletion() {
            let waitExpectation = expectation(description: "Wait for expectation")
            
            let findCompletion:FindCompletion = { (objects) in
                XCTAssertNotNil(objects)
                waitExpectation.fulfill()
            }
            
            let interface = TestParseInterface()
            let errorHandler = TestErrorHandler()
            let parseFindCompletion = interface.parseFindCompletion(with:errorHandler, for: findCompletion)
            parseFindCompletion(nil, nil)
            
            let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
            XCTAssertTrue(actual)
        }
    }
    
    func testParseFindCompletionReportsError() {
        let waitExpectation = expectation(description: "Wait for expectation")
        
        let interface = TestParseInterface()
        let errorHandler = TestErrorHandler()
        
        let findCompletion:FindCompletion = { (objects) in
            XCTAssertTrue(errorHandler.didReport)
            waitExpectation.fulfill()
        }

        let parseFindCompletion = interface.parseFindCompletion(with:errorHandler, for: findCompletion)
        let error = RemoteStoreError.InvalidSortByColumn
        parseFindCompletion(nil, error)
        
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testFindQueryCallsCompletion() {
        let waitExpectation = expectation(description: "Wait for expectation")
        
        let findCompletion:ParseFindCompletion = { (objects, error) in
            waitExpectation.fulfill()
        }
        
        let interface = TestParseInterface()
        do {
            let query = try interface.query(for: .Resource, sortBy: nil, skip: 0, limit: 0)
            interface.find(query: query, completion: findCompletion)
        } catch {
            XCTFail("Received unexpected error: \(error.localizedDescription)")
        }
        
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testQueryForTableSetsClassName() {
        let interface = TestParseInterface()
        do {
            let query = try interface.query(for: .Resource, sortBy: nil, skip: 0, limit: 0)
            let actual = query.parseClassName
            XCTAssertEqual(RemoteStoreTableMap.Resource.rawValue, actual)
        } catch {
            XCTFail("Received unexpected error: \(error.localizedDescription)")
        }
    }
    
    // func testQueryForTableSetsSortOrder is missing
    // query sort order is not a value that can be checked
    
    func testQueryForTableSetsSkipValue() {
        let interface = TestParseInterface()
        let expected = 10
        do {
            let query = try interface.query(for: .Resource, sortBy: nil, skip: expected, limit: 0)
            let actual = query.skip
            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Received unexpected error: \(error.localizedDescription)")
        }
    }
    
    func testQueryForTableSetsLimitValue() {
        let interface = TestParseInterface()
        let expected = 10
        do {
            let query = try interface.query(for: .Resource, sortBy: nil, skip: 0, limit: expected)
            let actual = query.limit
            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Received unexpected error: \(error.localizedDescription)")
        }
    }
    
    func testQueryForTableSetsCachePolicy() {
        let interface = TestParseInterface()
        let expected:PFCachePolicy = .cacheOnly
        do {
            let query = try interface.query(for: .Resource, sortBy: nil, skip: 0, limit: 0, cachePolicy: expected)
            let actual = query.cachePolicy
            XCTAssertEqual(expected, actual)
        } catch {
            XCTFail("Received unexpected error: \(error.localizedDescription)")
        }
    }
}
