//
//  ResourceModelController+GalleryCollectionViewModelDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension ResourceModelController : GalleryCollectionViewModelDelegate {
    func imageResources(skip: Int, limit: Int, completion:ImageResourceCompletion?) -> Void {
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
                try strongSelf.sorted(repository: strongSelf.imageRepository, skip: skip, limit: limit, completion: wrappedCompletion)
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.errorHandler.report(error)
                    completion?([ImageResource]())
                }
            }
        }
    }
}
