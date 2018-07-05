//
//  TestResourceModelController.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
@testable import ToyPhotoGallery

class TestResourceModelController : ResourceModelController {
    var didBuildRepository = false
    
    override func build<T>(using storeController: RemoteStoreController, for repositoryType: T.Type, with errorHandler: ErrorHandlerDelegate, completion: @escaping ErrorCompletion) where T : Resource {
        didBuildRepository = true
        completion(nil)
    }
}
