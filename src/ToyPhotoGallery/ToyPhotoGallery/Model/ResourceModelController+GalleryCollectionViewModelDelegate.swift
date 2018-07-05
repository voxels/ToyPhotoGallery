//
//  ResourceModelController+GalleryCollectionViewModelDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension ResourceModelController : GalleryCollectionViewModelDelegate {
    func cellModels(from table: RemoteStoreTableMap, sortBy: String?, for skip: Int, limit: Int) -> [GalleryCollectionViewCellModel] {
        let models = [GalleryCollectionViewCellModel]()
        
        return models
    }
}
