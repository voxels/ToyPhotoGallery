//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GalleryCollectionViewImageCell : UICollectionViewCell {
    
    let defaultBackgroundColor:UIColor = .lightGray
    var imageView:UIImageView?
    
    var model:GalleryCollectionViewImageCellModel? {
        didSet {
            if let model = model {
                refresh(with: model)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
    }

    func refresh(with model:GalleryCollectionViewImageCellModel) {
        backgroundColor = defaultBackgroundColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
        imageView?.image = nil
        let newImageView = UIImageView(frame: bounds)
        newImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newImageView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(newImageView)
        configure(imageView: newImageView)
    }
    
    func configure( imageView:UIImageView ) {
        // This is where we fetch our image
    }
}
