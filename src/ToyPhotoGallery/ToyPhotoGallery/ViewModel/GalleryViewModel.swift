//
//  GalleryViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryViewModelDelegate : ViewModelDelegate {
    
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
    
    func imageResource(for index:Int)->ImageResource {
        return ImageResource(createdAt: Date(), updatedAt: Date(), filename: "", thumbnailURL: URL(string: "http://apple.com")!, fileURL: URL(string: "http://apple.com")!)
    }
}
