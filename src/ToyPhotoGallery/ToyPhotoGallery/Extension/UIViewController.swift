//
//  UIViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

extension UIViewController {
    func insert(childViewController:UIViewController, on parentViewController:UIViewController, into view:UIView ) throws {
        if childViewController.parent != nil {
            remove(childViewController: childViewController)
        }
        
        parentViewController.addChildViewController(childViewController)
        childViewController.view.frame = view.bounds

        childViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(childViewController.view)
        childViewController.didMove(toParentViewController: parentViewController)

    }
    
    func remove(childViewController:UIViewController) {
        childViewController.view.removeFromSuperview()
        childViewController.willMove(toParentViewController: nil)
        childViewController.removeFromParentViewController()
    }
    
    func refreshLayout(in view:UIView) {
        view.setNeedsUpdateConstraints()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}
