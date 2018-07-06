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
    
    var collectionView:GalleryCollectionView?
    
    var debugTransitionButton:UIButton = UIButton(type: UIButtonType.custom)
    var debugTransitionButtonSize = CGSize(width: 100, height: 44)
    var debugTransitionMargins:UIEdgeInsets = UIEdgeInsets(top: 56, left: 0, bottom: 0, right: 20)
    var customConstraints = [NSLayoutConstraint]()
    var retryUpdate = true
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkDebugState(with: debugTransitionButton)
    }
    
    func refresh(with viewModel:GalleryViewModel) {
        let layout = GalleryCollectionViewLayout()
        let configuredView = configuredCollectionView(with: layout, viewModel:viewModel)
        collectionView = configuredView
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
        
        if let debugButtonConstraints = constraints(debugButton: debugTransitionButton) {
            customConstraints.append(contentsOf: debugButtonConstraints)
        }
        
        if let currentCollectionView = collectionView, let collectionViewConstraints = constraints(for: currentCollectionView) {
            customConstraints.append(contentsOf: collectionViewConstraints)
        }

        NSLayoutConstraint.activate(customConstraints)
        super.updateViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard let collectionView = collectionView else {
            return
        }
        
        // We need to kick the collection view after the auto layout constraints have been applied
        // But we don't want to do this every time we layout the subviews
        if !collectionView.completedInitialLayout {
            collectionView.reloadData()
        }
    }
}

extension GalleryViewController {
    func configuredCollectionView(with layout:UICollectionViewLayout, viewModel:GalleryViewModel)->GalleryCollectionView {
        if collectionView != nil {
            collectionView?.removeFromSuperview()
            refreshLayout(in: contentContainerView)
            collectionView = nil
        }
        
        let configuredView = GalleryCollectionView(frame: .zero, collectionViewLayout: layout)
        configuredView.translatesAutoresizingMaskIntoConstraints = false
        configuredView.backgroundColor = .white
        
        let collectionViewModel = GalleryCollectionViewModel()
        collectionViewModel.viewModelDelegate = self
        collectionViewModel.resourceDelegate = viewModel.resourceModelController
        configuredView.model = collectionViewModel
        
        return configuredView
    }
}


// MARK: - Debug Button

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
        previewViewController.viewModel = previewViewModel
        
        try? insert(childViewController: previewViewController, on: self, into: view)
        
        #endif
    }
}

// MARK: - Auto Layout

extension GalleryViewController {
    func constraints(for collectionView:GalleryCollectionView)->[NSLayoutConstraint]? {
        guard contentContainerView.subviews.contains(collectionView) else {
            return nil
        }
        
        var constraints = [NSLayoutConstraint]()
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["collectionView":collectionView])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: ["collectionView":collectionView])
        constraints.append(contentsOf: horizontalConstraints)
        constraints.append(contentsOf: verticalConstraints)
        return constraints
    }
    
    func constraints(debugButton:UIButton)->[NSLayoutConstraint]? {
        guard view.subviews.contains(debugButton) else {
            return nil
        }
        var constraints = [NSLayoutConstraint]()
        if view.subviews.contains(debugTransitionButton) {
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=0)-[debugButton(==buttonWidth)]-horizontalMargin-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: ["buttonWidth":debugTransitionButtonSize.width, "horizontalMargin":debugTransitionMargins.right], views: ["debugButton" : debugTransitionButton])
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-verticalMargin-[debugButton(==buttonHeight)]-(>=0)-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: ["buttonHeight":debugTransitionButtonSize.height, "verticalMargin":debugTransitionMargins.top], views: ["debugButton" : debugTransitionButton])
            
            constraints.append(contentsOf: horizontalConstraints)
            constraints.append(contentsOf: verticalConstraints)
        }
        
        return constraints
    }
}

// MARK: - GalleryViewModelDelegate

extension GalleryViewController : GalleryViewModelDelegate {
    func didUpdateViewModel() {
        guard let collectionView = collectionView else {
            viewModel?.resourceModelController.errorHandler.report(ViewError.ViewHierarchyError)
            return
        }
        
        // Preventing a race condition
        guard isViewLoaded, retryUpdate else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.didUpdateViewModel()
            }
            retryUpdate = false
            return
        }
        
        if !contentContainerView.subviews.contains(collectionView) {
            contentContainerView.addSubview(collectionView)
            refreshLayout(in: view)
        }
        
        collectionView.reloadData()
    }
}
