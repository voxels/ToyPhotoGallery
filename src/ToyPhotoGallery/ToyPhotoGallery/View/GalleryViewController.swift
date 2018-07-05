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
    
    @IBOutlet weak var headingContainerView: UIView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var headingContainerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contentContainerView: UIView!    
    
    var debugTransitionButton:UIButton = UIButton(type: UIButtonType.custom)
    var debugTransitionButtonSize = CGSize(width: 100, height: 44)
    var debugTransitionMargins:UIEdgeInsets = UIEdgeInsets(top: 56, left: 0, bottom: 0, right: 20)
    var customConstraints = [NSLayoutConstraint]()
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkDebugState(with: debugTransitionButton)
    }
    
    func refresh(with viewModel:GalleryViewModel) {
        viewModel.delegate = self
        viewModel.dataSource = viewModel.buildDataSource(from: viewModel.resourceModelController)
    }
    
    func show(previewViewController:PreviewViewController, for imageResource:ImageResource) {
        let viewModel = PreviewViewModel()
        viewModel.imageResource = imageResource
        previewViewController.viewModel = viewModel
    }
    
    override func updateViewConstraints() {
        if customConstraints.count > 0 {
            NSLayoutConstraint.deactivate(customConstraints)
            view.removeConstraints(customConstraints)
        }
        
        customConstraints.removeAll()
        
        if view.subviews.contains(debugTransitionButton) {
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=0)-[debugButton(==buttonWidth)]-horizontalMargin-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: ["buttonWidth":debugTransitionButtonSize.width, "horizontalMargin":debugTransitionMargins.right], views: ["debugButton" : debugTransitionButton])
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-verticalMargin-[debugButton(==buttonHeight)]-(>=0)-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: ["buttonHeight":debugTransitionButtonSize.height, "verticalMargin":debugTransitionMargins.top], views: ["debugButton" : debugTransitionButton])
            
            customConstraints.append(contentsOf: horizontalConstraints)
            customConstraints.append(contentsOf: verticalConstraints)
        }
        
        NSLayoutConstraint.activate(customConstraints)
        super.updateViewConstraints()
    }
}

extension GalleryViewController {
    func checkDebugState(with debugButton:UIButton) {
        // TODO: Create feature flag
        #if DEBUG
        configure(debugButton: debugButton)
        view.addSubview(debugButton)
        refreshLayout(in: view)
        #endif
    }
    
    func configure(debugButton:UIButton) {
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.setTitle("Transition In", for: .normal)
        debugButton.setTitleColor(.black, for: .normal)
        debugButton.addTarget(self, action: #selector(debugPreviewViewControllerTransition), for: .touchUpInside)
    }
    
    @objc func debugPreviewViewControllerTransition() {
        #if DEBUG
        guard let previewViewController = UIStoryboard.init(name: StoryboardMap.Main.rawValue, bundle: .main).instantiateViewController(withIdentifier: StoryboardMap.ViewController.PreviewViewController.rawValue) as? PreviewViewController, let model = viewModel else {
            return
        }
        
        let previewViewModel = PreviewViewModel()
        previewViewModel.imageResource = model.imageResource(for: 0)
        previewViewController.viewModel = previewViewModel
        
        try? insert(childViewController: previewViewController, on: self, into: view)
        
        #endif
    }
}

// MARK: - GalleryViewModelDelegate

extension GalleryViewController : GalleryViewModelDelegate {
    func didUpdateModel() {
        
    }
}
