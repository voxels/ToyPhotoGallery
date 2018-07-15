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
    
    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var previewContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewContainerViewBottomConstraint: NSLayoutConstraint!
    
    
    var customConstraints = [NSLayoutConstraint]()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearances()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let collectionView = collectionView, let existingEntries = collectionView.model?.data, existingEntries.count > 0 {
            if !contentContainerView.contains(collectionView) {
                contentContainerView.addSubview(collectionView)
                refreshLayout(in: view)
            }
            reloadCollectionViewWithoutAnimation()
        }
    }
    
    func configureAppearances() {
        configure(view: contentContainerView)
    }
    
    func refresh(with viewModel:GalleryViewModel) {
        let layout = collectionViewLayout(for: .vertical, errorHandler: viewModel.resourceModelController.errorHandler)
        let configuredView = galleryCollectionView(with: layout, viewModel:viewModel)
        collectionView = configuredView
    }
    
    func show(previewViewController:PreviewViewController, safeArea:UIEdgeInsets, into view:UIView ) throws {
        if #available(iOS 11.0, *) {
            previewViewController.additionalSafeAreaInsets = safeArea
        } else {
            // Fallback on earlier versions
        }
        
        toggle(preview: true)
        try insert(childViewController: previewViewController, on: self, into:view)
        closeButton.isHidden = false
    }
    
    @IBAction func onTapCloseButton(_ sender: Any) {
        if let child = self.childViewControllers.first {
            remove(childViewController: child)
        }
        toggle(preview: false)
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
        configuredView.isPagingEnabled = layout.scrollDirection == .horizontal
        
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
        layout.sizeDelegate = configuredView.model
        
        return configuredView
    }
    
    func previewViewController(for indexPath:IndexPath, with galleryCollectionViewModel:GalleryCollectionViewModel) throws -> PreviewViewController {
        guard let previewViewController = UIStoryboard.init(name: StoryboardSchemaMap.Main.rawValue, bundle: .main).instantiateViewController(withIdentifier: StoryboardSchemaMap.ViewController.PreviewViewController.rawValue) as? PreviewViewController else {
            throw ViewError.MissingViewController
        }
        
        previewViewController.view.backgroundColor = previewViewController.defaultBackgroundColor
        return previewViewController
    }
    
    func collectionViewLayout(for direction:UICollectionViewScrollDirection, errorHandler:ErrorHandlerDelegate?) -> GalleryCollectionViewLayout {
        let configuration = collectionViewLayoutConfiguration(direction: direction)
        let layout = GalleryCollectionViewLayout(with:configuration, errorHandler:errorHandler)
        layout.delegate = self
        layout.sizeDelegate = collectionView?.model
        return layout
    }
    
    func collectionViewLayoutConfiguration(direction:UICollectionViewScrollDirection)->FlowLayoutConfiguration {
        if direction == .vertical {
            return FlowLayoutVerticalConfiguration()
        } else {
            return FlowLayoutHorizontalConfiguration()
        }
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
    
    func toggle(preview:Bool) {
        guard let oldCollectionView = collectionView, let viewModel = viewModel else {
            return
        }
        
        let timingDuration:TimeInterval = 0.35 * (FeaturePolice.useSlowAnimation ? 10.0 : 1.0)
        
        let layout = collectionViewLayout(for: preview ? .horizontal : .vertical, errorHandler: oldCollectionView.model?.resourceDelegate?.errorHandler)
        let newCollectionView = galleryCollectionView(with: layout, viewModel:viewModel)
        newCollectionView.backgroundColor = preview ? .black : .white
        contentContainerView.backgroundColor = newCollectionView.backgroundColor
        newCollectionView.alpha = 1.0
        contentContainerView.addSubview(newCollectionView)
        self.collectionView = newCollectionView
        newCollectionView.reloadData()
        refreshLayout(in: view)
        
        newCollectionView.transform = CGAffineTransform.init(scaleX: 0.85, y: 0.95)
        
        let newCollectionAlphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        newCollectionAlphaAnimation.fromValue = 0.0
        newCollectionAlphaAnimation.toValue = 1.0
        
        let oldCollectionAlphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        oldCollectionAlphaAnimation.fromValue = 1.0
        oldCollectionAlphaAnimation.toValue = 0.0
        
        let headerBackgroundAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.backgroundColor))
        let currentColor = !preview ? UIColor.appDarkGrayBackground() : UIColor.appLightGrayBackground()
        let headerColor = preview ? UIColor.appDarkGrayBackground() : UIColor.appLightGrayBackground()
        headerBackgroundAnimation.fromValue = currentColor
        headerBackgroundAnimation.toValue = headerColor
        
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.45, -0.4, 0.20, 1.25)
        CATransaction.begin()
        CATransaction.setAnimationDuration(timingDuration)
        CATransaction.setAnimationTimingFunction(timingFunction)
        CATransaction.setCompletionBlock {
            oldCollectionView.removeFromSuperview()
        }
        headingContainerView.backgroundColor = headerColor
        headingContainerView.layer.add(headerBackgroundAnimation, forKey: #keyPath(CALayer.backgroundColor))
        
        oldCollectionView.alpha = 0.0
        oldCollectionView.layer.add(oldCollectionAlphaAnimation, forKey: #keyPath(CALayer.opacity))
        
        newCollectionView.alpha = 1.0
        newCollectionView.layer.add(newCollectionAlphaAnimation, forKey: #keyPath(CALayer.opacity))
        
        UIView.animate(withDuration: timingDuration) {
            newCollectionView.transform = .identity
        }
        
        let bottomConstant:CGFloat = preview ? -15 : -45
        previewContainerViewBottomConstraint.constant = bottomConstant
        view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: timingDuration) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
        if preview {
            closeButton.alpha = 1.0
            
            UIView.animate(withDuration: timingDuration) { [weak self] in
                self?.headingLabel.alpha = 0.0
                self?.headingLabel.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
                self?.closeButton.transform = .identity                
            }
        } else {
            let angle = CGFloat(Measurement(value: 90, unit: UnitAngle.degrees)
                .converted(to: .radians).value)
            UIView.animate(withDuration: timingDuration, animations: { [weak self] in
                self?.headingLabel.alpha = 1.0
                self?.headingLabel.transform = .identity
                self?.closeButton.transform = CGAffineTransform.init(rotationAngle:angle )
            }) { [weak self] (didSucceed) in
                self?.closeButton.alpha = 0.0
            }
        }
        CATransaction.commit()
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
    
    func reloadCollectionViewWithoutAnimation() {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        collectionView?.reloadData()
        CATransaction.commit()
    }
}

// MARK: - GalleryViewModelDelegate

extension GalleryViewController : GalleryViewModelDelegate {
    var containerSize: CGSize {
        guard let collectionView = collectionView else {
            return CGSize.zero
        }
        
        return collectionView.bounds.size
    }
    
    func didUpdateViewModel(insertItems: [IndexPath]?, deleteItems: [IndexPath]?, moveItems: [(IndexPath, IndexPath)]?) {
        guard let collectionView = collectionView else {
            return
        }
        
        if isViewLoaded, !contentContainerView.subviews.contains(collectionView) {
            contentContainerView.addSubview(collectionView)
            refreshLayout(in: view)
        }
        
        reloadCollectionViewWithoutAnimation()
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
        try show(previewViewController: viewController, safeArea: UIEdgeInsets.zero, into: previewContainerView)
    }
}
