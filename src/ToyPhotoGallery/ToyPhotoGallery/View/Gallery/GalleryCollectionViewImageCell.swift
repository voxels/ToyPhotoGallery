
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
    
    var fadeDuration:TimeInterval = 0.5
    
    var thumbnailImageView:UIImageView = UIImageView(frame: CGRect.zero)
    var fileImageView:UIImageView = UIImageView(frame: CGRect.zero)
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
        fileImageView.image = nil
        thumbnailImageView.frame = self.contentView.bounds
        fileImageView.frame = self.fileImageView.bounds
        model = nil
    }
    
    func refresh(with model:GalleryCollectionViewImageCellModel, appearance:GalleryCollectionViewImageCellAppearance = GalleryCollectionViewImageCellAppearance()) throws {
        try configure(with: appearance, model:model)
        self.model = model
    }
    
    func configure(with appearance:GalleryCollectionViewImageCellAppearance, model:GalleryCollectionViewImageCellModel) throws {
        self.appearance = appearance
        backgroundColor = appearance.defaultBackgroundColor
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
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.contentMode = .scaleAspectFill
    }
}
