//
//  GalleryViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GalleryViewController: UIViewController {
    var viewModel:GalleryViewModel? {
        didSet {
            if let model = viewModel {
                refresh(with: model)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func refresh(with viewModel:GalleryViewModel) {
        viewModel.delegate = self
        viewModel.dataSource = viewModel.buildDataSource(from: viewModel.resourceModelController)
        
    }
}

// MARK: - GalleryViewModelDelegate

extension GalleryViewController : GalleryViewModelDelegate {
    
}
