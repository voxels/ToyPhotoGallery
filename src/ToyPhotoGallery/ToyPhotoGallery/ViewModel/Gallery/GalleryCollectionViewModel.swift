//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryCollectionViewModelDelegate : class {
    func imageResources(skip:Int, limit:Int, completion:ImageResourceCompletion?)
}

class GalleryCollectionViewModel {
    weak var modelDelegate:GalleryCollectionViewModelDelegate? {
        didSet {
            if let delegate = modelDelegate {
                refresh(with: delegate)
            }
        }
    }
    
    weak var viewModelDelegate:GalleryViewModelDelegate?
    
    var dataSource = [GalleryCollectionViewCellModel]()
    
    func refresh(with delegate:GalleryCollectionViewModelDelegate) {
        dataSource = [GalleryCollectionViewCellModel]()
    }
}
