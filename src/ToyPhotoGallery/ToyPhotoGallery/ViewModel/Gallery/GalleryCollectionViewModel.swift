//
//  GalleryCollectionViewModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Protocol to fetch the image resources for the model and get an error handler if necessary
protocol GalleryCollectionViewModelDelegate : class {
    var errorHandler:ErrorHandlerDelegate { get }
    func imageResources(skip:Int, limit:Int, completion:ImageResourceCompletion?)
}

class GalleryCollectionViewModel {
    /// The default page limit size for fetching
    static let defaultPageSize:Int = 30
    
    /// The threshhold of the number of cells remining in the scroll view to trigger fetching the next page
    static let remainingCellsPageLimit:Int = 10

    /// The delegate used to fetch image resources
    weak var resourceDelegate:GalleryCollectionViewModelDelegate? {
        didSet {
            if let delegate = resourceDelegate {
                configure(with: delegate)
            }
        }
    }
    
    /// The network session interface given to the cells to fetch UIImage data with
    var networkSessionInterface:NetworkSessionInterface?
    
    /// The viewmodel delegate that receives a signal when the model has updated
    weak var viewModelDelegate:GalleryViewModelDelegate?
    
    /// The data source used for the collection view, containing a protocol of cell models
    var dataSource = [GalleryCollectionViewCellModel]()
    
    /// A flag to determine if the collection view is currently fetching image resources
    var isFetching = false
    
    /// A timer used to put a limit on how long we wait for the resource model controller to fetch
    var failTimer:Timer?
    
    /// The duration to wait before failing a fetch from the local store
    var failureDuration:TimeInterval = 30
    
    /// The current number of fetch retries
    var retryCount:Int = 0
    
    /// The maximum number of retries to take
    var maxRetryCount: Int = 3
    
    /// Flag that indicates that the collection view has called cellForItem: at least once
    /// We are using it because we need to make sure reloadData is called AFTER auto layout
    /// has applied the constraints for the collection, but not every time we layout the VC's subviews
    var completedInitialLayout = false

    /**
     Configures the view model with the given delegate, perpares a network session interface for the cells, empties the data source, and fetches the first page
     - parameter delegate: The *GalleryCollectionViewModelDelegate* used to signal that the model has updated
     - Returns: void
     */
    func configure(with delegate:GalleryCollectionViewModelDelegate) {
        networkSessionInterface = NetworkSessionInterface(with: delegate.errorHandler)
        dataSource = [GalleryCollectionViewCellModel]()
        nextPage(from: delegate, skip: 0, limit: GalleryCollectionViewModel.defaultPageSize, completion:nil)
    }
    
    /**
     Signal that the collection view is currently dequeuing a cell at the given indexPath.  Used so we know that the layout has been initiated and forwards to a check for the next page
     - parameter indexPath: the collection view's *IndexPath* being dequeued
     - Throws: a *ModelError.MissingResourceModelController* if the resource delegate cannot be found
     - Returns: void
     */
    func viewDidRequestCell(for indexPath:IndexPath) throws {
        completedInitialLayout = true
        guard let delegate = resourceDelegate else {
            throw ModelError.MissingResourceModelController
        }
        checkForNextPage(with: indexPath, with:delegate)
    }
    
    /**
     Performs a check if we should ask the resource delegate for another page, and calls *nextPage* if so
     - parameter indexPath: the *IndexPath* we are currently evaluating for remaining page content
     - parameter resourceDelegate: the *GalleryCollectionViewModelDelegate* we use to fetch *ImageResources* from
     - Returns: void
     */
    func checkForNextPage(with indexPath:IndexPath, with resourceDelegate:GalleryCollectionViewModelDelegate) {
        if indexPath.item > dataSource.count - GalleryCollectionViewModel.remainingCellsPageLimit {
            nextPage(from: resourceDelegate, skip: dataSource.count, limit: GalleryCollectionViewModel.defaultPageSize, completion:nil)
        }
    }
    
    /**
     Fetches the next page from the given resource delegate
     - parameter resourceDelegate: The *GalleryCollectionViewModelDelegate* we use to fetch *ImageResources* from
     - parameter skip: the number of items to skip in the fetch
     - parameter limit: the number of items we want to fetch
     - parameter completion: A callback which indicates if the fetch succeeded
     - Returns: void
     */
    func nextPage(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int, completion:((Bool)->Void)?) {
        if isFetching {
            return
        }
        
        beginFetching(from: resourceDelegate, skip: dataSource.count, limit: GalleryCollectionViewModel.defaultPageSize, completion:completion)
    }
}

// MARK: - Fetch Retries

extension GalleryCollectionViewModel {
    /**
     Starts the fail timer and begins a request for the content between the skip and limit indexes.  The internal callback checks the retry count and makes another attempt if the mad retries has not been reached
     - parameter resourceDelegate: the *GalleryCollectionViewModelDelegate* we use to fetch *ImageResources* from
     - parameter skip: the number of items to skip in the fetch
     - parameter limit: the number of items we want to fetch
     - parameter completion: A callback which indicates if the fetch succeeded
     - Returns: void
     */
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

    /// Increments the retry count and sets the tools for another attempt
    func retryFetching()->Int {
        failTimer = nil
        isFetching = false
        retryCount += 1
        return retryCount
    }
    
    /// Resets the count and tools for retries
    func endFetching() {
        failTimer?.invalidate()
        failTimer = nil
        isFetching = false
        retryCount = 0
    }
}

// MARK: - Resource Request

extension GalleryCollectionViewModel {
    /**
     Sends a request to the *GalleryCollectionViewModelDelegate* for the content between the skip and limit indexes.  Updates the data source
     - parameter resourceDelegate: the *GalleryCollectionViewModelDelegate* we use to fetch *ImageResources* from
     - parameter skip: the number of items to skip in the fetch
     - parameter limit: the number of items we want to fetch
     - parameter completion: A callback which indicates if the fetch succeeded
     - Returns: void
     */
    func request(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int, completion:((Bool)->Void)?) {
        resourceDelegate.imageResources(skip: skip, limit: limit) { [weak self] (resources) in
            self?.append(imageResources: resources, completion: completion)
        }
    }
    
    /**
     Creates an array of *GalleryCollectionViewImageCellModel* from an array of *ImageResource* and appends it to the model's data source
     - parameter imageResources: an array of *ImageResource* that will be added to the model's dataSource
     - parameter completion: A callback which indicates if the fetch succeeded
     - Returns: void
     */
    func append(imageResources:[ImageResource], completion:((Bool)->Void)?) {
        let imageModels = imageResources.compactMap({ [weak self] (imageResource) -> GalleryCollectionViewImageCellModel? in
            do {
                return try GalleryCollectionViewImageCellModel(with: imageResource, networkSessionInterface:self?.networkSessionInterface)
            } catch {
                self?.resourceDelegate?.errorHandler.report(error)
            }
            return nil
        })
        
        guard imageModels.count > 0 else {
            completion?(false)
            return
        }
        
        dataSource.append(contentsOf: imageModels)
        viewModelDelegate?.didUpdateViewModel()
        endFetching()
        completion?(true)
    }
}
