//
//  ImageRepository.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias ImageRepositoryCompletion = (ImageRepository,[Error]?)->Void

class ImageRepository : Repository {
    typealias AssociatedType = ImageResource
    var map: [String : ImageResource] = [:]
}
