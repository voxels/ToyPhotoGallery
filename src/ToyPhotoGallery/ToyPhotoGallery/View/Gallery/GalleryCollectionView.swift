//
//  GalleryCollectionView.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GalleryCollectionView: UICollectionView {
    var model:GalleryCollectionViewModel? {
        didSet {
            
        }
    }
    
    var defaultIdentifier = "default"
    var errorHandler:ErrorHandlerDelegate = DebugErrorHandler()

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        register(identifiers: [defaultIdentifier, GalleryCollectionViewPhotoCellModel.identifier])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        register(identifiers: [defaultIdentifier, GalleryCollectionViewPhotoCellModel.identifier])
    }
}

extension GalleryCollectionView {
    func register(identifiers:[String]) {
        identifiers.forEach { [weak self] (identifier) in
            switch identifier {
            case GalleryCollectionViewPhotoCellModel.identifier:
                self?.register(GalleryCollectionViewPhotoCell.classForCoder(), forCellWithReuseIdentifier: identifier)
            case defaultIdentifier:
                fallthrough
            default:
                self?.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: identifier)
            }
        }
    }
}

extension GalleryCollectionView : UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model?.dataSource.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var identifier = defaultIdentifier
        
        guard let cellDataSource = model?.dataSource, let cellModel = cellDataSource[safe:UInt(indexPath.item)] else {
            errorHandler.report(ModelError.MissingDataSourceItem)
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        }
        
        switch cellModel {
        case is GalleryCollectionViewPhotoCellModel:
            identifier = GalleryCollectionViewPhotoCellModel.identifier
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? GalleryCollectionViewPhotoCell else {
                errorHandler.report(ModelError.IncorrectType)
                return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
            }
            cell.model = cellModel as? GalleryCollectionViewPhotoCellModel
            return cell
        default:
            errorHandler.report(ModelError.IncorrectType)
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        }
    }
}
