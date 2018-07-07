//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct GalleryCollectionViewImageCellAppearance {
    let shadowOffset:CGSize = CGSize(width: 0.0, height: -0.5)
    let shadowOpacity:Float = 0.1
}

class GalleryCollectionViewImageCell : UICollectionViewCell {
    
    let defaultBackgroundColor:UIColor = .white
    var imageView:BufferedImageView?
    
    var model:GalleryCollectionViewImageCellModel? {
        didSet {
            if let model = model {
                refresh(with: model)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.cancel()
        imageView?.removeFromSuperview()
        imageView = nil
    }

    func refresh(with model:GalleryCollectionViewImageCellModel, appearance:GalleryCollectionViewImageCellAppearance = GalleryCollectionViewImageCellAppearance()) {
        backgroundColor = defaultBackgroundColor
        layer.shadowOpacity = appearance.shadowOpacity
        layer.shadowOffset = appearance.shadowOffset
        imageView?.image = nil
        configure(with:model.imageResource.thumbnailURL, networkSessionInterface:model.interface)
    }
    
    func configure(with url:URL, networkSessionInterface:NetworkSessionInterface) {
        let newImageView = BufferedImageView(url: url, networkSessionInterface: networkSessionInterface)
        newImageView.clipsToBounds = true
        newImageView.frame = bounds
        newImageView.backgroundColor = .white
        newImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newImageView.translatesAutoresizingMaskIntoConstraints = true
        newImageView.contentMode = .scaleAspectFill
        addSubview(newImageView)
        imageView = newImageView
    }
}
