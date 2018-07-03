//
//  TestReportingHandler.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
@testable import ToyPhotoGallery

class TestReportingHandler : ReportingHandlerDelegate {
    var launchControlKey: LaunchControlKey?
    var didLaunch = true
    var delayNotification:DispatchTime = DispatchTime(uptimeNanoseconds: 1000)
    
    func launch(with key: String?, with center: NotificationCenter) throws {
        didLaunch = true
        
        DispatchQueue.main.asyncAfter(deadline: delayNotification) {
            center.post(name: Notification.Name.DidLaunchReportingHandler, object: nil)
        }
    }
}
