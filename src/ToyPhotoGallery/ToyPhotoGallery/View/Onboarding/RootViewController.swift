//
//  RootViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var timer:Timer?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { [weak self] (timer) in
            self?.showActivityIndicator()
        })
    }
    
    func showActivityIndicator() {
        activityIndicator.isHidden = true
    }
}
