//
//  TestNotificationLaunchController.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
@testable import ToyPhotoGallery

class TestNotificationLaunchController : LaunchController {
    var didReceiveLaunchErrorHandlerNotification = false
    var didReceiveLaunchRemoteStoreNotification = false
    var didReceiveLaunchReportingHandlerNotification = false
    var didReceiveUnexpectedNotification = false
    
    @objc override func handle(notification: Notification) {
        switch notification.name {
        case Notification.Name.DidLaunchErrorHandler:
            didReceiveLaunchErrorHandlerNotification = true
        case Notification.Name.DidLaunchRemoteStore:
            didReceiveLaunchRemoteStoreNotification = true
        case Notification.Name.DidLaunchReportingHandler:
            didReceiveLaunchReportingHandlerNotification = true
        default:
            didReceiveUnexpectedNotification = true
        }
        
        super.handle(notification: notification)
    }
}
