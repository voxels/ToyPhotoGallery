//
//  TestLaunchService.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
@testable import ToyPhotoGallery

/// Used for testing the LaunchController
class TestErrorHandler : ErrorHandlerDelegate {
    var launchControlKey: LaunchControlKey? = nil
    var delayNotification:DispatchTime = DispatchTime(uptimeNanoseconds: 1000)
    var didLaunch = false
    var didReport = true
    
    func launch(with key: String?, with center: NotificationCenter = NotificationCenter.default) throws {
        didLaunch = true
        
        DispatchQueue.main.asyncAfter(deadline: delayNotification) {
            center.post(name: Notification.Name.DidLaunchErrorHandler, object: nil)
        }
    }
    
    func report(_ error: Error) {
        didReport = true
    }
}
