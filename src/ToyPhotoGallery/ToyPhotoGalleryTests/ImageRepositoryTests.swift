//
//  ImageRepositoryTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class ImageRepositoryTests: XCTestCase {
    
    var testErrorHandler:TestErrorHandler?
    var testRemoteStoreController:TestRemoteStoreController?
    var resourceModelController:ResourceModelController?
    
    override func setUp() {
        testErrorHandler = TestErrorHandler()
        testRemoteStoreController = TestRemoteStoreController()
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, errorHandler: testErrorHandler!)
    }
    
    static let imageResourceRawObject:[String:AnyObject] =
        ["objectId":"xxxxxxxx" as AnyObject,
         "createdAt": Date() as AnyObject,
         "updatedAt":Date() as AnyObject,
         "filename": "name" as AnyObject,
         "thumbnailURLString":"https://s3.amazonaws.com/com-federalforge-repository/public/resources/thumbnails/ToyPhotoGallery_98.jpg" as AnyObject,
         "fileURLString": "https://s3.amazonaws.com/com-federalforge-repository/public/resources/converted/ToyPhotoGallery_98.jpg" as AnyObject ]

    func testExtractImageResourcesExtractsExpectedEntries() {
        let waitExpectation = expectation(description: "Wait for completion")
        
        let rawResourceArray = [ImageRepositoryTests.imageResourceRawObject]
        ImageResource.extractImageResources(with: resourceModelController!, from: rawResourceArray) { (repository, errors) in
            if let errors = errors, errors.count > 0 {
                XCTFail("Found unexpected errors")
                return
            }
            
            guard let first = repository.map.first else {
                XCTFail("Did not find expected resource")
                return
            }
            
            XCTAssertEqual(first.key, ImageRepositoryTests.imageResourceRawObject["objectId"] as! String)
            
            waitExpectation.fulfill()
        }
        
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testExtractImageResourcesAccumulatesExpectedErrors() {
        let waitExpectation = expectation(description: "Wait for completion")
        ImageResource.extractImageResources(with: resourceModelController!, from: RawResourceArray()) { (repository, errors) in
            guard let errors = errors else {
                XCTFail("No errors found")
                return
            }
            
            XCTAssertTrue(errors.contains(where: { (error) -> Bool in
                switch error {
                case ModelError.NoNewValues:
                    return true
                default:
                    return false
                }
            }))
            
            waitExpectation.fulfill()
        }
        
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testImageResourceConstructsExpectedResource() {
        do {
            let actual = try ImageResource.imageResource(with: resourceModelController!, from: ImageRepositoryTests.imageResourceRawObject)
            XCTAssertNotNil(actual)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
