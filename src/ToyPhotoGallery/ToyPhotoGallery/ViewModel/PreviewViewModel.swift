//
//  PreviewViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol PreviewViewModelDelegate {
    
}

class PreviewViewModel {
    var imageResource:ImageResource? {
        didSet {
            
        }
    }
    
    var delegate:PreviewViewModelDelegate? {
        didSet {
            
        }
    }
}
