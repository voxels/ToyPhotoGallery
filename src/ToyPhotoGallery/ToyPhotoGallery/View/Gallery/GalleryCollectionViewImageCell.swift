
//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct GalleryCollectionViewImageCellAppearance {
    let defaultBackgroundColor:UIColor = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 240.0/255.0)
}

class GalleryCollectionViewImageCell : UICollectionViewCell {
    
    var model:GalleryCollectionViewImageCellModel?
    var appearance:GalleryCollectionViewImageCellAppearance?    
    
    var thumbnailImageView:UIImageView = UIImageView(frame: CGRect.zero)
    var fileImageView:UIImageView = UIImageView(frame: CGRect.zero)

    let fadeDuration:TimeInterval = 0.5

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        fileImageView.image = nil
        thumbnailImageView.frame = self.contentView.bounds
        fileImageView.frame = self.contentView.bounds
        model = nil
    }
    
    func refresh(with model:GalleryCollectionViewImageCellModel, appearance:GalleryCollectionViewImageCellAppearance = GalleryCollectionViewImageCellAppearance()) {
        configure(with: appearance, model:model)
        self.model = model
    }
    
    func configure(with appearance:GalleryCollectionViewImageCellAppearance, model:GalleryCollectionViewImageCellModel) {
        self.appearance = appearance
        backgroundColor = appearance.defaultBackgroundColor
        
        apply(image: model.imageResource.thumbnailImage, to:thumbnailImageView)
        apply(image: model.imageResource.fileImage, to: fileImageView)
        
        if thumbnailImageView.image != nil {
            show(imageView:thumbnailImageView)
        }
    }

    func apply(image:UIImage?, to imageView:UIImageView) {
        if !contentView.subviews.contains(imageView) {
            applyAttributes(to: imageView)
            imageView.isHidden = true
            imageView.alpha = 0.0
            contentView.addSubview(imageView)
        }
        
        imageView.image = image
    }
    
    func show(imageView:UIImageView) {
        if imageView.isHidden {
            imageView.isHidden = false
            UIView.animate(withDuration: fadeDuration) {
                imageView.alpha = 1.0
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
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
    }
}
