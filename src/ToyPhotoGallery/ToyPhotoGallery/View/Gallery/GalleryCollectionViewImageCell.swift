
//
//  GalleryCollectionViewImageCell.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct GalleryCollectionViewImageCellAppearance {
    let defaultBackgroundColor:UIColor = .white
    let shadowOffset:CGSize = CGSize(width: 0.0, height: -0.5)
    let shadowOpacity:Float = 0.1
}

class GalleryCollectionViewImageCell : UICollectionViewCell {
    
    var model:GalleryCollectionViewImageCellModel?
    var appearance:GalleryCollectionViewImageCellAppearance?

    var fadeDuration:TimeInterval = 0.5

    var thumbnailImageView:UIImageView?
    var fileImageView:UIImageView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        layer.shadowOpacity = 0.0
        thumbnailImageView?.removeFromSuperview()
        thumbnailImageView = nil
        fileImageView?.removeFromSuperview()
        fileImageView = nil
        model = nil
    }
    
    func refresh(with model:GalleryCollectionViewImageCellModel, appearance:GalleryCollectionViewImageCellAppearance = GalleryCollectionViewImageCellAppearance()) throws {
        try configure(with: appearance, model:model)
        self.model = model
    }
    
    func configure(with appearance:GalleryCollectionViewImageCellAppearance, model:GalleryCollectionViewImageCellModel) throws {
        self.appearance = appearance
        backgroundColor = appearance.defaultBackgroundColor
        
        configureThumbnailImageView(for: model)
    }
    
    func configureThumbnailImageView(for model:GalleryCollectionViewImageCellModel) {
        if let image = model.imageResource.thumbnailImage {
            let newImageView = UIImageView(image: image)
            applyAttributes(to: newImageView)
            addSubview(newImageView)
            thumbnailImageView = newImageView
            showThumbnail()
        } else {
            let newImageView = UIImageView.imageView(with:model.imageResource, url:model.imageResource.fileURL, networkSessionInterface:model.interface, completion:{[weak self] (image) in
                DispatchQueue.main.async {
                    model.imageResource.thumbnailImage = image
                    
                    guard let strongSelf = self else {
                        return
                    }
                    if model == strongSelf.model {
                        strongSelf.thumbnailImageView?.image = image
                        if let appearance = strongSelf.appearance {
                            strongSelf.layer.shadowOpacity = appearance.shadowOpacity
                            strongSelf.layer.shadowOffset = appearance.shadowOffset
                        }
                    }
                }
            })
            applyAttributes(to: newImageView)
            addSubview(newImageView)
            thumbnailImageView = newImageView
            showThumbnail()
        }
    }
    
    func configureFileImageView(for model:GalleryCollectionViewImageCellModel) {
        if let image = model.imageResource.fileImage {
            let newImageView = UIImageView(image:image)
            applyAttributes(to: newImageView)
            if let thumbnailImageView = thumbnailImageView, subviews.contains(thumbnailImageView) {
                insertSubview(newImageView, belowSubview: thumbnailImageView)
            } else {
                addSubview(newImageView)
            }
            fileImageView = newImageView
            showFileImageView()
        } else {
            let newImageView = UIImageView.imageView(with:model.imageResource, url:model.imageResource.fileURL, networkSessionInterface:model.interface, completion:{ (image) in
                DispatchQueue.main.async { [weak self] in
                    model.imageResource.fileImage = image
                    if model == self?.model {
                        self?.fileImageView?.image = image
                    }
                }
            })
            if let thumbnailImageView = thumbnailImageView, subviews.contains(thumbnailImageView) {
                insertSubview(newImageView, belowSubview: thumbnailImageView)
            } else {
                addSubview(newImageView)
            }
            fileImageView = newImageView
            showFileImageView()
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
        imageView.backgroundColor = .white
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0.0
    }
}

extension GalleryCollectionViewImageCell {
    func showFileImageView() {
        guard let fileImageView = fileImageView else {
            return
        }
        
        fileImageView.alpha = 1.0
        
        if let thumbnailImageView = thumbnailImageView {
            UIView.animate(withDuration: fadeDuration, delay: 0.0, options: .curveLinear, animations: {
                thumbnailImageView.alpha = 0.0
            }) { (didSucceed) in
                thumbnailImageView.isHidden = true
            }
        }
    }
    
    func showThumbnail() {
        guard let thumbnailImageView = thumbnailImageView else {
            return
        }
        
        thumbnailImageView.alpha = 0
        thumbnailImageView.isHidden = false
        
        UIView.animate(withDuration: fadeDuration, delay: 0.0, options: .curveLinear, animations: {
            thumbnailImageView.alpha = 1.0
        }) { (didSucceed) in
            
        }
    }
}
