//
//  NetworkSessionInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/6/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Class used to wrap URLSession for handling data and download session tasks
class NetworkSessionInterface : NSObject {
    
    /// The error handler delegate used to report non-fatal errors
    let errorHandler:ErrorHandlerDelegate
    
    /// The bucket handler for fetching AWS specific URLs
    lazy var bucketHandler:AWSBucketHandler = AWSBucketHandler()
    
    init(with errorHandler:ErrorHandlerDelegate) {
        self.errorHandler = errorHandler
        super.init()
    }
    
    /**
     Uses a one-off URLSession, NOT the interface's session, to perform a quick fetch of a data task for the given URL
     - parameter url: the URL being fetched
     - parameter queue: The queue that the fetch should be returned on
     - parameter timeout: The number of seconds before timing out the request
     - parameter cachePolicy: The *URLRequest.CachePolicy* for handling the request.  Defaults to *.returnCacheDataEleseLoad*.
     - parameter cacheHandler: An optional  *CacheHandler* used to archive the response
     - parameter completion: a callback used to pass through the optional fetched *Data*
     - Returns: void
     */
    func fetch(url:URL, on queue:DispatchQueue?, timeout:TimeInterval, cachePolicy:URLRequest.CachePolicy = .returnCacheDataElseLoad, cacheHandler:CacheHandler?,  completion:@escaping (Data?)->Void) {
        // Using a default session here may crash because of a potential bug in Foundation.
        // Ephemeral and Shared sessions don't crash.
        // See: https://forums.developer.apple.com/thread/66874
        
        var fetchQueue:DispatchQueue = .main
        if let otherQueue = queue {
            fetchQueue = otherQueue
        }
        
        if AWSBucketHandler.isAWS(url: url) {
            bucketHandler.fetchWithAWS(url: url, on:fetchQueue, cacheHandler:cacheHandler, with:errorHandler, completion: completion)
            return
        }
        
        // We are handling the cacheing ourselves
        let session = URLSession(configuration: .ephemeral)
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeout)
        
        if let data = cacheHandler?.cachedData(for: request) {
            completion(data)
            return
        }
        
        let taskCompletion:((Data?, URLResponse?, Error?) -> Void) = { [weak self] (data, response, error) in
            if let e = error {
                fetchQueue.async {
                    self?.errorHandler.report(e)
                    completion(nil)
                }
                return
            }
            
            fetchQueue.async {
                if let handler = cacheHandler {
                    handler.storeResponse(request:request, response: response, data: data, completion: completion)
                } else {
                    completion(data)
                }
            }
        }
        
        let task = session.dataTask(with: request, completionHandler: taskCompletion)
        task.resume()
    }
}
