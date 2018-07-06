//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct GalleryCollectionViewImageCellAppeareance {
    let shadowOffset:CGSize = CGSize(width: 0.0, height: -0.5)
    let shadowOpacity:Float = 0.1
}

class GalleryCollectionViewImageCell : UICollectionViewCell {
    
    let defaultBackgroundColor:UIColor = .white
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

    func refresh(with model:GalleryCollectionViewImageCellModel, appearance:GalleryCollectionViewImageCellAppeareance = GalleryCollectionViewImageCellAppeareance()) {
        backgroundColor = defaultBackgroundColor
        layer.shadowOpacity = appearance.shadowOpacity
        layer.shadowOffset = appearance.shadowOffset
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
