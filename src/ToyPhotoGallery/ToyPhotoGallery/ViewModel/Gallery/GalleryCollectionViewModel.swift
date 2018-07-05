//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryCollectionViewModelDelegate {
    func imageResources(sortBy:String?, skip:Int, limit:Int, completion:ImageResourceCompletion?)
}

class GalleryCollectionViewModel {
    var modelDelegate:GalleryCollectionViewModelDelegate? {
        didSet {
            if let delegate = modelDelegate {
                refresh(with: delegate)
            }
        }
    }
    
    var viewModelDelegate:GalleryViewModelDelegate?
    
    var dataSource = [GalleryCollectionViewCellModel]()
    
    func refresh(with delegate:GalleryCollectionViewModelDelegate) {
        dataSource = [GalleryCollectionViewCellModel]()
    }
}
