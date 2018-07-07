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
    var interface:NetworkSessionInterface

    required init(with resource: Resource, networkSessionInterface:NetworkSessionInterface? = nil) throws {
        guard let imageResource = resource as? ImageResource, let interface = networkSessionInterface else {
            throw ModelError.IncorrectType
        }
        
        self.imageResource = imageResource
        self.interface = interface
    }
}
