//
//  ImageResourceModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

typealias ResourceCompletion = ([URL])->Void

protocol ResourceModelControllerDelegate {
    func didUpdateModel()
}

/// A struct used to hold the image resource URLs
struct ImageResource {
    var thumbnailURL:URL
    var fullsizeURL:URL
}

/// A struct used to handle resources from the Parse interface
struct ResourceModelController {
    let remoteStoreController:RemoteStoreController
    let errorHandler:ErrorHandlerDelegate
    var delegate:ResourceModelControllerDelegate?
    
    var thumbnailRepository:[ImageResource]?
    
    init(with storeController:RemoteStoreController, errorHandler:ErrorHandlerDelegate) {
        self.remoteStoreController = storeController
        self.errorHandler = errorHandler
    }
    
    func resource(sortBy:String?, skip:Int, limit:Int, from service:RemoteStoreController, completion:@escaping ResourceCompletion) {
        find(from: service, in: .Resource, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler) { foundObjects in
            
        }
    }
    
    func buildRepository(from remoteStoreController:RemoteStoreController) {
//        fetch(from:remoteStoreController, column:.thumbnailURLString,sortBy: RemoteStoreTable.CommonColumn.createdAt.rawValue, skip: 0, limit:resourceModel.remoteStoreController.defaultQuerySize) { [weak self] (resources) in
//            self?.dataSource = resources
//            self?.delegate?.didUpdateModel()
//        }
    }
}

// MARK: - Initialize

extension ResourceModelController {
    func fetch(from controller:RemoteStoreController, columns:[RemoteStoreTable], sortBy:String?, skip:Int, limit:Int, completion:@escaping ResourceCompletion) {
//        resourceModel.find(from: controller, in: .Resource, sortBy: sortBy, skip: skip, limit: limit, errorHandler: resourceModel.errorHandler) { [weak self] (dictionaries) in
//            do {
//                guard let resources = try self?.extractResourceURLs(from: column, in: dictionaries) else {
//                    self?.resourceModel.errorHandler.report(ModelError.Deallocated)
//                    return
//                }
//                completion(resources)
//            } catch {
//                self?.resourceModel.errorHandler.report(error)
//                completion([URL]())
//            }
//        }
    }
}

extension ResourceModelController {
    /// TODO: Turn into template
    func extractResourceURLs(from columns:[RemoteStoreTable.ResourceColumn], in dictionaries:[[String:AnyObject]]) throws -> [URL] {
        var resources = [URL]()
        
//        try dictionaries.forEach({ (dictionary) in
//            guard let urlString = dictionary[column.rawValue] as? String else {
//                throw ModelError.IncorrectType
//            }
//
//            guard let resourceLocator = URL(string: urlString) else {
//                throw ModelError.InvalidURL
//            }
//
//            resources.append(resourceLocator)
//        })
        
        return resources
    }
}

extension ResourceModelController {
    func find(from service:RemoteStoreController, in table:RemoteStoreTable, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate, completion:@escaping FindCompletion) {
        
        service.find(table: table, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler, completion:completion)
    }
}
