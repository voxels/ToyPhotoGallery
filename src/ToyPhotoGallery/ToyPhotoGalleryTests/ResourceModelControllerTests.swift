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
    
    func testCleanRepositoryCleansImageRepository() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
        let unexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "notathing", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string:"http://apple.com")!)
        let otherUnexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "anotherthing", thumbnailURL: URL(string: "http://verizon.com")!, fileURL: URL(string:"http://verizon.com")!)
        let imageRepository = ImageRepository()
        imageRepository.map = ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        resourceModelController?.imageRepository = imageRepository
        
        let rawResourceArray = [ImageRepositoryTests.imageResourceRawObject]
        resourceModelController?.clean(using: rawResourceArray, for: ImageResource.self, with: testErrorHandler!, completion: {[weak self] (errors) in
            if let errors = errors, errors.count > 0 {
                XCTFail("Received unexpected errors")
            }
            
            guard let repository = self?.resourceModelController!.imageRepository, repository.map.keys.count == 1, let first = self?.resourceModelController!.imageRepository.map.first else {
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
        let imageRepository = ImageRepository()
        imageRepository.map = ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        resourceModelController?.imageRepository = imageRepository
        
        let rawResourceArray = [ImageRepositoryTests.imageResourceRawObject]
        
        resourceModelController?.append(from: rawResourceArray, into: ImageResource.self, completion: { [weak self] (errors) in
            if let errors = errors, errors.count > 0 {
                XCTFail("Received unexpected errors")
            }
            
            guard let repository = self?.resourceModelController!.imageRepository, repository.map.keys.count == 3 else {
                XCTFail("Expected resource not found")
                return
            }
            
            let expected = ImageRepositoryTests.imageResourceRawObject["objectId"] as! String
            let actual = repository.map.keys.contains(expected)
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
        let imageRepository = ImageRepository()
        imageRepository.map =  ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        resourceModelController?.imageRepository = imageRepository
        
        let rawResourceArray = RawResourceArray()
        
        resourceModelController?.append(from: rawResourceArray, into: ImageResource.self, completion: { (errors) in
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
}
