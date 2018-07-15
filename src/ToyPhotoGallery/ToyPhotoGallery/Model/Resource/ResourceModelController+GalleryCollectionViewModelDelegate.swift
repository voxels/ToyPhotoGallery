//
//  ResourceModelController+GalleryCollectionViewModelDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension ResourceModelController : GalleryCollectionViewModelDelegate {
    
    var timeoutDuration: TimeInterval {
        return ResourceModelController.defaultTimeout
    }
    
    /**
     Fetches the image resources from the local repository contained in the *ResourceModelController*
     - parameter currentCount: the current number of image resource items in the collection view model
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
     - parameter completion: a callback used to pass back the filled resources
     - Returns: void
     */
    func imageResources(currentCount:Int, skip: Int, limit: Int, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout, completion:ImageResourceCompletion?) -> Void {
        if currentCount == totalImageRecords {
            DispatchQueue.main.async {
                completion?([ImageResource]())
            }
        }
        
        // We need to make sure we don't skip fetching any images for this purpose
        let readQueue = DispatchQueue(label: readQueueLabel)
        var checkCount = 0
        readQueue.sync { checkCount = imageRepository.map.values.count }
        let finalSkip = skip > checkCount ? checkCount : skip
        
        // We also need to make sure we still get the requested number of images
        let finalLimit = abs(finalSkip - skip) + limit
        
        // FillAndSort returns on the main queue but we are doing this for safety
        let wrappedCompletion:([Resource])->Void = {[weak self] (sortedResources) in
            guard let imageResources = sortedResources as? [ImageResource] else {
                self?.errorHandler.report(ModelError.IncorrectType)
                DispatchQueue.main.async {
                    completion?([ImageResource]())
                }
                return
            }
            
            DispatchQueue.main.async {
                completion?(imageResources)
            }
        }
        
        var copyImageRepository = ImageRepository()
        readQueue.sync {
            copyImageRepository = imageRepository
        }
        
        let fetchQueue = DispatchQueue(label: "\(readQueueLabel).fetch")
        fetchQueue.async { [weak self] in
            do {
                try self?.fillAndSort(repository: copyImageRepository, skip: finalSkip, limit: finalLimit, timeoutDuration:timeoutDuration, on:fetchQueue, completion: wrappedCompletion)
            } catch {
                self?.errorHandler.report(error)
                DispatchQueue.main.async {
                    completion?([ImageResource]())
                }
            }
        }
    }
}
