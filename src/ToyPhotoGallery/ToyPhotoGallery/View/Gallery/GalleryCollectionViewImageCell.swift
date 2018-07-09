
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
        for view in subviews{
            view.removeFromSuperview()
        }
        thumbnailImageView = nil
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
            configureFileImageView(for: model)
        } else {
            model.interface.fetch(url: model.imageResource.thumbnailURL) { [weak self, weak configurationModel = model] (data) in
                guard let data = data, let strongSelf = self else {
                    return
                }
                
                if let existingModel = strongSelf.model {
                    let existingResourceFileName = existingModel.imageResource.filename
                    if configurationModel?.imageResource.filename != existingResourceFileName  {
                        self?.configureThumbnailImageView(for: existingModel)
                    } else {
                        self?.addThumbnailImageView(for: existingModel, data: data)
                    }
                } else {
                    model.interface.errorHandler.report(ModelError.MissingValue)
                    assert(false)
                }
            }
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
            model.interface.fetch(url: model.imageResource.fileURL) { [weak self, weak configurationModel = model] (data) in
                guard let data = data, let strongSelf = self else {
                    return
                }
                
                if model != strongSelf.model {
                    return
                }
                
                if let existingModel = strongSelf.model {
                    let existingResourceFileName = existingModel.imageResource.filename
                    if configurationModel?.imageResource.filename != existingResourceFileName  {
                        self?.configureFileImageView(for: existingModel)
                    } else {
                        self?.addFileImageView(for: existingModel, data: data)
                    }
                } else {
                    model.interface.errorHandler.report(ModelError.MissingValue)
                    assert(false)
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
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.contentMode = .scaleAspectFill
    }
}

extension GalleryCollectionViewImageCell {
    
    func addThumbnailImageView( for model:GalleryCollectionViewImageCellModel, data:Data ) {
        guard model == self.model, let foundImage = UIImage(data:data) else {
            return
        }
        
        if let existingThumbnailView = thumbnailImageView, subviews.contains(existingThumbnailView) {
            existingThumbnailView.image = foundImage
        } else {
            let newImageView = UIImageView(image:UIImage(data: data))
            applyAttributes(to: newImageView)
            addSubview(newImageView)
            thumbnailImageView = newImageView
        }
        showThumbnail()
    }
    
    func addFileImageView( for model:GalleryCollectionViewImageCellModel, data:Data ) {
        guard model == self.model, let foundImage = UIImage(data:data) else {
            return
        }
        
        if let existingFileImageView = fileImageView, subviews.contains(existingFileImageView) {
            existingFileImageView.image = foundImage
        } else {
            let newImageView = UIImageView(image:foundImage)
            applyAttributes(to: newImageView)
            newImageView.alpha = 0.0
            if let thumbnailImageView = thumbnailImageView, subviews.contains(thumbnailImageView) {
                insertSubview(newImageView, belowSubview: thumbnailImageView)
            } else {
                addSubview(newImageView)
            }
            fileImageView = newImageView
        }
        showFileImageView()
    }
    
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
        
        thumbnailImageView.isHidden = false
        guard let model = model else {
            return
        }
        configureFileImageView(for: model)
    }
}
