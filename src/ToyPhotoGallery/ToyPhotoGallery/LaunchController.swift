//
//  LaunchController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

/// Class that launches potentially asynchronous launch services and signals when the expected services
/// have been successfully launched, or sends a failed to launch notification if the time out is reached
class LaunchController {
    /// The gallery model we need to construct for launch
    var galleryModel:GalleryViewModel?
    
    /// The resource model we use to create the gallery model
    var resourceModel:ResourceModelController?
    
    /// An array of notifications we need to receive before confirming that launch is complete
    var waitForNotifications = Set<Notification.Name>()
    
    /// An array of notification names for those we have already received
    var receivedNotifications = Set<Notification.Name>()
    
    /// The duration, in seconds, that the launch controller waits before timing out
    var timeOutDuration:TimeInterval = 30
    
    /// A timer used to push launch forward if a service is not reached
    var timeOutTimer:Timer?
    
    /// Flag to indicate of the error reporting service has been launched
    var didLaunchErrorHandler = false
    
    /// We use the debug error handler until we have the Bugsnag service
    var currentErrorHandler:ErrorHandlerDelegate {
        return didLaunchErrorHandler ? BugsnagInterface() : DebugErrorHandler()
    }
    
    /// DEBUG flag to print API key encryption bytes to the console
    static let showKeyEncryption = false
    
    /// DEBUG flag to assert FALSE if a warning is received during launch
    let shouldAssertWarnings = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    init() {
        #if DEBUG
        show(hidden: [.BugsnagAPIKey, .ParseApplicationId])
        #endif
    }
    
    /**
     Calls the launch method for each service, retains any services that need to stay alive,
     and assigns the notification names we need to receive before posting a *DidCompleteLaunch* notification
     - parameter services: An array of *LaunchService* that need to be launched
     - parameter modelController: the *ResourceModel* used to create the gallery model
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func launch(services:[LaunchService],for modelController:ResourceModelController, with center:NotificationCenter = NotificationCenter.default) {
        resourceModel = modelController
        startTimeOutTimer(duration:timeOutDuration, with:center)
        waitForLaunchNotifications(for: services, with:center)
        attempt(services, with:center)
    }
}

// MARK: - Launch Control

extension LaunchController {
    /**
     Registers for *DidCompleteLaunch* notification for each service in the given array
     - parameter services: an array of *LaunchService* that should be checked for waiting to complete the launch
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func waitForLaunchNotifications(for services:[LaunchService], with center:NotificationCenter = NotificationCenter.default) {
        services.forEach { (service) in
            waitIfNecessary(service, with:center)
        }
    }
    
    /**
     Attempts to launch each of the services in the given array and handle the error if the launch fails
     - parameter services: an array of *LaunchService* that need to be launched
     - parameter center: the *NotificationCenter* used to post the *DidLaunch...* notification
     - Returns: void
     */
    func attempt(_ services:[LaunchService], with center:NotificationCenter = NotificationCenter.default) {
        services.forEach { (service) in
            do {
                try service.launch(with:service.launchControlKey?.decoded(), with:center)
            } catch {
                let errorHandler:ErrorHandlerDelegate = didLaunchErrorHandler ? BugsnagInterface() : DebugErrorHandler()
                handle(error: error, with:errorHandler)
            }
        }
    }
    
    /**
     Adds a check for services that the controller should wait for before sending a final *DidCompleteLaunch* notification
     - parameter service: A *LaunchService* that needs to be checked for delaying the final *DidCompleteLaunch* notification
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func waitIfNecessary(_ service: LaunchService, with center:NotificationCenter = NotificationCenter.default) {
        var shouldWaitForDidCompleteNotification = false

        if service is RemoteStoreController {
            shouldWaitForDidCompleteNotification = true
        }
        
        if service is ErrorHandlerDelegate {
            shouldWaitForDidCompleteNotification = true
        }
            
        if service is ReportingHandlerDelegate {
            shouldWaitForDidCompleteNotification = true
        }
        
        if shouldWaitForDidCompleteNotification, let name = didLaunchNotificationName(for: service) {
            waitForNotifications.insert(name)
            register(for: name, with:center)
        }
    }
    
    /**
     Adds a notification to the set of received notifications and compares the set to the notifications we are waiting for to the notifications we have received.  If the *receivedNotifications* are verified against the *waitForNotifications*, the *galleryModel* is constructed.
     - parameter notification: The notification received
     - Throws: a *LaunchError.MissingRemoteStoreController* if the remote store controller has not been init by this point
     - Returns: void
     */
    func checkLaunchComplete(with notification:Notification) throws {
        receivedNotifications.insert(notification.name)
        if verify(received: receivedNotifications, with: waitForNotifications) {
            if let model = resourceModel {
                galleryModel = GalleryViewModel(with: model, delegate: self)
                guard let storeController = resourceModel?.remoteStoreController else {
                    throw LaunchError.MissingRemoteStoreController
                }
                galleryModel?.buildDataSource(from: storeController)
            }
        }
    }
    
    /**
     Verifies that we have received all of the expected *DidCompleteLaunch* notifications
     - parameter receivedNotifications: a set of the notifications the class has received since launch
     - parameter expectedNotifications: a set of the notifications that we expect to receive before launch is complete
     - Returns: True if all the expected notifications have been received, false if an expected notification hasn't been received
     */
    func verify(received receivedNotifications:Set<Notification.Name>, with expectedNotifications:Set<Notification.Name>)->Bool {
        for expected in expectedNotifications {
            if !receivedNotifications.contains(expected) {
                return false
            }
        }
        
        return true
    }
    
    /**
     
     */
    
    /**
     Signals that launch is complete with the *DidCompleteLaunch* notification. Resets the notification registration and time out timer for self
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
     */
    func signalLaunchComplete(with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self)
        receivedNotifications = Set<Notification.Name>()
        waitForNotifications = Set<Notification.Name>()
        timeOutTimer?.invalidate()
        timeOutTimer = nil
        center.post(name: Notification.Name.DidCompleteLaunch, object: nil)
    }
}

// MARK: - Launch Time Out

extension LaunchController {
    /**
     Starts the time out timer that posts a *DidFailLaunch* notification after the duration has elapsed
     - parameter duration: the TimeInterval that the class should wait for before posting the failure notification
     - parameter center: the *NotificationCenter* to deregister and post *DidCompleteLaunch* on
     - Returns: void
    */
    func startTimeOutTimer(duration:TimeInterval, with center:NotificationCenter = NotificationCenter.default) {
        timeOutTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { [weak self] (timer) in
            let notification = Notification(name: Notification.Name.DidFailLaunch, object: nil, userInfo: [NSLocalizedFailureReasonErrorKey:"Launch timed out after \(String(describing:self?.timeOutDuration)) seconds"])
            center.post(notification)
        })
    }
}

// MARK: - Error Handling

extension LaunchController {
    /**
     Handles the error with the *errorHandlerDelegate* if one is present or an instance of *DebugErrorHandler* if the error handler hasn't been init
     - parameter error: The error that needs to be handled
     - parameter handler: The error handler reporting the error
     - Returns: void
     */
    func handle(error:Error, with handler:ErrorHandlerDelegate?) {
        guard let handler = handler else {
            let debugHandler = DebugErrorHandler()
            debugHandler.report(error)
            
            if shouldAssertWarnings {
                assert(false)
            }
            return
        }
        
        handler.report(error)
    }
}

// MARK: - Notifications

extension LaunchController {
    /**
     Removes self from the notification center observers
     - parameter name: The notification name to deregister
     - parameter center: The notification center to deregister from
     - Returns: void
     */
    func deregisterForNotification(_ name:Notification.Name, with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self, name: name, object: nil)
    }
    
    /**
     Registers self for the given notification names and assigns the handle(notification:) selector
     - parameter name: The notification name to register
     - parameter center: The notification center to register with
     - Returns: void
     */
    func register(for name:Notification.Name, with center:NotificationCenter = NotificationCenter.default) {
        deregisterForNotification(name, with:center)
        center.addObserver(self, selector:#selector(handle(notification:)), name: name, object: nil)
    }
    
    /**
     Assigns a *didLaunch...* notification name to a LaunchService
     - parameter service: the *LaunchService* that needs to be checked for completion
     - Returns: a Notification.Name for the *LaunchService* or nil if none is assigned
     */
    func didLaunchNotificationName(for service:LaunchService)->Notification.Name? {
        if service is RemoteStoreController {
            return Notification.Name.DidLaunchRemoteStore
        } else if service is ErrorHandlerDelegate {
            return Notification.Name.DidLaunchErrorHandler
        } else if service is ReportingHandlerDelegate {
            return Notification.Name.DidLaunchReportingHandler
        }
        
        return nil
    }
    
    /**
     Handles incoming notifications
     - parameter notification: the notification received from the default *NotificationCenter*
     - Returns: void
     */
    @objc func handle(notification:Notification) {
        switch notification.name {
        case Notification.Name.DidLaunchErrorHandler:
            didLaunchErrorHandler = true
            fallthrough
        case Notification.Name.DidLaunchRemoteStore:
            fallthrough
        case Notification.Name.DidLaunchReportingHandler:
            do {
                try checkLaunchComplete(with: notification)
            } catch {
                handle(error: error, with: currentErrorHandler)
            }
        default:
            handle(error: LaunchError.UnexpectedLaunchNotification, with:currentErrorHandler)
        }
    }
}

// MARK: - GalleryViewModelDelegate

extension LaunchController : GalleryViewModelDelegate {
    func didUpdateModel() {
        signalLaunchComplete()
    }
}

// MARK: - View

extension LaunchController {
    func showGalleryView(in rootViewController:UINavigationController, with model:GalleryViewModel) {
        // TODO: show gallery view
        print("show gallery view")
    }
    
    func showReachabilityView(in rootViewController:UINavigationController) {
        // TODO: show reachability view
        print("show reachability view")
    }
    
    static func showFatalAlert(with message:String, in viewController:UIViewController?) {
        guard let viewController = viewController else {
            // No further recourse.  The app is dead.
            fatalError("Missing root window view controller")
        }
        
        let alertController = UIAlertController(title: "Fatal Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            fatalError("turtles")
        }
        alertController.addAction(okAction)
        alertController.show(viewController, sender: nil)
    }
}


// MARK: - API Key Security
private extension LaunchController {
    #if DEBUG
    /**
     Debug method used to print the bytes for an array of *LaunchControllerKey* encrypted by the Obfuscator class
     - parameter keys: an array of *LaunchControllerKey* to print to the console
     - parameter handler: The *LogHandlerDelegate* responsible for displaying the string
     */
    func show(hidden keys:[LaunchControlKey], with handler:LogHandlerDelegate = DebugLogHandler()) {
        if !LaunchController.showKeyEncryption {
            return
        }
        
        for key in keys {
            let bytes = key.generate(with:Obfuscator.saltObjects())
            handler.console("Key for \(key):")
            handler.console("\t\(String(describing:bytes))")
            handler.console("Decoded string:")
            handler.console(key.decoded())
            handler.console("\n\n")
        }
    }
    #endif
}

