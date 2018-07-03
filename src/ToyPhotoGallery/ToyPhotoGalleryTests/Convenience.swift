//
//  Convenience.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest

protocol Convenience {
    
}

extension Convenience {

}

extension XCTestCase {
    func wait(timeout:TimeInterval) {
        waitForExpectations(timeout: 0.2) { (error) in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }
}


