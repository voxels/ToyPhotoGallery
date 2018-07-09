//
//  GalleryViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Protocol to notifcy the GalleryViewController that the model has updated
protocol GalleryViewModelDelegate : class {
    func didUpdateViewModel(insertItems:[IndexPath]?, deleteItems:[IndexPath]?, moveItems:[(IndexPath,IndexPath)]?)
}

/// Model class that holds the model controller for the Gallery view subviews
class GalleryViewModel {
    
    /// Resource model controller designed to be the interface to assets stored remotely
    /// or in a cache
    let resourceModelController:ResourceModelController
    
    init(with resourceModel:ResourceModelController) {
        self.resourceModelController = resourceModel
    }
}
