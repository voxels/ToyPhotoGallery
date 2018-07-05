//
//  ResourceModelController+GalleryCollectionViewModelDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension ResourceModelController : GalleryCollectionViewModelDelegate {
    func imageResources(sortBy: String?, skip: Int, limit: Int, completion:ImageResourceCompletion?) -> Void {
//        let wrappedCompletion:ResourceCompletion = {[weak self] (sortedResources) in
//            guard let imageResources = sortedResources as? [ImageResource] else {
//                self?.errorHandler.report(ModelError.IncorrectType)
//                completion?([ImageResource]())
//                return
//            }
//            completion?(imageResources)
//        }
//
//        do {
//            let values:[ImageResource] = Array(imageRepository.map.values)
//            try sorted(resources: values, sortBy: sortBy, skip: skip, limit: limit, completion: wrappedCompletion)
//        } catch {
//            errorHandler.report(error)
//            completion?([ImageResource]())
//        }
    }
}
