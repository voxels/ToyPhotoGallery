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
    
    func tableMap<T>(for repository:T) throws -> RemoteStoreTableMap where T:Repository, T.AssociatedType:Resource {
        return try tableMap(with: T.AssociatedType.self)
    }
    
    func tableMap<T>(with type:T.Type) throws -> RemoteStoreTableMap where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            return RemoteStoreTableMap.ImageResource
        default:
            throw ModelError.UnsupportedRequest
        }
    }
    
    func build<T>(using storeController:RemoteStoreController, for repositoryType:T.Type, with errorHandler:ErrorHandlerDelegate, completion:@escaping ErrorCompletion) where T:Resource {
        do {
            let table = try tableMap(with: repositoryType)
            
            find(from: storeController, in: table, sortBy: RemoteStoreTableMap.CommonColumn.createdAt.rawValue, skip: 0, limit: storeController.defaultQuerySize, errorHandler: errorHandler) { [weak self](rawResourceArray) in
                guard let strongSelf = self else {
                    completion([ModelError.Deallocated])
                    return
                }
                strongSelf.clean(using: rawResourceArray, for: repositoryType, with: errorHandler, completion: completion)
            }
        } catch {
            completion([error])
        }
    }
    
    func clean<T>(using rawResourceArray:RawResourceArray, for repositoryType:T.Type, with errorHandler:ErrorHandlerDelegate, completion:ErrorCompletion) where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            imageRepository = ImageRepository()
        default:
            completion([ModelError.UnsupportedRequest])
        }
        
        append(from: rawResourceArray, into: T.self, completion: completion)
    }
    
    func append<T>(from rawResourceArray:RawResourceArray, into repositoryType:T.Type, completion:ErrorCompletion ) where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            ImageResource.extractImageResources(with: self, from: rawResourceArray, completion: { [weak self] (newRepository, accumulatedErrors) in
                newRepository.map.forEach({ (object) in
                    self?.imageRepository.map[object.key] = object.value
                })
                completion(accumulatedErrors)
            })
        default:
            completion([ModelError.UnsupportedRequest])
        }
    }
    
    func fill<T>(repository:T, sortBy:String?, skip:Int, limit:Int, completion:(T)->Void) throws where T:Repository, T.AssociatedType:Resource {
        let count = repository.map.count
        
        let table = try tableMap(for: repository)
        
        if count < skip {
            // If we have less that the skip, fill from the count to the limit
            find(from: remoteStoreController, in: table, sortBy:sortBy, skip: skip, limit: limit, errorHandler: errorHandler) { (rawResourceArray) in
                
            }
        } else if count >= skip && count < limit {
            // If we have more than the skip, but less than the limit, fill from the skip to the limit
            // We are not entertaining empty list values at the moment
            
        } else {
            // We have the number of things we need
            completion(repository)
        }
    }
}

// MARK: - Sort

extension ResourceModelController {
    func sorted<T>(repository:T, sortBy:String?, skip:Int, limit:Int, completion:([T.AssociatedType])->Void) throws where T:Repository, T.AssociatedType:Resource {
        try fill(repository:repository, sortBy:sortBy, skip: skip, limit: limit) { (filledRepository) in
            sort(repository: filledRepository, by: sortBy, completion: completion)
        }
    }
    
    func sort<T>(repository:T, by:String?, completion:([T.AssociatedType])->Void) where T:Repository, T.AssociatedType:Resource {
        
    }
}

// MARK: - RemoteStoreController

extension ResourceModelController {
    func find(from remoteStoreController:RemoteStoreController, in table:RemoteStoreTableMap, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate, completion:@escaping RawResourceArrayCompletion) {
        
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
