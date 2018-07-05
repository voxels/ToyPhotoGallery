//
//  GalleryViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryViewModelDelegate {
    func didUpdateViewModel()
}

class GalleryViewModel {
    let resourceModelController:ResourceModelController
    let logHandler = DebugLogHandler()

    init(with resourceModel:ResourceModelController) {
        self.resourceModelController = resourceModel
    }
}
