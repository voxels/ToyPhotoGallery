//
//  GalleryViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryViewModelDelegate {
    func didUpdateModel()
}

class GalleryViewModel {
    let resourceModel:ResourceModelController
    let logHandler = DebugLogHandler()
    var delegate:GalleryViewModelDelegate?
    
    var dataSource:[URL]?
    
    init(with resourceModel:ResourceModelController, delegate:GalleryViewModelDelegate) {
        self.resourceModel = resourceModel
        self.delegate = delegate
    }
    
    func buildDataSource(from controller:RemoteStoreController) {
        thumbnails(from:controller, sortBy: RemoteStoreTable.CommonColumn.createdAt.rawValue, skip: 0, limit:resourceModel.remoteStoreController.defaultQuerySize) { [weak self] (foundResources) in
            self?.dataSource = foundResources
            self?.delegate?.didUpdateModel()
        }
    }
}

// MARK: - Initialize

extension GalleryViewModel {
    func thumbnails(from controller:RemoteStoreController, sortBy:String?, skip:Int, limit:Int, completion:ResourceCompletion) {
        resourceModel.find(from: controller, in: .Resource, sortBy: sortBy, skip: skip, limit: limit, errorHandler: resourceModel.errorHandler) { [weak self] (foundObjects) in
            for object in foundObjects {
                self?.logHandler.console(String(describing:type(of: object)))
            }
        }
    }
}
