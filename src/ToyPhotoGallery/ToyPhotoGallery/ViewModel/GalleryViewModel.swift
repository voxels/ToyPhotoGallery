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
        fetch(from:controller, column:.thumbnailURLString,sortBy: RemoteStoreTable.CommonColumn.createdAt.rawValue, skip: 0, limit:resourceModel.remoteStoreController.defaultQuerySize) { [weak self] (resources) in
            self?.dataSource = resources
            self?.delegate?.didUpdateModel()
        }
    }
}

// MARK: - Initialize

extension GalleryViewModel {
    func fetch(from controller:RemoteStoreController, column:RemoteStoreTable.ResourceColumn, sortBy:String?, skip:Int, limit:Int, completion:@escaping ResourceCompletion) {
        resourceModel.find(from: controller, in: .Resource, sortBy: sortBy, skip: skip, limit: limit, errorHandler: resourceModel.errorHandler) { [weak self] (dictionaries) in
            do {
                guard let resources = try self?.extractResourceURLs(from: column, in: dictionaries) else {
                    self?.resourceModel.errorHandler.report(ModelError.Deallocated)
                    return
                }
                completion(resources)
            } catch {
                self?.resourceModel.errorHandler.report(error)
                completion([URL]())
            }
        }
    }
}

extension GalleryViewModel {
    func extractResourceURLs(from column:RemoteStoreTable.ResourceColumn, in dictionaries:[[String:AnyObject]]) throws -> [URL] {
        var resources = [URL]()
        
        try dictionaries.forEach({ (dictionary) in
            guard let urlString = dictionary[column.rawValue] as? String else {
                throw ModelError.IncorrectType
            }
            
            guard let resourceLocator = URL(string: urlString) else {
                throw ModelError.InvalidURL
            }
            
            resources.append(resourceLocator)
        })
        
        return resources
    }
}
