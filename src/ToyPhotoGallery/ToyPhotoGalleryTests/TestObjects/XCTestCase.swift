//
//  Convenience.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {
    static let defaultWaitDuration:TimeInterval = 2
    
    func register(expectations:[XCTestExpectation], duration timeout:TimeInterval)->Bool {
        let result = XCTWaiter().wait(for: expectations, timeout: timeout)
        return  result == .completed
    }
}


