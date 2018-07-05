//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryCollectionViewModelDelegate {
    func cellModels(from table:RemoteStoreTableMap, sortBy:String?, for skip:Int, limit:Int)->[GalleryCollectionViewCellModel]
}

class GalleryCollectionViewModel {
    var modelDelegate:GalleryCollectionViewModelDelegate?
    var viewModelDelegate:GalleryViewModelDelegate?
    
    var dataSource = [GalleryCollectionViewCellModel]()
    
    var parentModel:GalleryViewModel {
        didSet {
            refresh(with: parentModel)
        }
    }
    
    init(with galleryViewModel:GalleryViewModel) {
        parentModel = galleryViewModel
    }
    
    func refresh(with parentModel:GalleryViewModel) {
        dataSource = [GalleryCollectionViewCellModel]()
    }
}
