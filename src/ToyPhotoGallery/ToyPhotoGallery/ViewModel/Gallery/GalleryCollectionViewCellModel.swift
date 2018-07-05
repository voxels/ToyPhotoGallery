//
//  GalleryCollectionViewCellModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Generic cell model created so that the collection view data source can hold subtypes
protocol GalleryCollectionViewCellModel {
    static var identifier : String { get }
}
