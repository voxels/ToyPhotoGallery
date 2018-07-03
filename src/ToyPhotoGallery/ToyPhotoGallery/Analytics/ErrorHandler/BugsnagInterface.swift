//
//  BugsnagInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import Bugsnag

class BugsnagInterface : ErrorHandlerDelegate {
    /// Flag to indicate if Bugsnag should capture session information
    static let kShouldAutoCaptureSessions = true
    
    /// The launch control key for decoding the API key
    var launchControlKey: LaunchControlKey? = .BugsnagAPIKey
    
    /**
     Launches the Bugsnag services with the given API key
     - parameter key: The API key used for launch
     - parameter center: the *NotificationCenter* used to post the *DidLaunchErrorHandler* notification
     - Throws: a 'LaunchError.MissingRequiredKey' if the key is nil
     - Returns: void
     */
    func launch(with key: String?, with center:NotificationCenter = NotificationCenter.default) throws {
        guard let key = key else {
            throw LaunchError.MissingRequiredKey
        }
        
        let configuration = BugsnagInterface.configuration(for: key, shouldCaptureSessions: BugsnagInterface.kShouldAutoCaptureSessions)
        start(with: configuration)
        center.post(name: Notification.Name.DidLaunchErrorHandler, object: nil)
    }
    
    /**
     Reports the non-fatal error to Bugsnag
     - Returns: void
     */
    func report(_ error: Error) {
        Bugsnag.notifyError(error)
    }
}

extension BugsnagInterface {
    /**
     Constructs the default configuration for starting the Bugsnag service
     - parameter key: The API key used to start Bugsnag
     - Returns: A BugsnagConfiguration
     */
    static func configuration(for key:String, shouldCaptureSessions:Bool)->BugsnagConfiguration {
        let configuration = BugsnagConfiguration()
        configuration.apiKey = key
        configuration.shouldAutoCaptureSessions = shouldCaptureSessions
        return configuration
    }
    
    /**
     Starts the Bugsnag service with the given configuation
     - parameter configuration: a BugsnagConfiguation configured for launching the service
     - Returns: void
     */
    func start(with configuration:BugsnagConfiguration) {
        Bugsnag.start(with: configuration)
    }
}
