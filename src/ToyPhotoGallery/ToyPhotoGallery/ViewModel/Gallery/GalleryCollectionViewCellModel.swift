//
//  GalleryCollectionViewCellModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

// Abstract class used to inherit data source cell items
protocol GalleryCollectionViewCellModel : class {
    static var identifier : String { get }
    var updatedAt : Date { get set }
}
