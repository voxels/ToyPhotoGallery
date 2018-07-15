//
//  GalleryViewController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

struct ContentContainerViewAppearance {
    static let shadowOffset:CGSize = CGSize(width: 0.0, height: -2)
    static let shadowOpacity:Float = 0.1
}

class GalleryViewController: UIViewController {
    var viewModel:GalleryViewModel?
    
    @IBOutlet weak var headingContainerView: UIView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var headingContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headingContainerViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var backingView: UIView!
    @IBOutlet weak var coverCollectionShadowView: UIView!
    @IBOutlet weak var topContentContainerCoverView: UIView!
    @IBOutlet weak var bottomContentContainerCoverView: UIView!
    
    @IBOutlet weak var contentContainerView: UIView!
    var collectionView:GalleryCollectionView?
    
    @IBOutlet weak var previewContainerView: UIView!
    @IBOutlet weak var previewContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var previewContainerViewBottomConstraint: NSLayoutConstraint!
    
    var customConstraints = [NSLayoutConstraint]()
    
    var isPreviewing:Bool {
        return childViewControllers.first as? PreviewViewController != nil
    }

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
        addShadow(view: contentContainerView)
        addShadow(view: coverCollectionShadowView)
        coverCollectionShadowView.backgroundColor = UIColor.appLightGrayBackground()
    }
    
    func addShadow(view:UIView) {
        view.layer.shadowOffset = ContentContainerViewAppearance.shadowOffset
        view.layer.shadowOpacity = ContentContainerViewAppearance.shadowOpacity
    }
    
    func refresh(with viewModel:GalleryViewModel, for direction:UICollectionViewScrollDirection) {
        self.viewModel = viewModel
        let layout = collectionViewLayout(for: direction, errorHandler: viewModel.resourceModelController.errorHandler)
        let collectionViewModel = GalleryCollectionViewModel()
        collectionViewModel.viewModelDelegate = self
        collectionViewModel.resourceDelegate = viewModel.resourceModelController
        collectionViewModel.configure(with: viewModel.resourceModelController)
        let configuredView = galleryCollectionView(with: layout, collectionViewModel:collectionViewModel)
        collectionView = configuredView
    }
    
    func toggle(previewViewController:PreviewViewController, into view:UIView, with indexPath:IndexPath ) throws
    {
        if let existingPreviewViewController = childViewControllers.first as? PreviewViewController {
            let timingDuration:TimeInterval = 0.05 * (FeaturePolice.useSlowAnimation ? 10.0 : 1.0)
            if !existingPreviewViewController.view.isHidden {
                UIView.animate(withDuration: timingDuration, animations: { [weak self] in
                    existingPreviewViewController.view.alpha = 0.0
                    self?.headingContainerView.alpha = 0.0
                }) {[weak self] (didSucceed) in
                    existingPreviewViewController.view.isHidden = true
                    self?.headingContainerView.isHidden = true
                }
            } else {
                existingPreviewViewController.view.isHidden = false
                headingContainerView.isHidden = false
                UIView.animate(withDuration: timingDuration, animations: { [weak self] in
                    existingPreviewViewController.view.alpha = 1.0
                    self?.headingContainerView.alpha = 1.0
                })
            }
        } else {
            try insert(childViewController: previewViewController, on: self, into:view)
            animateCollectionViews(preview: isPreviewing, with:indexPath)
        }
    }
    
    @IBAction func onTapCloseButton(_ sender: Any) {
        let indexPath = collectionView?.indexPathsForVisibleItems.first
        if let child = self.childViewControllers.first {
            remove(childViewController: child)
        }
        
        animateCollectionViews(preview: isPreviewing, with:indexPath)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return isPreviewing ? .lightContent : .default
    }
}

extension GalleryViewController {
    func galleryCollectionView(with layout:GalleryCollectionViewLayout, collectionViewModel:GalleryCollectionViewModel)->GalleryCollectionView {
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

// MARK: - Animation

extension GalleryViewController {
    func animateCollectionViews(preview:Bool, with indexPath:IndexPath?) {
        guard let oldCollectionView = collectionView, let collectionViewModel = oldCollectionView.model else {
            return
        }

        let angle = CGFloat(Measurement(value: 90, unit: UnitAngle.degrees)
            .converted(to: .radians).value)
        closeButton.transform = preview ? CGAffineTransform.init(rotationAngle:angle) : .identity
        closeButton.isHidden = false
        
        var scrollToIndexPath = IndexPath(item: 0, section: 0)
        if let visibleIndexPath = indexPath {
            scrollToIndexPath = visibleIndexPath
        }
        
        let timingDuration:TimeInterval = 0.65 * (FeaturePolice.useSlowAnimation ? 10.0 : 1.0)
        
        let layout = collectionViewLayout(for: preview ? .horizontal : .vertical, errorHandler: oldCollectionView.model?.resourceDelegate?.errorHandler)
        let newCollectionView = galleryCollectionView(with: layout, collectionViewModel:collectionViewModel)
        
        newCollectionView.backgroundColor = preview ? .black : .white
        backingView.backgroundColor = newCollectionView.backgroundColor
        contentContainerView.backgroundColor = newCollectionView.backgroundColor
        headingContainerView.backgroundColor = view.backgroundColor
        topContentContainerCoverView.isHidden = preview
        bottomContentContainerCoverView.backgroundColor = preview ? UIColor.appDarkGrayBackground() : UIColor.appLightGrayBackground()
        coverCollectionShadowView.backgroundColor = preview ? UIColor.appDarkGrayBackground() : UIColor.appLightGrayBackground()
        coverCollectionShadowView.layer.shadowOpacity = preview ? 0.0 : 0.1
        

        var appearance = GalleryCollectionViewImageCellAppearance()
        if preview {
            appearance.backgroundColor = .black
        } else {
            appearance.backgroundColor = .white
        }
        appearance.fadeDuration = timingDuration + 0.25
        
        newCollectionView.cellAppearance = appearance

        newCollectionView.alpha = 1.0

        contentContainerView.insertSubview(newCollectionView, at: 0)
        self.collectionView = newCollectionView
        
        setNeedsStatusBarAppearanceUpdate()
        refreshLayout(in: view)
        
        newCollectionView.performBatchUpdates({
            newCollectionView.reloadData()
        }) { (didSucceed) in
            newCollectionView.scrollToItem(at: scrollToIndexPath, at: preview ? .centeredHorizontally : .centeredVertically, animated: false)
        }
        
        newCollectionView.transform = CGAffineTransform.init(scaleX: 0.85, y: 0.95)
        
        let newCollectionAlphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        newCollectionAlphaAnimation.fromValue = 0.0
        newCollectionAlphaAnimation.toValue = 1.0
        
        let oldCollectionAlphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        oldCollectionAlphaAnimation.fromValue = 1.0
        oldCollectionAlphaAnimation.toValue = 0.0
        
        let headerColor = preview ? UIColor.appDarkGrayBackground() : UIColor.appLightGrayBackground()
        headingContainerView.backgroundColor = headerColor
        view.backgroundColor = headingContainerView.backgroundColor

        let timingFunction = CAMediaTimingFunction(controlPoints: 0.45, -0.4, 0.20, 1.25)
        CATransaction.begin()
        CATransaction.setAnimationDuration(timingDuration)
        CATransaction.setAnimationTimingFunction(timingFunction)
        CATransaction.setCompletionBlock {
            oldCollectionView.removeFromSuperview()
        }
        
        oldCollectionView.alpha = 0.0
        oldCollectionView.layer.add(oldCollectionAlphaAnimation, forKey: #keyPath(CALayer.opacity))
        
        newCollectionView.alpha = 1.0
        newCollectionView.layer.add(newCollectionAlphaAnimation, forKey: #keyPath(CALayer.opacity))
        
        UIView.animate(withDuration: timingDuration, animations: {
            newCollectionView.transform = .identity
        })
        
        let bottomConstant:CGFloat = preview ? -15 : -60
        previewContainerViewBottomConstraint.constant = bottomConstant
        
        if preview {
            for index in 1...4 {
                if let previewViewButtonImageView = previewContainerView.subviews.first?.subviews.first?.viewWithTag(index) {
                    
                    previewViewButtonImageView.alpha = 0.0
                    previewViewButtonImageView.transform = CGAffineTransform.init(scaleX: 0.25, y: 0.25)
                }
            }
        }
        
        view.setNeedsUpdateConstraints()
        UIView.animate(withDuration: timingDuration) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        
        if preview {
            closeButton.alpha = 0.5
            
            UIView.animate(withDuration: timingDuration, animations: { [weak self] in
                self?.headingLabel.alpha = 0.0
                self?.headingLabel.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
                self?.closeButton.transform = .identity
                self?.closeButton.alpha = 1.0
            }) { (didSucceed) in
                if preview {
                    UIView.animate(withDuration: timingDuration / 2.0, animations: { [weak self] in
                        for index in 1...4 {
                            if let previewViewButtonImageView = self?.previewContainerView.subviews.first?.subviews.first?.viewWithTag(index) {
                                previewViewButtonImageView.alpha = 1.0
                                previewViewButtonImageView.transform = .identity
                            }
                        }
                    })
                }
            }
        } else {
            closeButton.alpha = 0.0
            closeButton.isHidden = true
            UIView.animate(withDuration: timingDuration, animations: { [weak self] in
                self?.headingLabel.alpha = 1.0
                self?.headingLabel.transform = .identity
                self?.closeButton.transform = CGAffineTransform.init(rotationAngle:angle)
            }) { (didSucceed) in
                
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
        try toggle(previewViewController: viewController, into: previewContainerView, with:indexPath )
    }
}

