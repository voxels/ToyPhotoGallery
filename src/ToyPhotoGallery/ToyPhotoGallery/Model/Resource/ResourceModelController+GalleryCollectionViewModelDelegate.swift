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
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter timeoutDuration:  the *TimeInterval* to wait before timing out the request
     - parameter completion: a callback used to pass back the filled resources
     - Returns: void
     */
    func imageResources(skip: Int, limit: Int, timeoutDuration:TimeInterval = ResourceModelController.defaultTimeout, completion:ImageResourceCompletion?) -> Void {
        // We need to make sure we don't skip fetching any images for this purpose
        let checkCount = imageRepository.map.values.count
        let finalSkip = skip > checkCount ? checkCount : skip
        
        // We also need to make sure we still get the requested number of images
        let finalLimit = abs(finalSkip - skip) + limit
        
        let wrappedCompletion:([Resource])->Void = {[weak self] (sortedResources) in
            guard let imageResources = sortedResources as? [ImageResource] else {
                self?.errorHandler.report(ModelError.IncorrectType)
                completion?([ImageResource]())
                return
            }
            
            completion?(imageResources)
        }
        
        do {
            try fillAndSort(repository: imageRepository, skip: finalSkip, limit: finalLimit, timeoutDuration:timeoutDuration, completion: wrappedCompletion)
        } catch {
            errorHandler.report(error)
            completion?([ImageResource]())
        }
    }
}
