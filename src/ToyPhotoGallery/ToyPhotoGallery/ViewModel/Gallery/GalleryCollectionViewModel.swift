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
    var networkSessionInterface:NetworkSessionInterface { get }
    var errorHandler:ErrorHandlerDelegate { get }
    var timeoutDuration:TimeInterval { get }
    func imageResources(skip: Int, limit: Int, timeoutDuration:TimeInterval, completion:ImageResourceCompletion?)
}

class GalleryCollectionViewModel {
    /// The default page limit size for fetching
    static let defaultPageSize:Int = 20
    
    /// The threshhold of the number of cells remining in the scroll view to trigger fetching the next page
    static let remainingCellsPageLimit:Int = 10

    /// The delegate used to fetch image resources
    weak var resourceDelegate:GalleryCollectionViewModelDelegate?
    
    /// The network session interface given to the cells to fetch UIImage data with
    var networkSessionInterface:NetworkSessionInterface?
    
    /// The viewmodel delegate that receives a signal when the model has updated
    weak var viewModelDelegate:GalleryViewModelDelegate?
    
    /// The data source used for the collection view, containing a protocol of cell models
    var data = [GalleryCollectionViewImageCellModel]()
    
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
        networkSessionInterface = delegate.networkSessionInterface
        data = [GalleryCollectionViewImageCellModel]()
        nextPage(from: delegate, skip: 0, limit: GalleryCollectionViewModel.defaultPageSize)
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
        if indexPath.item > data.count - GalleryCollectionViewModel.remainingCellsPageLimit {
            nextPage(from: resourceDelegate, skip: data.count, limit: GalleryCollectionViewModel.defaultPageSize)
        }
    }
    
    /**
     Fetches the next page from the given resource delegate
     - parameter resourceDelegate: The *GalleryCollectionViewModelDelegate* we use to fetch *ImageResources* from
     - parameter skip: the number of items to skip in the fetch
     - parameter limit: the number of items we want to fetch
     - Returns: void
     */
    func nextPage(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int) {
        if isFetching {
            return
        }
        
        beginFetching(from: resourceDelegate, skip: data.count, limit: GalleryCollectionViewModel.defaultPageSize)
    }
}

// MARK: - Fetch Retries

extension GalleryCollectionViewModel {
    /**
     Starts the fail timer and begins a request for the content between the skip and limit indexes.  The internal callback checks the retry count and makes another attempt if the mad retries has not been reached
     - parameter resourceDelegate: the *GalleryCollectionViewModelDelegate* we use to fetch *ImageResources* from
     - parameter skip: the number of items to skip in the fetch
     - parameter limit: the number of items we want to fetch
     - Returns: void
     */
    func beginFetching(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int) {
        isFetching = true
        failTimer = Timer.scheduledTimer(withTimeInterval: failureDuration, repeats: false, block: { [weak self] (timer) in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.retryFetching() < strongSelf.maxRetryCount {
                strongSelf.beginFetching(from: resourceDelegate, skip: skip, limit: limit)
            } else {
                strongSelf.endFetching()
            }
        })
        
        request(from: resourceDelegate, skip: skip, limit: limit)
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
     - Returns: void
     */
    func request(from resourceDelegate:GalleryCollectionViewModelDelegate, skip:Int, limit:Int) {
        resourceDelegate.imageResources(skip: skip, limit: limit, timeoutDuration:resourceDelegate.timeoutDuration ) { [weak self] (resources) in
            self?.insert(imageResources: resources)
        }
    }
    
    /**
     Creates an array of *GalleryCollectionViewImageCellModel* from an array of *ImageResource* and inserts it to the model's data source.  This method will replace existing data source items if they have been updated more recently, and it sorts the dataSource by the updatedAt property in descending order
     - parameter imageResources: an array of *ImageResource* that will be added to the model's dataSource
     - Returns: void
     */
    func insert(imageResources:[ImageResource]) {
        let imageModels = imageResources.compactMap({ [weak self] (imageResource) -> GalleryCollectionViewImageCellModel? in
            do {
                return try GalleryCollectionViewImageCellModel(with: imageResource, networkSessionInterface:self?.networkSessionInterface)
            } catch {
                self?.resourceDelegate?.errorHandler.report(error)
            }
            return nil
        })
        
        guard imageModels.count > 0 else {
            return
        }
        
        data.append(contentsOf: imageModels)
        viewModelDelegate?.didUpdateViewModel(insertItems: nil, deleteItems: nil, moveItems: nil)
        endFetching()
    }
    
    /*
    func completeFetch(with newDataSource:[GalleryCollectionViewImageCellModel], insertItems:[IndexPath]?, deleteItems:[IndexPath]?, moveItems:[(IndexPath, IndexPath)]?, delegate:GalleryViewModelDelegate?) {
        data = newDataSource
        delegate?.didUpdateViewModel(insertItems: insertItems, deleteItems: deleteItems, moveItems: moveItems)
        endFetching()
    }
     */
}

extension GalleryCollectionViewModel : FlowLayoutConfigurationSizeDelegate {
    func sizeForItemAt(indexPath: IndexPath) -> CGSize {
        let fetchedWidth = data[indexPath.item].imageResource.thumbnailWidth
        let fetchedHeight = data[indexPath.item].imageResource.thumbnailHeight
        
        if fetchedWidth > 0 && fetchedHeight > 0, let containerSize = viewModelDelegate?.containerSize {
            print("\(fetchedWidth)\t\(fetchedHeight)\t\(containerSize)")
            return CGSize(width: fetchedWidth, height: fetchedHeight)
        }
        
        return FlowLayoutVerticalConfiguration().estimatedItemSize
    }
}
