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
    var networkSessionInterface:NetworkSessionInterface?
    
    override func setUp() {
        testErrorHandler = TestErrorHandler()
        testRemoteStoreController = TestRemoteStoreController()
        networkSessionInterface = NetworkSessionInterface(with: testErrorHandler!)
    }
    
    
    func testAppendImagesCompletesWithAccumulatedErrors() {
        let waitExpectation = expectation(description: "Wait for completion")
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface:networkSessionInterface!, errorHandler: testErrorHandler!)
        let unexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "notathing", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string:"http://apple.com")!, width:100, height:100)
        let otherUnexpectedImageResource = ImageResource(createdAt: Date(), updatedAt: Date(), filename: "anotherthing", thumbnailURL: URL(string: "http://verizon.com")!, fileURL: URL(string:"http://verizon.com")!, width:100, height:100)
        let imageRepository = ImageRepository()
        imageRepository.map =  ["xxxxxx":unexpectedImageResource, "asdfbasd":otherUnexpectedImageResource]
        resourceModelController?.imageRepository = imageRepository
        
        let rawResourceArray = RawResourceArray()
        resourceModelController?.append(from: rawResourceArray, into: imageRepository, completion: { (repository, errors) in
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
