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
    
    /// The viewmodel delegate that receives a signal when the model has updated
    weak var viewModelDelegate:GalleryViewModelDelegate?
    
    /// The data source used for the collection view, containing a protocol of cell models
    var data = SynchronizedArray<ImageResource>(qos: .userInteractive)
    
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

    /**
     Configures the view model with the given delegate, perpares a network session interface for the cells, empties the data source, and fetches the first page
     - parameter delegate: The *GalleryCollectionViewModelDelegate* used to signal that the model has updated
     - Returns: void
     */
    func configure(with delegate:GalleryCollectionViewModelDelegate) {
        data = SynchronizedArray<ImageResource>(qos: .userInteractive)
        nextPage(from: delegate, skip: 0, limit: GalleryCollectionViewModel.defaultPageSize)
    }
    
    /**
     Signal that the collection view is currently dequeuing a cell at the given indexPath.  Used so we know that the layout has been initiated and forwards to a check for the next page
     - parameter indexPath: the collection view's *IndexPath* being dequeued
     - Throws: a *ModelError.MissingResourceModelController* if the resource delegate cannot be found
     - Returns: void
     */
    func viewDidRequestCell(for indexPath:IndexPath) throws {
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
        let readQueue = DispatchQueue(label: "com.secretatomics.toyphotogallery.gallerycollectionviewmodel.read")
        var appendResources = [ImageResource]()
        readQueue.sync {
            appendResources = imageResources
        }
        self.data.append(contentsOf: appendResources)
        
        // TODO: Implement checking for changes
        viewModelDelegate?.didUpdateViewModel(insertItems: nil, deleteItems: nil, moveItems: nil)
        endFetching()
    }
}

extension GalleryCollectionViewModel {
    func calculateItemSize(for thumbnailSize:CGSize, containerSize:CGSize, layout:GalleryCollectionViewLayout, configuration:FlowLayoutConfiguration)->CGSize {
        if configuration.scrollDirection == .horizontal {
            return itemSize(for: thumbnailSize, containerSize: containerSize)
        } else {
            return layout.relative(size: configuration.estimatedItemSize, with: configuration, containerWidth: containerSize.width)
        }
    }
    
    func itemSize(for thumbnailSize:CGSize, containerSize:CGSize)->CGSize {
        var actualSize = containerSize
        
        // Protect against div/0
        guard containerSize.width > 0, containerSize.height > 0 else {
            return CGSize(width: 1, height: 1)
        }
        
        // Landscape and square, else portrait
        if thumbnailSize.width >= thumbnailSize.height {
            let actualHeight = max(min(thumbnailSize.height * containerSize.width / thumbnailSize.width, containerSize.height), 320.0)
            let actualWidth = containerSize.width
            actualSize = CGSize(width: actualWidth, height: actualHeight)
        } else {
            let actualHeight = containerSize.height
            let actualWidth = min(thumbnailSize.width * containerSize.height / thumbnailSize.height, containerSize.width)
            actualSize = CGSize(width: actualWidth, height: actualHeight)
        }
        
        // Making sure we don't break the layout by returning a negative size
        if actualSize.width <= 1 || actualSize.height <= 1 {
            return CGSize(width: 1, height: 1)
        }
        
        return actualSize
    }
}

extension GalleryCollectionViewModel : FlowLayoutConfigurationSizeDelegate {
    func sizeForItemAt(indexPath: IndexPath, layout:GalleryCollectionViewLayout, currentConfiguration:FlowLayoutConfiguration) -> CGSize {
        
        if let containerSize = viewModelDelegate?.containerSize,
            let width = data[indexPath.item]?.thumbnailWidth,
            let height = data[indexPath.item]?.thumbnailHeight,
            width > CGFloat(0.0) && height > CGFloat(0.0) {
            return calculateItemSize(for: CGSize(width:width, height:height), containerSize: containerSize, layout:layout, configuration: currentConfiguration)
        }
        
        return layout.relative(size: currentConfiguration.estimatedItemSize, with: currentConfiguration, containerWidth: currentConfiguration.compWidth)
    }
}
