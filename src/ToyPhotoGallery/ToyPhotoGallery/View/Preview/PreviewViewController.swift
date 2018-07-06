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
    
    @IBOutlet weak var sceneContainerView: UIView!
    @IBOutlet weak var sceneView: PreviewSceneView!

    @IBOutlet weak var kitContainerView: UIView!
    @IBOutlet weak var contentContainerView: UIView!
    
    let defaultBackgroundColor:UIColor = .clear

    func refresh(with viewModel:PreviewViewModel) {
        
    }
    
    @IBAction func onTapCloseButton(_ sender: Any) {
        parent?.remove(childViewController: self)
    }
}
