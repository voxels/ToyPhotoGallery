//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GalleryCollectionViewImageCell : UICollectionViewCell {
    var model:GalleryCollectionViewImageCellModel? {
        didSet {
            if let model = model {
                refresh(with: model)
            }
        }
    }
    
    func refresh(with model:GalleryCollectionViewImageCellModel) {
        
    }
}
