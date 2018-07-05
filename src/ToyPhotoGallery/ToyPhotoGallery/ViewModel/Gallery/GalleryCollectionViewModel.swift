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
    weak var resourceDelegate:GalleryCollectionViewModelDelegate? {
        didSet {
            if let delegate = resourceDelegate {
                refresh(with: delegate)
            }
        }
    }
    
    weak var viewModelDelegate:GalleryViewModelDelegate?
    
    var dataSource = [GalleryCollectionViewCellModel]()
    
    func refresh(with delegate:GalleryCollectionViewModelDelegate) {
        dataSource = [GalleryCollectionViewCellModel]()
        delegate.imageResources(skip: 0, limit: 30) { [weak self] (resources) in
            for resource in resources {
                print(resource.filename)
            }
            self?.viewModelDelegate?.didUpdateViewModel()
        }
        
        delegate.imageResources(skip: 32, limit: 10) { [weak self] (resources) in
            for resource in resources {
                print(resource.filename)
            }
            self?.viewModelDelegate?.didUpdateViewModel()
        }
    }
}
