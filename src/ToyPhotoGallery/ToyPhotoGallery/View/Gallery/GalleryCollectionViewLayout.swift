//
//  GalleryCollectionViewLayout.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

protocol FlowLayoutConfiguration {
    var compWidth:CGFloat { get set }
    var scrollDirection:UICollectionViewScrollDirection { get set }
    var minimumLineSpacing:CGFloat { get set }
    var minimumInteritemSpacing:CGFloat { get set }
    var estimatedItemSize:CGSize { get set }
    var sectionInset:UIEdgeInsets { get set }
    var headerReferenceSize:CGSize { get set }
    var footerReferenceSize:CGSize { get set }
}

protocol FlowLayoutConfigurationSizeDelegate : class {
    func sizeForItemAt( indexPath: IndexPath, layout:GalleryCollectionViewLayout, currentConfiguration:FlowLayoutConfiguration)->CGSize
}

/// Configuration parameters measured from GIMP
struct FlowLayoutVerticalConfiguration : FlowLayoutConfiguration {
    var compWidth:CGFloat                   = 640.0
    var scrollDirection:UICollectionViewScrollDirection = .vertical
    var minimumLineSpacing:CGFloat          = 16.0
    var minimumInteritemSpacing:CGFloat     = 16.0
    var estimatedItemSize:CGSize            = CGSize(width: 282.0, height: 206.0)
    var sectionInset:UIEdgeInsets           = UIEdgeInsets(top: 30.0, left: 30.0, bottom: 30.0, right: 30.0)
    var headerReferenceSize:CGSize          = CGSize.zero
    var footerReferenceSize:CGSize          = CGSize.zero
}

struct FlowLayoutHorizontalConfiguration : FlowLayoutConfiguration {
    var compWidth:CGFloat                   = 640.0
    var scrollDirection:UICollectionViewScrollDirection = .horizontal
    var minimumLineSpacing:CGFloat          = 50.0
    var minimumInteritemSpacing:CGFloat     = 50.0
    var estimatedItemSize:CGSize            = CGSize(width: 320.0, height: 240.0)
    var sectionInset:UIEdgeInsets           = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    var headerReferenceSize:CGSize          = CGSize.zero
    var footerReferenceSize:CGSize          = CGSize.zero
}

protocol GalleryCollectionViewLayoutDelegate : class {
    var errorHandler:ErrorHandlerDelegate { get }
    func previewItem(at indexPath:IndexPath) throws
}
class GalleryCollectionViewLayout : UICollectionViewFlowLayout {
    
    let defaultAspectRatio:Float = 4.0/3.0

    var errorHandler:ErrorHandlerDelegate?
    var configuration:FlowLayoutConfiguration?
    weak var delegate:GalleryCollectionViewLayoutDelegate?
    weak var sizeDelegate:FlowLayoutConfigurationSizeDelegate?
    
    init(with configuration:FlowLayoutConfiguration, errorHandler:ErrorHandlerDelegate?) {
        super.init()
        self.configuration = configuration
        self.errorHandler = errorHandler
        configure(with:configuration)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Used for relative content size calculation
    let defaultLogicalWidth:CGFloat = 320   // the logical width is different for every device, but we
    var containerWidth:CGFloat {
        return collectionView?.frame.size.width ?? defaultLogicalWidth
    }
    
    func configure(with configuration:FlowLayoutConfiguration) {
        scrollDirection = configuration.scrollDirection
        estimatedItemSize = relative(size: configuration.estimatedItemSize, with: configuration, containerWidth: containerWidth)
    }
}

extension GalleryCollectionViewLayout : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let delegate = delegate else {
            assert(false, "The delegate is not set")
            return
        }

        do {
            try delegate.previewItem(at: indexPath)
        } catch {
            errorHandler?.report(error)
        }
    }
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var relativeSize = CGSize.zero
        
        guard let configuration = configuration, let delegate = sizeDelegate else {
            return relativeSize
        }
        
        relativeSize = delegate.sizeForItemAt(indexPath: indexPath, layout:self, currentConfiguration: configuration)
        
        return relativeSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let configuration = configuration {
            return relative(dimension: configuration.minimumLineSpacing, with: configuration, containerWidth: containerWidth)
        }
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if let configuration = configuration {
            return  relative(dimension: configuration.minimumInteritemSpacing, with: configuration, containerWidth: containerWidth)
        }
        return 0.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let configuration = configuration {
            return relative(edgeInsets: configuration.sectionInset, with: configuration, containerWidth:containerWidth )
        }
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if let configuration = configuration {
            return relative(size: configuration.headerReferenceSize, with: configuration, containerWidth: containerWidth)
        }
        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let configuration = configuration {
            return relative(size: configuration.footerReferenceSize, with: configuration, containerWidth: containerWidth)
        }
        return CGSize.zero
    }
}

extension GalleryCollectionViewLayout {
    
    func relative(edgeInsets:UIEdgeInsets, with configuration:FlowLayoutConfiguration, containerWidth:CGFloat)->UIEdgeInsets {
        
        let top = relative(dimension: edgeInsets.top, with: configuration, containerWidth:containerWidth)
        let left = relative(dimension: edgeInsets.left, with: configuration, containerWidth: containerWidth)
        let bottom = relative(dimension: edgeInsets.bottom, with: configuration, containerWidth: containerWidth)
        let right = relative(dimension: edgeInsets.right, with: configuration, containerWidth: containerWidth)
        
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
    
    func relative(size:CGSize, with configuration:FlowLayoutConfiguration, containerWidth:CGFloat)->CGSize {
        let width = relative(dimension: size.width, with: configuration, containerWidth: containerWidth)
        let height = relative(dimension:size.height, with: configuration, containerWidth: containerWidth)
        return CGSize(width: width, height: height)
    }
    
    func relative(dimension:CGFloat, with configuration:FlowLayoutConfiguration, containerWidth:CGFloat)->CGFloat {
        return dimension * containerWidth / configuration.compWidth
    }
}
