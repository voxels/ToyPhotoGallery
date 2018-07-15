//
//  GalleryCollectionView.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GalleryCollectionView: UICollectionView {
    var model:GalleryCollectionViewModel?
    
    let defaultBackgroundColor:UIColor = .white
    let defaultIdentifier = "default"
    let imageIdentifer = "image"
    var cellAppearance:GalleryCollectionViewImageCellAppearance?
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        register(identifiers: [defaultIdentifier, imageIdentifer])
        if let delegate = layout as? GalleryCollectionViewLayout {
            assign(dataSource: self, delegate:delegate )
        } else {
            assign(dataSource: self, delegate: self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        register(identifiers: [defaultIdentifier, imageIdentifer])
    }
}

extension GalleryCollectionView {
    func register(identifiers:[String]) {
        identifiers.forEach { [weak self] (identifier) in
            switch identifier {
            case imageIdentifer:
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
}

extension GalleryCollectionView : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model?.data.count ?? 0
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
        
        guard let cellDataSource = model?.data, let cellModel = cellDataSource[safe:UInt(indexPath.item)] else {
            model?.resourceDelegate?.errorHandler.report(ModelError.MissingDataSourceItem)
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        }
        
        identifier = imageIdentifer
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? GalleryCollectionViewImageCell else {
            model?.resourceDelegate?.errorHandler.report(ModelError.IncorrectType)
            return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        }
        
        var appearance = GalleryCollectionViewImageCellAppearance()
        if let overrideAppearance = cellAppearance {
            appearance = overrideAppearance
        }
        
        cell.refresh(with: cellModel, appearance:appearance)
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(Int(appearance.fadeDuration))) {
            cell.show(imageView:cell.thumbnailImageView, with:appearance)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Unused delegate

// Included for type safety
extension GalleryCollectionView : UICollectionViewDelegateFlowLayout {}
