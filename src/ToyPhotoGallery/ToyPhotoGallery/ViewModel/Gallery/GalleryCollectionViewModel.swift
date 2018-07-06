//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryCollectionViewModelDelegate : class {
    var errorHandler:ErrorHandlerDelegate { get }
    func imageResources(skip:Int, limit:Int, completion:ImageResourceCompletion?)
}

class GalleryCollectionViewModel {
    static let defaultPageSize:Int = 30
    
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
        delegate.imageResources(skip: 0, limit: GalleryCollectionViewModel.defaultPageSize) { [weak self] (resources) in
            let imageModels = resources.compactMap({ [weak self] (imageResource) -> GalleryCollectionViewImageCellModel? in
                do {
                    return try GalleryCollectionViewImageCellModel(with: imageResource)
                } catch {
                    self?.resourceDelegate?.errorHandler.report(error)
                }
                return nil
            })
            self?.dataSource.append(contentsOf: imageModels)
            self?.viewModelDelegate?.didUpdateViewModel()
        }
    }
}
