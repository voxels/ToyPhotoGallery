//
//  UIViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

extension UIViewController {
    func insert(childViewController:UIViewController, on parentViewController:UIViewController, into view:UIView, frame:CGRect? = nil ) throws {
        if childViewController.parent != nil {
            remove(childViewController: childViewController)
        }
        
        parentViewController.addChildViewController(childViewController)
        childViewController.didMove(toParentViewController: parentViewController)
        if let frame = frame {
            childViewController.view.frame = frame
        } else {
            childViewController.view.bounds = view.bounds
        }
        view.addSubview(childViewController.view)
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
