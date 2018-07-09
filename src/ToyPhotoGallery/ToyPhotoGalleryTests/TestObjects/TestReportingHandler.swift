//
//  TestBucketHandler.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
@testable import ToyPhotoGallery

struct TestReportingHandler : BucketHandlerDelegate {
    var launchControlKey: LaunchControlKey?
    var delayNotification:DispatchTime = DispatchTime(uptimeNanoseconds: 1000)
    
    func launch(with key: String?, with center: NotificationCenter) throws {
        DispatchQueue.main.asyncAfter(deadline: delayNotification) {
            center.post(name: Notification.Name.DidLaunchBucketHandler, object: nil)
        }
    }
}
