//
//  GalleryCollectionViewImageCellModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Model class used to hold an image cell's resouce and network session interface
class GalleryCollectionViewImageCellModel : NSObject, GalleryCollectionViewCellModel {
    
    /// The cell identifier registered with the collection view
    static var identifier: String = "GalleryCollectionViewImageCell"
    
    /// The identifier we use to sort the data model with
    var updatedAt: Date
    
    /// The image resource model for the cell
    var imageResource:ImageResource
    
    required init(with resource: Resource) throws {
        guard let imageResource = resource as? ImageResource else {
            throw ModelError.IncorrectType
        }
        
        self.imageResource = imageResource
        self.updatedAt = imageResource.updatedAt
    }
}
