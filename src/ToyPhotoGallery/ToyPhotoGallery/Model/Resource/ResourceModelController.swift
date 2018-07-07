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

/// The delegate protocol used to notify that the model has updated or failed to update
protocol ResourceModelControllerDelegate : class {
    func didUpdateModel()
    func didFailToUpdateModel(with reason:String?)
}

/// A struct used to handle resources from a *RemoteStoreController* interface
class ResourceModelController {
    /// A controller used to fetch objects from a remote store
    let remoteStoreController:RemoteStoreController
    
    /// The error handler used to report non-fatal errors
    let errorHandler:ErrorHandlerDelegate
    
    /// The delegate that gets informed of model updates
    weak var delegate:ResourceModelControllerDelegate?
    
    /// A cache of previously fetched *ImageResource*
    var imageRepository = ImageRepository()
    
    init(with storeController:RemoteStoreController, errorHandler:ErrorHandlerDelegate) {
        self.remoteStoreController = storeController
        self.errorHandler = errorHandler
    }
    
    /**
     Builds the initial repository asset list
     - parameter storeController: the *RemoteStoreController* used to fetch the resources
     - parameter resourceType: the type of the resource being fetched
     - parameter errorHandler: the *ErrorHandlerDelegate* used to report non-fatal errors
     - Returns: void
     */
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
    
    /**
     Checks the existing number of resources in the repository and fills in entries for indexes between the skip and limit, if necessary
     - parameter repository: the *Repository* that needs to be filled
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter completion: a callback used to pass back the filled repository
     - Throws: Throws any error surfaced from *tableMap*
     - Returns: void
     */
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

/// NOTE: These methods do not notify the delegate that the model has updated.  These are
/// utility methods for *build*, *fill*, etc.  They are public for unit testing.
extension ResourceModelController {
    /**
     Asks the given *RemoteStoreController* to find the requested records
     - parameter table: the *RemoteStoreTableMap* schema entry to search within
     - parameter sortBy: An optional *String* to sort the query with
     - parameter skip: the number of records we want to skip in the query
     - parameter limit: the number of records we want to fetch
     - parameter errorHandler: an error handler used to report non-fatal errors
     - parameter completion: a *RawResourceArrayCompletion* that passes through the records fetched from the remote store
     - Returns: void
     */
    func find(from remoteStoreController:RemoteStoreController, in table:RemoteStoreTableMap, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate, completion:@escaping RawResourceArrayCompletion) {
        
        remoteStoreController.find(table: table, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler, completion:completion)
    }

    /**
     Cleans a repository using the given *RawResourceArray*
     - parameter rawResourceArray: an array of *[String:AnyObject]* representing the raw model objects fetched from a remote store controller
     - parameter resourceType: the type of resource for the repository
     - parameter errorHandler: a *ErrorHandlerDelegate* used to report non-fatal errors
     - parameter completion: a callback used to pass through the errors accumulated during the process
     */
    func clean<T>(using rawResourceArray:RawResourceArray, for resourceType:T.Type, with errorHandler:ErrorHandlerDelegate, completion:ErrorCompletion) where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            imageRepository = ImageRepository()
        default:
            completion([ModelError.UnsupportedRequest])
        }
        
        append(from: rawResourceArray, into: T.self, completion: completion)
    }
    
    /**
     Appends the raw resource array into the model's repository of the given type.  Implemented only for *ImageResource*, for now.
     - parameter rawResourceArray: an array of *[String:AnyObject]* representing the raw model objects fetched from a remote store controller
     - parameter resourceType: the type of resource for the repository
     - parameter completion: a callback used to pass through the errors accumulated during the process
     */
    func append<T>(from rawResourceArray:RawResourceArray, into resourceType:T.Type, completion:ErrorCompletion ) where T:Resource {
        switch T.self {
        case is ImageResource.Type:
            ImageResource.extractImageResources(from: rawResourceArray, completion: { [weak self] (newRepository, accumulatedErrors) in
                newRepository.map.forEach({ (object) in
                    self?.imageRepository.map[object.key] = object.value
                })
                completion(accumulatedErrors)
            })
        default:
            completion([ModelError.UnsupportedRequest])
        }
    }
    
    /**
     Returns the *RemoteStoreTableMap* for a given repository, if possible
     - parameter repository: the repository that needs to be mapped to the table
     - Throws: any error generated by *tableMap(with:)
     - Returns: the located *RemoteStoreTableMap*
     */
    func tableMap<T>(for repository:T) throws -> RemoteStoreTableMap where T:Repository, T.AssociatedType:Resource {
        return try tableMap(with: T.AssociatedType.self)
    }

    /**
     Returns the *RemoteStoreTableMap* for a given repository, if possible
     - parameter type: the type of repository that needs to be mapped to the table
     - Throws: any error generated by *tableMap(with:)
     - Returns: the located *RemoteStoreTableMap*
     */
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
    
    /**
     Fills the given repository with sorted records between the skip and limit indexes, and calls a callback with the resources that exist between the indexes
     - parameter repository: the *Repository* that needs to be filled
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter completion: a callback used to pass back the filled resources
     - Throws: Throws any error surfaced from *fill*
     - Returns: void
     */
    func fillAndSort<T>(repository:T, skip:Int, limit:Int, completion:@escaping ([T.AssociatedType])->Void) throws where T:Repository, T.AssociatedType:Resource {
        try fill(repository:repository, skip: skip, limit: limit) { [weak self] (filledRepository) in
            self?.sort(repository: filledRepository, skip:skip, limit:limit, completion: completion)
        }
    }

    /**
     Sorts the given repository with records between the skip and limit indexes, and calls a callback with the resources that exist between the indexes
     - parameter repository: the *Repository* that needs to be filled
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter completion: a callback used to pass back the filled resources
     - Returns: void
     */
    func sort<T>(repository:T, skip:Int, limit:Int, completion:([T.AssociatedType])->Void) where T:Repository, T.AssociatedType:Resource {
        let values = Array(repository.map.values).sorted { $0.updatedAt > $1.updatedAt }
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
