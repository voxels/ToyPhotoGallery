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

protocol ResourceModelControllerDelegate : class {
    func didUpdateModel()
    func didFailToUpdateModel(with reason:String?)
}

/// A struct used to handle resources from the Parse interface
class ResourceModelController {
    let remoteStoreController:RemoteStoreController
    let errorHandler:ErrorHandlerDelegate
    weak var delegate:ResourceModelControllerDelegate?
    
    var imageRepository = ImageRepository()
    
    init(with storeController:RemoteStoreController, errorHandler:ErrorHandlerDelegate) {
        self.remoteStoreController = storeController
        self.errorHandler = errorHandler
    }
    
    func build<T>(using storeController:RemoteStoreController, for resourceType:T.Type, with errorHandler:ErrorHandlerDelegate) where T:Resource {
            do {
                switch T.self {
                case is ImageResource.Type:
                    try fill(repository: imageRepository, skip: 0, limit: remoteStoreController.defaultQuerySize, completion:nil)
                default:
                    throw ModelError.UnsupportedRequest
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorHandler.report(error)
                    self?.delegate?.didFailToUpdateModel(with: error.localizedDescription)
                }
            }
    }
    
    func fill<T>(repository:T, skip:Int, limit:Int, completion:((T)->Void)?) throws where T:Repository, T.AssociatedType:Resource {
        let count = repository.map.count
        
        // We have what we need
        if count >= skip + limit {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateModel()
            }

            completion?(repository)
            return
        }
        
        let table = try tableMap(for: repository)
        
        find(from: remoteStoreController, in: table, sortBy:RemoteStoreTableMap.CommonColumn.createdAt.rawValue, skip: skip, limit: limit, errorHandler: errorHandler) {[weak self] (rawResourceArray) in
            self?.append(from: rawResourceArray, into: T.AssociatedType.self, completion: { (accumulatedErrors) in
                if ResourceModelController.modelUpdateFailed(with: accumulatedErrors) {
                    DispatchQueue.main.async {
                        self?.delegate?.didFailToUpdateModel(with: nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.delegate?.didUpdateModel()
                    }
                }
                
                completion?(repository)
            })
        }
    }
}

// MARK: - Utilities

/// NOTE: These methods do not notify the delegate
extension ResourceModelController {
    func find(from remoteStoreController:RemoteStoreController, in table:RemoteStoreTableMap, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate, completion:@escaping RawResourceArrayCompletion) {
        
        remoteStoreController.find(table: table, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler, completion:completion)
    }

    func clean<T>(using rawResourceArray:RawResourceArray, for resourceType:T.Type, with errorHandler:ErrorHandlerDelegate, completion:ErrorCompletion) where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            imageRepository = ImageRepository()
        default:
            completion([ModelError.UnsupportedRequest])
        }
        
        append(from: rawResourceArray, into: T.self, completion: completion)
    }
    
    func append<T>(from rawResourceArray:RawResourceArray, into resourceType:T.Type, completion:ErrorCompletion ) where T:Resource {
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
}

// MARK: - Sort

extension ResourceModelController {
    
    func fillAndSort<T>(repository:T, skip:Int, limit:Int, completion:@escaping ([T.AssociatedType])->Void) throws where T:Repository, T.AssociatedType:Resource {
        try fill(repository:repository, skip: skip, limit: limit) { [weak self] (filledRepository) in
            self?.sort(repository: filledRepository, skip:skip, limit:limit, completion: completion)
        }
    }
    
    func sort<T>(repository:T, skip:Int, limit:Int, completion:([T.AssociatedType])->Void) where T:Repository, T.AssociatedType:Resource {
        let values = Array(repository.map.values).sorted { $0.updatedAt < $1.updatedAt }
        let endSlice = skip + limit < values.count ? skip + limit : values.count
        let resources = Array(values[skip..<(endSlice)])
        completion(resources)
    }
}


// MARK: - Error Checking

extension ResourceModelController {
    /**
     Checks accumulated errors for types that signify that the model failed to update.  For example, if a record in the database fails to parse, then perhaps we should still allow the model update to pass even though the record itself is bad
     - parameter errors: An array of *Error* we need to check for serious errors
     - Returns: *true* if a serious error is found, *false* if *errors* is nil or if no serious errors are found
     */
    static func modelUpdateFailed(with errors:[Error]?) -> Bool {
        guard let errors = errors else {
            return false
        }
        
        var failedLaunch = false
        errors.forEach { (error) in
            switch error {
            case ModelError.InvalidURL:
                fallthrough
            case ModelError.IncorrectType:
                fallthrough
            case ModelError.MissingValue:
                fallthrough
            case ModelError.NoNewValues:
                return
            default:
                failedLaunch = true
            }
        }
        
        return failedLaunch
    }
}
