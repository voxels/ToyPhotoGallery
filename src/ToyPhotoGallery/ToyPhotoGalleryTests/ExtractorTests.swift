//
//  ExtractorTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class ExtractorTests: XCTestCase {
    var testErrorHandler:TestErrorHandler?
    var testRemoteStoreController:TestRemoteStoreController?
    var resourceModelController:ResourceModelController?
    var networkSessionInterface:NetworkSessionInterface?
    
    override func setUp() {
        testErrorHandler = TestErrorHandler()
        testRemoteStoreController = TestRemoteStoreController()
        networkSessionInterface = NetworkSessionInterface(with: testErrorHandler!)
    }

    func testExtractValueExtractsExpectedString() {
        let expectedString = "actual"
        let blob = ["expected":expectedString as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface:networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let actual:String = try Extractor.extractValue(named: "expected", from: blob)
            XCTAssertEqual(expectedString, actual)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExtractValueExtractsExpectedURL() {
        let expectedURLString = "http://apple.com"
        let blob = ["expected": expectedURLString as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface:networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let actual:URL = try Extractor.extractValue(named: "expected", from: blob)
            XCTAssertEqual(actual.absoluteString, expectedURLString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExtractValueExtractsExpectedDate() {
        let expectedDate = Date()
        let blob = ["expected": expectedDate as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let actual:Date = try Extractor.extractValue(named: "expected", from: blob)
            XCTAssertEqual(actual, expectedDate)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExtractValueThrowsExpectedMissingObjectIDError() {
        let waitExpectation = expectation(description: "Wait for completion")
        
        let key = "unexpected"
        let blob = ["unexpected":key as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let string:String? = try Extractor.extractValue(named: RemoteStoreTableMap.CommonColumn.objectId.rawValue, from: blob)
            XCTFail("Should not reach this point")
            print(string ?? "") // silencing the warning
        } catch {
            switch error {
            case ModelError.EmptyObjectId:
                waitExpectation.fulfill()
            default:
                XCTFail(error.localizedDescription)
            }
        }
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testExtractValueThrowsExpectedMissingValueError() {
        let waitExpectation = expectation(description: "Wait for completion")
        
        let key = "unexpected"
        let blob = ["unexpected":key as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let string:String? = try Extractor.extractValue(named: "expected", from: blob)
            XCTFail("Should not reach this point")
            print(string ?? "") // silencing the warning
        } catch {
            switch error {
            case ModelError.MissingValue:
                waitExpectation.fulfill()
            default:
                XCTFail(error.localizedDescription)
            }
        }
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testExtractValueThrowsExpectedIncorrectTypeError() {
        let waitExpectation = expectation(description: "Wait for completion")
        
        let key = "unexpected"
        let blob = ["unexpected":key as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let date:Date = try Extractor.extractValue(named: key, from: blob)
            XCTFail("Should not reach this point")
            print(String(describing:date)) // silencing the warning
        } catch {
            switch error {
            case ModelError.IncorrectType:
                waitExpectation.fulfill()
            default:
                XCTFail(error.localizedDescription)
            }
        }
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testConstructURLConstructsExpectedURL() {
        let expectedURLString = "http://apple.com"
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let actual:URL = try Extractor.constructURL(from: expectedURLString as AnyObject)
            XCTAssertEqual(expectedURLString, actual.absoluteString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConstructURLThrowsExpectedInvalidURLError() {
        let waitExpectation = expectation(description: "Wait for completion")
        
        let expectedURLString = ""
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let _:URL = try Extractor.constructURL(from: expectedURLString as AnyObject)
            XCTFail("Should not reach this point")
        } catch {
            switch error {
            case ModelError.InvalidURL:
                waitExpectation.fulfill()
            default:
                XCTFail(error.localizedDescription)
            }
        }
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testConstructURLThrowsExpectedIncorrectTypeError() {
        let waitExpectation = expectation(description: "Wait for completion")
        
        let unexpectedDate = Date() as AnyObject
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface!, errorHandler: testErrorHandler!)
        do {
            let _:URL = try Extractor.constructURL(from: unexpectedDate)
            XCTFail("Should not reach this point")
        } catch {
            switch error {
            case ModelError.IncorrectType:
                waitExpectation.fulfill()
            default:
                XCTFail(error.localizedDescription)
            }
        }
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
}
