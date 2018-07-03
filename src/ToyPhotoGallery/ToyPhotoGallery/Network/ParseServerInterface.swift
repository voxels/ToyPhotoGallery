//
//  ParseServerInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import Parse

/// A class for wrapping the Parse API service
class ParseServerInterface : RemoteStoreController {
    /// The launch control key that decodes the Parse Application ID
    var launchControlKey: LaunchControlKey? = .ParseApplicationId
    
    /**
     Launches the Parse API and posts a DidLaunchRemoteStore notification when complete
     - Throws: No error is thrown in this class
     - Returns: void
     */
    func launch(with key: String?) throws {
        NotificationCenter.default.post(name: Notification.Name.DidLaunchRemoteStore, object: nil)
    }
}
