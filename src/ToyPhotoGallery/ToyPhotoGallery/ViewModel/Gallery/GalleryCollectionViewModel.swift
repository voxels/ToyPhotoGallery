//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryCollectionViewModelDelegate {
    
}

class GalleryCollectionViewModel {
    var delegate:GalleryCollectionViewModelDelegate?
    var dataSource = [GalleryCollectionViewCellModel]()
    
    var parentModel:GalleryViewModel
    
    init(with galleryViewModel:GalleryViewModel) {
        parentModel = galleryViewModel
    }
}
