//
//  GalleryViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryViewModelDelegate {
    
}

class GalleryViewModel {
    let resourceModelController:ResourceModelController
    let logHandler = DebugLogHandler()

    var dataSource:[URL]?
    var delegate:GalleryViewModelDelegate?
    
    init(with resourceModel:ResourceModelController) {
        self.resourceModelController = resourceModel
    }
    
    func buildDataSource(from controller:ResourceModelController)->[URL] {
        
        return [URL]()
    }
}
