//
//  PreviewViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {
    var viewModel:PreviewViewModel? {
        didSet {
            if let model = viewModel {
                refresh(with: model)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func refresh(with viewModel:PreviewViewModel) {
        viewModel.delegate = self
    }
}

extension PreviewViewController : PreviewViewModelDelegate {
    
}
