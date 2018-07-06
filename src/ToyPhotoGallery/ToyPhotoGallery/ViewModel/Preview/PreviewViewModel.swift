//
//  PreviewViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

class PreviewViewModel {
    var currentIndexPath:IndexPath
    
    init(with indexPath:IndexPath, galleryCollectionViewModel:GalleryCollectionViewModel) {
        self.currentIndexPath = indexPath
    }    
}
