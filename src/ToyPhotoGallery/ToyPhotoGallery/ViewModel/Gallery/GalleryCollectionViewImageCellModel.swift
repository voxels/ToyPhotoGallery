//
//  GalleryCollectionViewImageCellModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

class GalleryCollectionViewImageCellModel : GalleryCollectionViewCellModel {
    
    static var identifier: String = "GalleryCollectionViewImageCell"
    var imageResource:ImageResource
    
    required init(with resource: Resource) throws {
        guard let imageResource = resource as? ImageResource else {
            throw ModelError.IncorrectType
        }
        
        self.imageResource = imageResource
    }
}
