//
//  TestParseInterface.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import Parse
@testable import ToyPhotoGallery

class TestParseInterface : ParseInterface {
    var didFindQuery = false
    override func find(query: PFQuery<PFObject>, completion: @escaping ParseFindCompletion) {
        didFindQuery = true
        let pfObject:PFObject = PFObject(className: RemoteStoreTable.Resource.rawValue)
        completion([pfObject],nil)
    }
}

class TestErrorParseInterface : TestParseInterface {
    override func find(query: PFQuery<PFObject>, completion: @escaping ParseFindCompletion) {
        didFindQuery = true
        let pfObject:PFObject = PFObject(className: RemoteStoreTable.Resource.rawValue)
        let error = RemoteStoreError.InvalidSortByColumn
        completion([pfObject],error)
    }
}
