//
//  PreviewViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class PreviewViewController: UIViewController {
    
    let logHandler = DebugLogHandler()
    
    @IBOutlet weak var contentContainerView: UIView!
    
    let defaultBackgroundColor:UIColor = .clear

    @IBAction func onTapPlusOneButton(_ sender: Any) {
        logHandler.console("tap plus one")
    }
    
    @IBAction func onTapCommentButton(_ sender: Any) {
        logHandler.console("tap comment")
    }
    
    @IBAction func onTapAddButton(_ sender: Any) {
        logHandler.console("tap add")
    }
    
    @IBAction func onTapShareButton(_ sender: Any) {
        logHandler.console("tap share")
    }    
}
