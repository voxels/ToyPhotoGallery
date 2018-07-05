//
//  PreviewViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol PreviewViewModelDelegate : class {
    func didUpdateViewModel()
}

class PreviewViewModel {
    var imageResource:ImageResource? {
        didSet {
            if let resource = imageResource {
                refresh(with: resource)
            }
        }
    }
    
    weak var delegate:PreviewViewModelDelegate?
    
    func refresh(with imageResource:ImageResource) {
        delegate?.didUpdateViewModel()
    }
}
