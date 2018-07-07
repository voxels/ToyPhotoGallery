//
//  GalleryCollectionViewImageCellModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Model class used to hold an image cell's resouce and network session interface
class GalleryCollectionViewImageCellModel : GalleryCollectionViewCellModel {
    
    /// The cell identifier registered with the collection view
    static var identifier: String = "GalleryCollectionViewImageCell"
    
    /// The image resource model for the cell
    var imageResource:ImageResource
    
    /// The interface used to fetch the image resource's data
    var interface:NetworkSessionInterface

    required init(with resource: Resource, networkSessionInterface:NetworkSessionInterface? = nil) throws {
        guard let imageResource = resource as? ImageResource, let interface = networkSessionInterface else {
            throw ModelError.IncorrectType
        }
        
        self.imageResource = imageResource
        self.interface = interface
    }
}
