//
//  ImageResourceModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

typealias ErrorCompletion = ([Error]?)->Void
typealias RawResourceArray = [[String:AnyObject]]

protocol ResourceModelControllerDelegate {
    func didUpdateModel()
    func didFailToUpdateModel(with reason:String?)
}

/// A struct used to handle resources from the Parse interface
class ResourceModelController {
    let remoteStoreController:RemoteStoreController
    let errorHandler:ErrorHandlerDelegate
    var delegate:ResourceModelControllerDelegate?
    
    var imageRepository = ImageRepository()
    
    init(with storeController:RemoteStoreController, errorHandler:ErrorHandlerDelegate) {
        self.remoteStoreController = storeController
        self.errorHandler = errorHandler
    }
    
    func buildRepository(from storeController:RemoteStoreController, with errorHandler :ErrorHandlerDelegate, completion:@escaping ErrorCompletion) {
        find(from: storeController, in: RemoteStoreTableMap.Resource, sortBy: RemoteStoreTableMap.CommonColumn.createdAt.rawValue, skip: 0, limit: storeController.defaultQuerySize, errorHandler: errorHandler) { [weak self] (rawResourceArray) in
            guard let strongSelf = self else {
                completion([ModelError.Deallocated])
                return
            }
            
            strongSelf.cleanImageRepository(using:rawResourceArray, with:errorHandler, completion:completion)
        }
    }
    
    func cleanImageRepository(using rawResourceArray:RawResourceArray, with errorHandler:ErrorHandlerDelegate, completion:ErrorCompletion) {
        imageRepository = ImageRepository()
        appendImages(from: rawResourceArray, completion: completion)
    }
    
    func appendImages(from rawResourceArray:RawResourceArray, completion:ErrorCompletion ) {
        ImageResource.extractImageResources(with: self, from: rawResourceArray, completion: { [weak self] (newEntries, accumulatedErrors) in
            newEntries.forEach({ (object) in
                self?.imageRepository[object.key] = object.value
            })
            completion(accumulatedErrors)
        })
    }
}

// MARK: - Find

extension ResourceModelController {
    func find(from remoteStoreController:RemoteStoreController, in table:RemoteStoreTableMap, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate, completion:@escaping FindCompletion) {
        
        remoteStoreController.find(table: table, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler, completion:completion)
    }
}

// MARK: Generic Extraction Handlers

extension ResourceModelController {
    func extractValue<T>(named key:String, from dictionary:[String:AnyObject]) throws -> T {
        
        guard var value = dictionary[key] else {
            if key == RemoteStoreTableMap.CommonColumn.objectId.rawValue {
                throw ModelError.EmptyObjectId
            } else {
                throw ModelError.MissingValue
            }
        }
        
        // We need to convert the string to an URL type
        if T.self is URL.Type{
            value = try constructURL(from: value) as AnyObject
        }
        
        // We need to make sure we have the type of variable we expect to have
        guard let castValue = value as? T else {
            throw ModelError.IncorrectType
        }
        
        return castValue
    }
    
    func constructURL(from value:AnyObject) throws -> URL {
        if let urlString = value as? String {
            guard let resourceLocator = URL(string: urlString) else {
                throw ModelError.InvalidURL
            }
            return resourceLocator
        } else {
            throw ModelError.IncorrectType
        }
    }
}
