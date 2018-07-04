//
//  ImageRepository.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias ImageRepository = [String:ImageResource]
typealias ImageRepositoryCompletion = (ImageRepository,[Error]?)->Void

/// A struct used to hold the image resource URLs
struct ImageResource {
    var createdAt:Date
    var updatedAt:Date
    var filename:String
    var thumbnailURL:URL
    var fileURL:URL
}

extension ImageResource {
    static func extractImageResources(with resourceModelController:ResourceModelController, from rawResourceArray:RawResourceArray, completion:ImageRepositoryCompletion) -> Void {
        
        var accumulatedErrors = [Error]()
        var newEntries = ImageRepository()
        
        var foundImageResource = false
        
        rawResourceArray.forEach { (dictionary) in
            do {
                let objectId:String = try resourceModelController.extractValue(named: RemoteStoreTableMap.CommonColumn.objectId.rawValue, from: dictionary)
                
                foundImageResource = true
                let imageResource = try ImageResource.imageResource(with: resourceModelController, from: dictionary)
                newEntries[objectId] = imageResource
                
            } catch {
                accumulatedErrors.append(error)
            }
        }
        
        if !foundImageResource {
            accumulatedErrors.append(ModelError.NoNewValues)
        }
        
        completion(newEntries, accumulatedErrors)
    }
    
    static func imageResource(with resourceModelController:ResourceModelController, from dictionary:[String:AnyObject]) throws -> ImageResource {
        let createdAt:Date = try resourceModelController.extractValue(named: RemoteStoreTableMap.CommonColumn.createdAt.rawValue, from: dictionary)
        let updatedAt:Date = try resourceModelController.extractValue(named: RemoteStoreTableMap.CommonColumn.updatedAt.rawValue, from: dictionary)
        let filename:String = try resourceModelController.extractValue(named: RemoteStoreTableMap.ResourceColumn.filename.rawValue, from: dictionary)
        let thumbnailURL:URL = try resourceModelController.extractValue(named: RemoteStoreTableMap.ResourceColumn.thumbnailURLString.rawValue, from: dictionary)
        let fileURL:URL = try resourceModelController.extractValue(named: RemoteStoreTableMap.ResourceColumn.fileURLString.rawValue, from: dictionary)

        return ImageResource(createdAt: createdAt, updatedAt: updatedAt, filename: filename, thumbnailURL: thumbnailURL, fileURL: fileURL)
    }
}
