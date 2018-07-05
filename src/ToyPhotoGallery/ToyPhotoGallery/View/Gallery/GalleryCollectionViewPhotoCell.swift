//
//  GalleryCollectionViewPhotoCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GalleryCollectionViewPhotoCell : UICollectionViewCell {
    var model:GalleryCollectionViewPhotoCellModel? {
        didSet {
            if let model = model {
                refresh(with: model)
            }
        }
    }
    
    func refresh(with model:GalleryCollectionViewPhotoCellModel) {
        
    }    
}
