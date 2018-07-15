//
//  CacheHandler.swift
//  ToyPhotoGallery
//
//  Created by Michael Edgcumbe on 7/14/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

class CacheHandler : LaunchService {
    static let sharedCache:URLCache = URLCache()
    var launchControlKey: LaunchControlKey?
    
    /// The default number of megabytes for the memory cache
    let defaultMemoryCacheSize:Int = 16
    
    /// The default number of megabytes for the disk cache
    let defaultDiskCacheSize:Int = 32
    
    func launch(with key: String?, with center: NotificationCenter) throws {
        let cache = URLCache(memoryCapacity: bytes(in: defaultMemoryCacheSize), diskCapacity: bytes(in: defaultDiskCacheSize), diskPath: nil)
        URLCache.shared = cache
        
        center.post(name: Notification.Name.DidLaunchSharedCached, object: nil)
    }
    
    func storeResponse(request:URLRequest, response:URLResponse?, data:Data?, completion:((Data?)->Void)?) {
        guard let response = response, let data = data else {
            completion?(nil)
            return
        }
        
        let cachedResponse = CachedURLResponse(response: response, data: data)
        URLCache.shared.storeCachedResponse(cachedResponse, for: request)
    }
    
    func cachedData(for request:URLRequest)->Data? {
        if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
            return cachedResponse.data
        }
        return nil
    }
}

extension CacheHandler {
    func bytes(in megabytes:Int)->Int {
        return megabytes * 1024 * 1024
    }
}
