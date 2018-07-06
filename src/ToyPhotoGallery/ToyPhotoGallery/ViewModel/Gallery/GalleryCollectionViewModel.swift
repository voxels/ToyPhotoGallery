//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol GalleryCollectionViewModelDelegate : class {
    var errorHandler:ErrorHandlerDelegate { get }
    func imageResources(skip:Int, limit:Int, completion:ImageResourceCompletion?)
}

class GalleryCollectionViewModel {
    static let defaultPageSize:Int = 30
    static let remainingCellsPageLimit:Int = 10
    
    weak var resourceDelegate:GalleryCollectionViewModelDelegate? {
        didSet {
            if let delegate = resourceDelegate {
                refresh(with: delegate)
            }
        }
    }
    
    weak var viewModelDelegate:GalleryViewModelDelegate?
    
    var dataSource = [GalleryCollectionViewCellModel]()
    
    var isFetching = false
    var failTimer:Timer?
    var failureDuration:TimeInterval = 30
    var retryCount:Int = 0
    var maxRetryCount: Int = 3
    
    /// Flag that indicates that the collection view has called cellForItem: at least once
    /// We are using it because we need to make sure reloadData is called AFTER auto layout
    /// has applied the constraints for the collection, but not every time we layout the VC's subviews
    var completedInitialLayout = false

    func refresh(with delegate:GalleryCollectionViewModelDelegate) {
        dataSource = [GalleryCollectionViewCellModel]()
        nextPage(from: delegate, skip: 0, limit: GalleryCollectionViewModel.defaultPageSize, completion:nil)
    }
    
    func viewDidRequestCell(for indexPath:IndexPath) throws {
        completedInitialLayout = true
        guard let delegate = resourceDelegate else {
            throw ModelError.MissingResourceModelController
        }
        checkForNextPage(with: indexPath, with:delegate)
    }
    
    func checkForNextPage(with indexPath:IndexPath, with resourceDelegate:GalleryCollectionViewModelDelegate) {
        if indexPath.item > dataSource.count - GalleryCollectionViewModel.remainingCellsPageLimit {
            nextPage(from: resourceDelegate, skip: dataSource.count, limit: GalleryCollectionViewModel.defaultPageSize, completion:nil)
        }
    }
    
    func nextPage(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int, completion:((Bool)->Void)?) {
        if isFetching {
            return
        }
        
        beginFetching(from: resourceDelegate, skip: dataSource.count, limit: GalleryCollectionViewModel.defaultPageSize, completion:completion)
    }
}

// MARK: - Fetch Retries

extension GalleryCollectionViewModel {
    func beginFetching(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int, completion:((Bool)->Void)?) {
        isFetching = true
        failTimer = Timer.scheduledTimer(withTimeInterval: failureDuration, repeats: false, block: { [weak self] (timer) in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.retryFetching() < strongSelf.maxRetryCount {
                strongSelf.beginFetching(from: resourceDelegate, skip: skip, limit: limit, completion: completion)
            } else {
                strongSelf.endFetching()
            }
        })
        
        request(from: resourceDelegate, skip: skip, limit: limit, completion: completion)
    }

    func retryFetching()->Int {
        failTimer = nil
        isFetching = false
        retryCount += 1
        return retryCount
    }
    
    func endFetching() {
        failTimer?.invalidate()
        failTimer = nil
        isFetching = false
        retryCount = 0
    }
}

// MARK: - Resource Request

extension GalleryCollectionViewModel {
    func request(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int, completion:((Bool)->Void)?) {
        resourceDelegate.imageResources(skip: skip, limit: limit) { [weak self] (resources) in
            let imageModels = resources.compactMap({ [weak self] (imageResource) -> GalleryCollectionViewImageCellModel? in
                do {
                    return try GalleryCollectionViewImageCellModel(with: imageResource)
                } catch {
                    self?.resourceDelegate?.errorHandler.report(error)
                }
                return nil
            })
            
            guard imageModels.count > 0 else {
                completion?(false)
                return
            }
            
            self?.dataSource.append(contentsOf: imageModels)
            self?.viewModelDelegate?.didUpdateViewModel()
            self?.endFetching()
            completion?(true)
        }
    }
}
