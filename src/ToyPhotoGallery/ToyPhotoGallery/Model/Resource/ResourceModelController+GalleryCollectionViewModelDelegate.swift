//
//  ResourceModelController+GalleryCollectionViewModelDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension ResourceModelController : GalleryCollectionViewModelDelegate {
    /**
     Fetches the image resources from the local repository contained in the *ResourceModelController*
     - parameter skip: the number of items to skip when finding new resources
     - parameter limit: the number of items we want to fetch
     - parameter completion: a callback used to pass back the filled resources
     - Returns: void
     */
    func imageResources(skip: Int, limit: Int, completion:ImageResourceCompletion?) -> Void {
        // We need to make sure we don't skip fetching any images for this purpose
        let checkCount = imageRepository.map.values.count
        let finalSkip = skip > checkCount ? checkCount : skip
        
        // We also need to make sure we still get the requested number of images
        let finalLimit = abs(finalSkip - skip) + limit
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let wrappedCompletion:([Resource])->Void = {[weak self] (sortedResources) in
                guard let imageResources = sortedResources as? [ImageResource] else {
                    DispatchQueue.main.async {
                        self?.errorHandler.report(ModelError.IncorrectType)
                        completion?([ImageResource]())
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion?(imageResources)
                }
            }
            
            do {
                try strongSelf.fillAndSort(repository: strongSelf.imageRepository, skip: finalSkip, limit: finalLimit, completion: wrappedCompletion)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorHandler.report(error)
                    completion?([ImageResource]())
                }
            }
        }
    }
}
