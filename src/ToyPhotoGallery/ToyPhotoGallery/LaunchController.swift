//
//  LaunchController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Class that launches potentially asynchronous launch services and signals when the expected services
/// have been successfully launched, or sends a failed to launch notification if the time out is reached
class LaunchController {
    /// A remote store controller instance for fetching archived data
    var remoteStoreController:RemoteStoreController?
    
    /// An error handler delegate instance for reporting non-fatal errors
    var errorHandlerDelegate:ErrorHandlerDelegate?
    
    /// A reporting handler delegate instance for reporting behavior analytics
    var reportingHandlerDelegate:ReportingHandlerDelegate?
    
    /// An array of notifications we need to receive before confirming that launch is complete
    var waitForNotifications = Set<Notification.Name>()
    
    /// An array of notification names for those we have already received
    var receivedNotifications = Set<Notification.Name>()
    
    /// The duration, in seconds, that the launch controller waits before timing out
    var timeOutDuration:TimeInterval = 30
    
    /// A timer used to push launch forward if a service is not reached
    var timeOutTimer:Timer?
    
    /// DEBUG flag to print API key encryption bytes to the console
    static let showKeyEncryption = false
    
    /// DEBUG flag to assert FALSE if a warning is received during launch
    let shouldAssertWarnings = false
    
    deinit {
        deregisterForNotifications()
    }
    
    init() {
        #if DEBUG
        show(hidden: [.BugsnagAPIKey, .ParseApplicationId])
        #endif
    }
    
    /**
     Calls the launch method for each service, retains any services that need to stay alive,
     and assigns the notification names we need to receive before posting a launchComplete notification
     - parameter services: An array of LaunchService that need to be warmed up
     - Returns: void
     */
    func launch(services:[LaunchService]) {
        startTimeOutTimer(duration:timeOutDuration)
        assignToInstances(services)
        attempt(services)
    }
}

// MARK: - Launch Control

extension LaunchController {
    /**
     Retains the launch services in self's properties and registers for did complete launch notifications
     - parameter services: an array of LaunchService that need to be warmed up and listened for
     - Returns: void
     */
    func assignToInstances(_ services:[LaunchService]) {
        var notificationNames = [Notification.Name]()
        
        services.forEach { (service) in
            retainIfNecessary(service)
            
            if let name = didLaunchNotificationName(for: service) {
                notificationNames.append(name)
            }
        }
        
        register(for: notificationNames)
    }
    
    /**
     Attempts to launch each of the services in the given array and handle the error if the launch fails
     - parameter services: an array of LaunchService that need to be launched
     - Returns: void
     */
    func attempt(_ services:[LaunchService]) {
        services.forEach { (service) in
            do {
                try service.launch(with:service.launchControlKey?.decoded())
            } catch {
                handle(error: error)
            }
        }
    }
    
    /**
     Increases the reference count for the LaunchService instance by assigning it to a property of self for the given type, and adds a check for services we need to wait for
     - parameter service: A LaunchService that is also another type of controller or delegate that needs to be retained
     - Returns: void
     */
    func retainIfNecessary(_ service: LaunchService) {
        var shouldWaitForDidCompleteNotification = false

        if let controller = service as? RemoteStoreController {
            remoteStoreController = controller
            shouldWaitForDidCompleteNotification = true
        }
        
        if let delegate = service as? ErrorHandlerDelegate {
            errorHandlerDelegate = delegate
            shouldWaitForDidCompleteNotification = true
        }
            
        if let delegate = service as? ReportingHandlerDelegate {
            reportingHandlerDelegate = delegate
            shouldWaitForDidCompleteNotification = true
        }
        
        if shouldWaitForDidCompleteNotification, let name = didLaunchNotificationName(for: service) {
            waitForNotifications.insert(name)
        }
    }
    
    /**
     Adds a notification to the set of received notifications, compares the set to the notifications we are waiting for, and attempts to verify the retained services
     - parameter notification: The notification received
     - Returns: void
     */
    func checkLaunchComplete(with notification:Notification) {
        receivedNotifications.insert(notification.name)
        if verify(received: receivedNotifications, with: waitForNotifications) && verifyRetainedServices(for: waitForNotifications) {
            signalLaunchComplete()
        }
    }
    
    /**
     Checks the notification name for the assigned launch service instance attached to self
     - Returns: The launch service instance assigned to the notification name or nil if none is found
     */
    func instance(for name:Notification.Name)->LaunchService? {
        switch name {
        case Notification.Name.DidLaunchErrorHandler:
            return errorHandlerDelegate
        case Notification.Name.DidLaunchRemoteStore:
            return remoteStoreController
        case Notification.Name.DidLaunchReportingHandler:
            return reportingHandlerDelegate
        default:
            return nil
        }
    }
    
    /**
     Verifies that we have received all of the launch notifications that we expect to receive
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
     Verifies that the received notifications correspond to the instances we expect to retain
     - parameter names: the set of notifications we have expect to have service instances for
     - Returns: True if all the services are found, false if a service is still missing
     */
    func verifyRetainedServices(for expectedNotifications:Set<Notification.Name>) -> Bool {
        for name in expectedNotifications {
            if instance(for: name) == nil {
                return false
            }
        }
        return true
    }
    
    /**
     Signals that launch is complete with the DidCompleteLaunch notification. Resets the notification registration and time out timer for self
     - Returns: void
     */
    func signalLaunchComplete() {
        deregisterForNotifications()
        receivedNotifications = Set<Notification.Name>()
        waitForNotifications = Set<Notification.Name>()
        timeOutTimer?.invalidate()
        timeOutTimer = nil
        NotificationCenter.default.post(name: Notification.Name.DidCompleteLaunch, object: nil)
    }
}

// MARK: - Launch Time Out

extension LaunchController {
    /**
     Starts the time out timer that posts a DidFailLaunch notification after the duration has elapsed
     - parameter duration: the TimeInterval that the class should wait for before posting the failure notification
     - Returns: void
    */
    func startTimeOutTimer(duration:TimeInterval) {
        timeOutTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { [weak self](timer) in
            let notification = Notification(name: Notification.Name.DidFailLaunch, object: nil, userInfo: [NSLocalizedFailureReasonErrorKey:"Launch timed out after \(String(describing:self?.timeOutDuration)) seconds"])
            NotificationCenter.default.post(notification)
        })
    }
}

// MARK: - Error Handling

extension LaunchController {
    /**
     Handles the error with the errorHandlerDelegate if one is present or an instance of DebugErrorHandler if the error handler hasn't been init
     - parameter error: The error that needs to be handled
     - Returns: void
     */
    func handle(error:Error) {
        if errorHandlerDelegate != nil {
            errorHandlerDelegate?.report(error)
        } else {
            let handler = DebugErrorHandler()
            handler.report(error)
            
            if shouldAssertWarnings {
                assert(false)
            }
        }
    }
}

// MARK: - Notifications

extension LaunchController {
    /**
     Removes self from the notification center observers
     - Returns: void
     */
    func deregisterForNotifications(with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self)
    }
    
    /**
     Registers self for the given notification names and assigns the handle(notification:) selector
     - parameter names: an array of Notification.Name for which the instance should be registered
     - Returns: void
     */
    func register(for names:[Notification.Name], with center:NotificationCenter = NotificationCenter.default) {
        deregisterForNotifications()
        for name in names {
            center.addObserver(self, selector:#selector(handle(notification:)), name: name, object: nil)
        }
    }
    
    /**
     Assigns a didLaunch notification name to a LaunchService
     - parameter service: the LaunchService that needs to be checked for completion
     - Returns: a Notification.Name for the LaunchService or nil if none is assigned
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
     - parameter notification: the notification received from the default Notification Center
     - Returns: void
     */
    @objc func handle(notification:Notification) {
        switch notification.name {
        case Notification.Name.DidLaunchErrorHandler:
            fallthrough
        case Notification.Name.DidLaunchRemoteStore:
            fallthrough
        case Notification.Name.DidLaunchReportingHandler:
            checkLaunchComplete(with: notification)
        default:
            handle(error: LaunchError.UnexpectedLaunchNotification)
        }
    }
}

// MARK: - API Key Security
private extension LaunchController {
    #if DEBUG
    /**
     Debug method used to print the bytes for an array of LaunchControllerKey encrypted by the Obfuscator class
     - parameter keys: an array of LaunchControllerKey to print to the console
     - parameter handler: The LogHandlerDelegate responsible for displaying the string
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
