//
//  GalleryViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct ContentContainerViewAppearance {
    static let shadowOffset:CGSize = CGSize(width: 0.0, height: -0.5)
    static let shadowOpacity:Float = 0.1
}

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
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var contentContainerView: UIView!
    var collectionView:GalleryCollectionView?

    var customConstraints = [NSLayoutConstraint]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearances()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let collectionView = collectionView, let existingEntries = collectionView.model?.data, existingEntries.count > 0 {
            if contentContainerView.contains(collectionView) {
                collectionView.reloadData()
            } else {
                contentContainerView.addSubview(collectionView)
                refreshLayout(in: view)
                collectionView.reloadData()
            }
        }
    }
    
    func configureAppearances() {
        configure(view: contentContainerView)
    }
    
    func refresh(with viewModel:GalleryViewModel) {
        let configuration = collectionViewLayoutConfiguration(vertical: true)
        let layout = GalleryCollectionViewLayout(with:configuration, errorHandler:viewModel.resourceModelController.errorHandler)
        layout.delegate = self
        let configuredView = galleryCollectionView(with: layout, viewModel:viewModel)
        collectionView = configuredView
    }
    
    func show(previewViewController:PreviewViewController, safeArea:UIEdgeInsets, in frame:CGRect ) throws {
        if #available(iOS 11.0, *) {
            previewViewController.additionalSafeAreaInsets = safeArea
        } else {
            // Fallback on earlier versions
        }
        
        toggle(header: headingContainerView, preview: true)
        try insert(childViewController: previewViewController, on: self, into:view, frame:frame)
        closeButton.isHidden = false
    }
    
    @IBAction func onTapCloseButton(_ sender: Any) {
        if let child = self.childViewControllers.first {
            remove(childViewController: child)
        }
        toggle(header: headingContainerView, preview: false)
    }
}

extension GalleryViewController {
    func galleryCollectionView(with layout:GalleryCollectionViewLayout, viewModel:GalleryViewModel)->GalleryCollectionView {
        if collectionView != nil {
            collectionView?.removeFromSuperview()
            refreshLayout(in: contentContainerView)
            collectionView = nil
        }
        
        let configuredView = GalleryCollectionView(frame: .zero, collectionViewLayout: layout)
        configuredView.translatesAutoresizingMaskIntoConstraints = false
        configuredView.backgroundColor = .white
        configuredView.isDirectionalLockEnabled = true
        
        if #available(iOS 11.0, *) {
            configuredView.contentInsetAdjustmentBehavior = .scrollableAxes
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        let collectionViewModel = GalleryCollectionViewModel()
        collectionViewModel.viewModelDelegate = self
        collectionViewModel.resourceDelegate = viewModel.resourceModelController
        collectionViewModel.configure(with: viewModel.resourceModelController)
        configuredView.model = collectionViewModel
        
        return configuredView
    }
    
    func previewViewController(for indexPath:IndexPath, with galleryCollectionViewModel:GalleryCollectionViewModel) throws -> PreviewViewController {
        guard let previewViewController = UIStoryboard.init(name: StoryboardSchemaMap.Main.rawValue, bundle: .main).instantiateViewController(withIdentifier: StoryboardSchemaMap.ViewController.PreviewViewController.rawValue) as? PreviewViewController else {
            throw ViewError.MissingViewController
        }
        
        let previewViewModel = PreviewViewModel(with: indexPath, galleryCollectionViewModel: galleryCollectionViewModel)
        previewViewController.viewModel = previewViewModel
        previewViewController.view.backgroundColor = previewViewController.defaultBackgroundColor
        return previewViewController
    }
}

// MARK: - Appearance

extension GalleryViewController {
    func configure(view:UIView) {
        if view == contentContainerView {
            view.layer.shadowOffset = ContentContainerViewAppearance.shadowOffset
            view.layer.shadowOpacity = ContentContainerViewAppearance.shadowOpacity
        }
    }
    
    func toggle(header:UIView, preview:Bool) {
        if preview {
            closeButton.isHidden = false
            header.backgroundColor = UIColor.appDarkGrayBackground()
        } else {
            closeButton.isHidden = true
            header.backgroundColor = UIColor.appLightGrayBackground()
        }
    }
    
    func collectionViewLayoutConfiguration(vertical:Bool)->FlowLayoutConfiguration {
        if vertical {
            return FlowLayoutVerticalConfiguration()
        } else {
            var layout = FlowLayoutHorizontalConfiguration()
            layout.sizeDelegate = collectionView?.model
            let finalLayout = layout
            return finalLayout
        }
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
        
        // We need to kick the collection view after the auto layout constraints have been applied
        // But we don't want to do this every time we layout the subviews
        guard let collectionView = collectionView, let model = collectionView.model else {
            return
        }
        if model.completedInitialLayout {
            collectionView.reloadData()
        }
    }
}

// MARK: - GalleryViewModelDelegate

extension GalleryViewController : GalleryViewModelDelegate {
    
    func didUpdateViewModel(insertItems: [IndexPath]?, deleteItems: [IndexPath]?, moveItems: [(IndexPath, IndexPath)]?) {
        guard let collectionView = collectionView else {
            return
        }
        
        if !contentContainerView.subviews.contains(collectionView) {
            contentContainerView.addSubview(collectionView)
            refreshLayout(in: view)
        }
        
        collectionView.reloadData()
    }
}

// MARK: - GalleryCollectionViewLayoutDelegate

extension GalleryViewController : GalleryCollectionViewLayoutDelegate {
    var errorHandler:ErrorHandlerDelegate {
        return viewModel?.resourceModelController.errorHandler ?? DebugErrorHandler()
    }
    
    func previewItem(at indexPath: IndexPath) throws {
        guard let galleryModel = collectionView?.model else {
            throw ModelError.IncorrectType
        }
        
        let viewController = try previewViewController(for: indexPath, with: galleryModel)
        let frame = contentContainerView.frame
        try show(previewViewController: viewController, safeArea: UIEdgeInsets.zero, in: frame)
    }
}
