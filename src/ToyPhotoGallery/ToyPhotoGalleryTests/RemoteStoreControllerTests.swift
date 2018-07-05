//
//  RemoteStoreControllerTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class RemoteStoreControllerTests: XCTestCase {
    
    func testValidateThrowsExpectedError() {
        let interface = ParseInterface()
        do {
            try interface.validate(sortBy: "unexpected", in: .ImageResource)
        } catch {
            switch error {
            case RemoteStoreError.InvalidSortByColumn:
                return
            default:
                XCTFail("Unexpected error received: \(error.localizedDescription)")
            }
        }
        
        XCTFail("Validated unexpected sortBy column")
    }
}
