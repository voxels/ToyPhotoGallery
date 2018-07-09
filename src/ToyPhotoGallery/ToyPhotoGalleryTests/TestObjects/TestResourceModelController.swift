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
    
    override func build<T>(using storeController: RemoteStoreController, for resourceType: T.Type, with errorHandler: ErrorHandlerDelegate, timeoutDuration: TimeInterval) where T : Resource {
        didBuildRepository = true
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didUpdateModel()
        }
    }
}
