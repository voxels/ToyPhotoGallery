//
//  ResourceModelControllerTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class ResourceModelControllerTests: XCTestCase {
    
    var testErrorHandler:TestErrorHandler?
    var testRemoteStoreController:TestRemoteStoreController?
    var resourceModelController:ResourceModelController?
    
    override func setUp() {
        testErrorHandler = TestErrorHandler()
        testRemoteStoreController = TestRemoteStoreController()
    }

    func testBuildRespositoryFindsExpectedResources() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        resourceModelController!.buildRepository(from: testRemoteStoreController!, with: testErrorHandler!) {[weak self] (errors) in
            
            if let errors = errors, errors.count > 0 {
                XCTFail("Received unexpected errors")
            }
            
            guard let first = self?.resourceModelController!.imageRepository.first else {
                XCTFail("Expected resource not found")
                return
            }
            
            XCTAssertEqual(first.key, ImageRepositoryTests.imageResourceRawObject["objectId"] as! String)
            
            waitExpectation.fulfill()
        }
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testBuildRepositoryCleansImageRepository() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        let unexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "notathing", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string:"http://apple.com")!)
        let otherUnexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "anotherthing", thumbnailURL: URL(string: "http://verizon.com")!, fileURL: URL(string:"http://verizon.com")!)
        resourceModelController?.imageRepository = ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        
        resourceModelController!.buildRepository(from: testRemoteStoreController!, with: testErrorHandler!) {[weak self] (errors) in
            
            if let errors = errors, errors.count > 0 {
                XCTFail("Received unexpected errors")
            }

            guard let repository = self?.resourceModelController!.imageRepository, repository.keys.count == 1, let first = self?.resourceModelController!.imageRepository.first else {
                XCTFail("Expected resource not found")
                return
            }
            
            XCTAssertEqual(first.key, ImageRepositoryTests.imageResourceRawObject["objectId"] as! String)
            
            waitExpectation.fulfill()
        }
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testCleanRepositoryCleansImageRepository() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        let unexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "notathing", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string:"http://apple.com")!)
        let otherUnexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "anotherthing", thumbnailURL: URL(string: "http://verizon.com")!, fileURL: URL(string:"http://verizon.com")!)
        resourceModelController?.imageRepository = ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        
        let rawResourceArray = [ImageRepositoryTests.imageResourceRawObject]
        resourceModelController?.cleanImageRepository(using: rawResourceArray, with: testErrorHandler!, completion: { [weak self] (errors) in
            if let errors = errors, errors.count > 0 {
                XCTFail("Received unexpected errors")
            }
            
            guard let repository = self?.resourceModelController!.imageRepository, repository.keys.count == 1, let first = self?.resourceModelController!.imageRepository.first else {
                XCTFail("Expected resource not found")
                return
            }
            
            XCTAssertEqual(first.key, ImageRepositoryTests.imageResourceRawObject["objectId"] as! String)
            
            waitExpectation.fulfill()
        })
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testAppendImagesAppendsExpectedResources() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        let unexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "notathing", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string:"http://apple.com")!)
        let otherUnexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "anotherthing", thumbnailURL: URL(string: "http://verizon.com")!, fileURL: URL(string:"http://verizon.com")!)
        resourceModelController?.imageRepository = ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        
        let rawResourceArray = [ImageRepositoryTests.imageResourceRawObject]
        
        resourceModelController?.appendImages(from: rawResourceArray, completion: { [weak self] (errors) in
            if let errors = errors, errors.count > 0 {
                XCTFail("Received unexpected errors")
            }
            
            guard let repository = self?.resourceModelController!.imageRepository, repository.keys.count == 3 else {
                XCTFail("Expected resource not found")
                return
            }
            
            let expected = ImageRepositoryTests.imageResourceRawObject["objectId"] as! String
            let actual = repository.keys.contains(expected)
            XCTAssertTrue(actual)
            
            waitExpectation.fulfill()
        })
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testAppendImagesCompletesWithAccumulatedErrors() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        let unexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "notathing", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string:"http://apple.com")!)
        let otherUnexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "anotherthing", thumbnailURL: URL(string: "http://verizon.com")!, fileURL: URL(string:"http://verizon.com")!)
        resourceModelController?.imageRepository = ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        
        let rawResourceArray = RawResourceArray()
        
        resourceModelController?.appendImages(from: rawResourceArray, completion: { (errors) in
            guard let errors = errors, errors.count == 1 else {
                XCTFail("Errors was not expected value")
                return
            }
            
            for error in errors {
                switch error {
                case ModelError.NoNewValues:
                    waitExpectation.fulfill()
                default:
                    XCTFail("Found unexpected error: \(error.localizedDescription)")
                }
            }
        })
        
        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
    
    func testExtractValueExtractsExpectedString() {
        let expectedString = "actual"
        let blob = ["expected":expectedString as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let actual:String = try resourceModelController!.extractValue(named: "expected", from: blob)
            XCTAssertEqual(expectedString, actual)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExtractValueExtractsExpectedURL() {
        let expectedURLString = "http://apple.com"
        let blob = ["expected": expectedURLString as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let actual:URL = try resourceModelController!.extractValue(named: "expected", from: blob)
            XCTAssertEqual(actual.absoluteString, expectedURLString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExtractValueExtractsExpectedDate() {
        let expectedDate = Date()
        let blob = ["expected": expectedDate as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let actual:Date = try resourceModelController!.extractValue(named: "expected", from: blob)
            XCTAssertEqual(actual, expectedDate)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testExtractValueThrowsExpectedMissingObjectIDError() {
        let waitExpectation = expectation(description: "Wait for completion")

        let key = "unexpected"
        let blob = ["unexpected":key as AnyObject]
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let string:String? = try resourceModelController!.extractValue(named: RemoteStoreTableMap.CommonColumn.objectId.rawValue, from: blob)
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
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let string:String? = try resourceModelController!.extractValue(named: "expected", from: blob)
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
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let date:Date = try resourceModelController!.extractValue(named: key, from: blob)
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
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let actual:URL = try resourceModelController!.constructURL(from: expectedURLString as AnyObject)
            XCTAssertEqual(expectedURLString, actual.absoluteString)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConstructURLThrowsExpectedInvalidURLError() {
        let waitExpectation = expectation(description: "Wait for completion")

        let expectedURLString = ""
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let _:URL = try resourceModelController!.constructURL(from: expectedURLString as AnyObject)
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
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        do {
            let _:URL = try resourceModelController!.constructURL(from: unexpectedDate)
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
