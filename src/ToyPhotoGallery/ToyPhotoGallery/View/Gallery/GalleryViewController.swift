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

    var customConstraints = [NSLayoutConstraint]()

    var retryCount:Int = 0
    var maxRetries:Int = 3
    
    func refresh(with viewModel:GalleryViewModel) {
        let layout = GalleryCollectionViewLayout()
        layout.delegate = self
        let configuredView = galleryCollectionView(with: layout, viewModel:viewModel)
        collectionView = configuredView
    }
    
    func show(previewViewController:PreviewViewController) throws {
        try insert(childViewController: previewViewController, on: self, into: view)
    }
}

extension GalleryViewController {
    func galleryCollectionView(with layout:UICollectionViewLayout, viewModel:GalleryViewModel)->GalleryCollectionView {
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
    
    func previewViewController(for imageResource:ImageResource) throws -> PreviewViewController {
        guard let previewViewController = UIStoryboard.init(name: StoryboardMap.Main.rawValue, bundle: .main).instantiateViewController(withIdentifier: StoryboardMap.ViewController.PreviewViewController.rawValue) as? PreviewViewController else {
            throw ViewError.MissingViewController
        }
        
        let previewViewModel = PreviewViewModel(with:imageResource)
        previewViewController.viewModel = previewViewModel
        return previewViewController
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
    
    override func updateViewConstraints() {
        if customConstraints.count > 0 {
            NSLayoutConstraint.deactivate(customConstraints)
            view.removeConstraints(customConstraints)
        }
        
        customConstraints.removeAll()
        
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

// MARK: - GalleryViewModelDelegate

extension GalleryViewController : GalleryViewModelDelegate {
    func didUpdateViewModel() {
        guard let collectionView = collectionView else {
            viewModel?.resourceModelController.errorHandler.report(ViewError.ViewHierarchyError)
            return
        }
        
        // Preventing a race condition where the model updates before the view is loaded
        guard isViewLoaded else {
            retryCount = retryModelUpdate(with: retryCount)
            return
        }
        
        retryCount = 0
        
        if !contentContainerView.subviews.contains(collectionView) {
            contentContainerView.addSubview(collectionView)
            refreshLayout(in: view)
        }
        
        collectionView.reloadData()
    }
    
    func retryModelUpdate(with countRetries:Int) -> Int {
        if countRetries < maxRetries {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.didUpdateViewModel()
            }
        } else {
            let error = ViewError.MissingView
            viewModel?.resourceModelController.errorHandler.report(error)
            // TODO: Show lockout view?
            assert(false, error.localizedDescription)
        }
        
        return countRetries + 1
    }
}

// MARK: - GalleryCollectionViewLayoutDelegate

extension GalleryViewController : GalleryCollectionViewLayoutDelegate {
    var errorHandler:ErrorHandlerDelegate {
        return viewModel?.resourceModelController.errorHandler ?? DebugErrorHandler()
    }
    
    func previewItem(at indexPath: IndexPath) throws {
        guard let cellModel = collectionView?.model?.dataSource[indexPath.item] as? GalleryCollectionViewImageCellModel else {
            throw ModelError.IncorrectType
        }
        
        let viewController = try previewViewController(for: cellModel.imageResource)
        try show(previewViewController: viewController)
    }
}
