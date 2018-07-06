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
            if model != nil {
                refresh()
            }
        }
    }
    
    let defaultBackgroundColor:UIColor = .white
    let defaultIdentifier = "default"
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        register(identifiers: [defaultIdentifier, GalleryCollectionViewImageCellModel.identifier])
        if let delegate = layout as? GalleryCollectionViewLayout {
            assign(dataSource: self, delegate:delegate )
        } else {
            assign(dataSource: self, delegate: self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        register(identifiers: [defaultIdentifier, GalleryCollectionViewImageCellModel.identifier])
    }
}

extension GalleryCollectionView {
    func register(identifiers:[String]) {
        identifiers.forEach { [weak self] (identifier) in
            switch identifier {
            case GalleryCollectionViewImageCellModel.identifier:
                self?.register(GalleryCollectionViewImageCell.classForCoder(), forCellWithReuseIdentifier: identifier)
            case defaultIdentifier:
                fallthrough
            default:
                self?.register(UICollectionViewCell.classForCoder(), forCellWithReuseIdentifier: identifier)
            }
        }
    }
    
    func assign(dataSource:UICollectionViewDataSource, delegate:UICollectionViewDelegateFlowLayout) {
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    func refresh() {
        self.reloadData()
    }
}

extension GalleryCollectionView : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model?.dataSource.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        do {
            try model?.viewDidRequestCell(for: indexPath)
        } catch {
            model?.resourceDelegate?.errorHandler.report(error)
        }
        
        var identifier = defaultIdentifier
        
        guard let cellDataSource = model?.dataSource, let cellModel = cellDataSource[safe:UInt(indexPath.item)] else {
            model?.resourceDelegate?.errorHandler.report(ModelError.MissingDataSourceItem)
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        }
        
        switch cellModel {
        case is GalleryCollectionViewImageCellModel:
            identifier = GalleryCollectionViewImageCellModel.identifier
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? GalleryCollectionViewImageCell else {
                model?.resourceDelegate?.errorHandler.report(ModelError.IncorrectType)
                return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
            }
            cell.model = cellModel as? GalleryCollectionViewImageCellModel
            return cell
        default:
            model?.resourceDelegate?.errorHandler.report(ModelError.IncorrectType)
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Unused delegate

// Included for type safety
extension GalleryCollectionView : UICollectionViewDelegateFlowLayout {}
