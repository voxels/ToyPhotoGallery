//
//  ImageResource.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias ImageResourceCompletion = ([ImageResource])->Void

class ImageResource : ImageSchema  {
    var createdAt: Date
    var updatedAt: Date
    var filename: String
    var thumbnailURL: URL
    var fileURL: URL
    
    init(createdAt:Date, updatedAt:Date, filename:String, thumbnailURL:URL, fileURL:URL) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.filename = filename
        self.thumbnailURL = thumbnailURL
        self.fileURL = fileURL
    }
    
    static func extractImageResources(with resourceModelController:ResourceModelController, from rawResourceArray:RawResourceArray, completion:ImageRepositoryCompletion) -> Void {
        
        var accumulatedErrors = [Error]()
        let newEntries = ImageRepository()
        
        var foundImageResource = false
        
        rawResourceArray.forEach { (dictionary) in
            do {
                let objectId:String = try resourceModelController.extractValue(named: RemoteStoreTableMap.CommonColumn.objectId.rawValue, from: dictionary)
                
                foundImageResource = true
                let imageResource = try ImageResource.imageResource(with: resourceModelController, from: dictionary)
                newEntries.map[objectId] = imageResource
                
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
        let filename:String = try resourceModelController.extractValue(named: RemoteStoreTableMap.ImageResourceColumn.filename.rawValue, from: dictionary)
        let thumbnailURL:URL = try resourceModelController.extractValue(named: RemoteStoreTableMap.ImageResourceColumn.thumbnailURLString.rawValue, from: dictionary)
        let fileURL:URL = try resourceModelController.extractValue(named: RemoteStoreTableMap.ImageResourceColumn.fileURLString.rawValue, from: dictionary)
        
        return ImageResource(createdAt: createdAt, updatedAt: updatedAt, filename: filename, thumbnailURL: thumbnailURL, fileURL: fileURL)
    }
}
