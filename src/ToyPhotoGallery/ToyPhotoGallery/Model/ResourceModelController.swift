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
typealias ImageRepository = [String:ImageResource]
typealias ImageRepositoryCompletion = (ImageRepository,[Error]?)->Void
typealias ResourceCompletion = ([URL])->Void

protocol ResourceModelControllerDelegate {
    func didUpdateModel()
    func didFailToUpdateModel(with reason:String?)
}

/// A struct used to hold the image resource URLs
struct ImageResource {
    var thumbnailURL:URL
    var fileURL:URL
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
        find(from: storeController, in: RemoteStoreTable.Resource, sortBy: RemoteStoreTable.CommonColumn.createdAt.rawValue, skip: 0, limit: storeController.defaultQuerySize, errorHandler: errorHandler) { [weak self] (rawResourceArray) in
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
        extractImageResources(from: rawResourceArray, completion: { [weak self] (newEntries, accumulatedErrors) in
            newEntries.forEach({ (object) in
                self?.imageRepository[object.key] = object.value
            })
            completion(accumulatedErrors)
        })
    }
}

// MARK: - Find

extension ResourceModelController {
    func find(from remoteStoreController:RemoteStoreController, in table:RemoteStoreTable, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate, completion:@escaping FindCompletion) {
        
        remoteStoreController.find(table: table, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler, completion:completion)
    }
}

// MARK: - Struct Extraction

extension ResourceModelController {
    func extractImageResources(from rawResourceArray:RawResourceArray, completion:ImageRepositoryCompletion) -> Void {
        
        var accumulatedErrors = [Error]()
        var newEntries = ImageRepository()
        var foundImageResource = false
        
        rawResourceArray.forEach { (dictionary) in
            var objectId = String()
            var thumbnailURL:URL?
            var fileURL:URL?
            
            do {
                objectId = try extractString(named: RemoteStoreTable.CommonColumn.objectId.rawValue, from: dictionary)
            } catch {
                accumulatedErrors.append(ModelError.EmptyObjectId)
                return
            }

            do {
                thumbnailURL = try extractURL(named: RemoteStoreTable.ResourceColumn.thumbnailURLString.rawValue, from: dictionary)
                fileURL = try extractURL(named: RemoteStoreTable.ResourceColumn.fileURLString.rawValue, from: dictionary)
            } catch {
                accumulatedErrors.append(error)
            }
            
            guard let extractedThumbnailURL = thumbnailURL, let extractedFileURL = fileURL else {
                return
            }
            
            foundImageResource = true
            
            let imageResource = ImageResource(thumbnailURL: extractedThumbnailURL, fileURL: extractedFileURL)
            newEntries[objectId] = imageResource
        }
        
        if !foundImageResource {
            accumulatedErrors.append(ModelError.EmptyImageResourceModel)
        }
        
        completion(newEntries, accumulatedErrors)
    }
}

// MARK: Generic Extraction Handlers

extension ResourceModelController {
    func extractString(named key:String, from dictionary:[String:AnyObject]) throws -> String {
        
        guard let value = dictionary[key] as? String else {
            throw ModelError.IncorrectType
        }
        
        return value
    }
    
    func extractURL(named key:String, from dictionary:[String:AnyObject]) throws -> URL {
        
        let urlString = try extractString(named: key, from: dictionary)
        guard let resourceLocator = URL(string: urlString) else {
            throw ModelError.InvalidURL
        }
        
        return resourceLocator
    }
}
