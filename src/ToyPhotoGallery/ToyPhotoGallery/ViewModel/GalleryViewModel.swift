//
//  GalleryViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

class GalleryViewModel {
    let resourceModel:ResourceModelController
    let logHandler = DebugLogHandler()
    
    var dataSource:[URL]?
    
    init(with resourceModel:ResourceModelController) {
        self.resourceModel = resourceModel
    }
    
    func buildDataSource(from controller:RemoteStoreController) {
        
    }
}
