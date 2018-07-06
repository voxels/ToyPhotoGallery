//
//  GalleryCollectionViewLayout.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

/// Configuration parameters measured from GIMP
struct FlowLayoutConfiguration {
    var compWidth:CGFloat                   = 640.0
    var scrollDirection:UICollectionViewScrollDirection = .vertical
    var minimumLineSpacing:CGFloat          = 16.0
    var minimumInteritemSpacing:CGFloat     = 16.0
    var itemSize:CGSize                     = CGSize(width: 282.0, height: 206.0)
    var estimatedItemSize:CGSize            = CGSize(width: 282.0, height: 206.0)
    var sectionInset:UIEdgeInsets           = UIEdgeInsets(top: 30.0, left: 30.0, bottom: 30.0, right: 30.0)
    var headerReferenceSize:CGSize          = CGSize.zero
    var footerReferenceSize:CGSize          = CGSize.zero
}

protocol GalleryCollectionViewLayoutDelegate : class {
    var errorHandler:ErrorHandlerDelegate { get }
    func previewItem(at indexPath:IndexPath) throws
}

class GalleryCollectionViewLayout : UICollectionViewFlowLayout {
    
    var configuration:FlowLayoutConfiguration = FlowLayoutConfiguration()
    weak var delegate:GalleryCollectionViewLayoutDelegate?
    
    /// Used for relative content size calculation
    let defaultLogicalWidth:CGFloat = 320   // the logical width is different for every device, but we
    var containerWidth:CGFloat {
        return collectionView?.frame.size.width ?? defaultLogicalWidth
    }
    
    override init() {
        super.init()
        configure(with:configuration)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let relativeSize = relative(size: configuration.itemSize, with: configuration, containerWidth: containerWidth)
        return relativeSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return relative(dimension: configuration.minimumLineSpacing, with: configuration, containerWidth: containerWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return relative(dimension: configuration.minimumInteritemSpacing, with: configuration, containerWidth: containerWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let relativeInset = relative(edgeInsets: configuration.sectionInset, with: configuration, containerWidth:containerWidth )
        return relativeInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return relative(size: configuration.headerReferenceSize, with: configuration, containerWidth: containerWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return relative(size: configuration.footerReferenceSize, with: configuration, containerWidth: containerWidth)
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
