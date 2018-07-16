//
//  TestRemoteStoreController.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
@testable import ToyPhotoGallery

class TestRemoteStoreController : RemoteStoreController {
    var serverURLString: String = "urlString"
    var defaultQuerySize: Int = 20
    
    var didLaunch = false
    var didFind = false
    var launchControlKey: LaunchControlKey?
    var delayNotification:DispatchTime = DispatchTime(uptimeNanoseconds: 1000)
    
    func launch(with key: String?, with center: NotificationCenter) throws {
        didLaunch = true
        
        DispatchQueue.main.asyncAfter(deadline: delayNotification) {
            center.post(name: Notification.Name.DidLaunchRemoteStore, object: nil)
        }
    }
    
    func find(table: RemoteStoreTableMap, sortBy: String?, skip: Int, limit: Int, on queue: DispatchQueue, errorHandler: ErrorHandlerDelegate, completion: @escaping RawResourceArrayCompletion) {
        didFind = true
        completion([ImageRepositoryTests.imageResourceRawObject])
    }
    
    func count(table: RemoteStoreTableMap, on queue: DispatchQueue, errorHandler: ErrorHandlerDelegate, completion: @escaping ((Int) -> Void)) {
        completion(1)
    }
}
