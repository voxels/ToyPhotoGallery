
//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct GalleryCollectionViewImageCellAppearance {
    var backgroundColor:UIColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 240.0/255.0)
    var fadeDuration:TimeInterval = 0.5
}

class GalleryCollectionViewImageCell : UICollectionViewCell {
    
    var model:ImageResource?
    var appearance:GalleryCollectionViewImageCellAppearance?    
    
    var thumbnailImageView:UIImageView = UIImageView(frame: CGRect.zero)
    var fileImageView:UIImageView = UIImageView(frame: CGRect.zero)

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.isHidden = true
        thumbnailImageView.image = nil
        thumbnailImageView.alpha = 0.0
        
        fileImageView.isHidden = true
        fileImageView.image = nil
        fileImageView.alpha = 0.0
        
        model = nil
    }
    
    func refresh(with model:ImageResource, appearance:GalleryCollectionViewImageCellAppearance) {
        configure(with: appearance, model:model)
        self.model = model
    }
    
    func configure(with appearance:GalleryCollectionViewImageCellAppearance, model:ImageResource) {
        self.appearance = appearance
        backgroundColor = appearance.backgroundColor
        
        apply(image: model.thumbnailImage, to:thumbnailImageView)
        apply(image: model.fileImage, to: fileImageView)
    }

    func apply(image:UIImage?, to imageView:UIImageView) {
        if !contentView.subviews.contains(imageView) {
            applyAttributes(to: imageView)
            contentView.addSubview(imageView)
        }
        
        imageView.image = image
    }
    
    func show(imageView:UIImageView, with appearance:GalleryCollectionViewImageCellAppearance) {
        if imageView.isHidden {
            imageView.isHidden = false
            if imageView.alpha <= 0.01 {
                UIView.animate(withDuration: appearance.fadeDuration) {
                    imageView.alpha = 1.0
                }
            }
        }
    }
}

extension GalleryCollectionViewImageCell {
    func applyAttributes(to imageView:UIImageView?) {
        guard let imageView = imageView else {
            return
        }
        imageView.clipsToBounds = true
        imageView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.alpha = 0.0
    }
}
