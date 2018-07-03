//
//  AppDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var launchController:LaunchController?
    
    deinit {
        deregisterForNotifications()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Registers for *DidCompleteLaunch* notification
        registerForLaunchNotifications()
        
        // Start launch services
        launchController = LaunchController()
        let bugsnagService = BugsnagInterface()
        let parseService = ParseInterface()
        launchController?.launch(services: [bugsnagService, parseService])
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }
}


// MARK: - Notifications

extension AppDelegate {
    /**
     Deregisters self for all notifications from a given *NotificationCenter*
     - parameter center: The *NotificationCenter* to deregister from
     - Returns: void
     */
    func deregisterForNotifications(with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self)
    }
    
    /**
     Deregisters self for all launch notifications from the given *NotificationCenter*
     - parameter center: The *NotificationCenter* to deregister from
     - Returns: void
     */
    func deregisterForLaunchNotifications(with center:NotificationCenter = NotificationCenter.default) {
        center.removeObserver(self, name: Notification.Name.DidCompleteLaunch, object: nil)
        center.removeObserver(self, name: Notification.Name.DidFailLaunch, object: nil)
    }
    
    /**
     Registers self for the complete and fail launch notifications
     - parameter center: The *NotificationCenter* to register with from
     - Returns: void
     */
    func registerForLaunchNotifications(with center:NotificationCenter = NotificationCenter.default) {
        deregisterForLaunchNotifications()
        center.addObserver(self, selector: #selector(handleLaunchDidComplete(sender:)), name: Notification.Name.DidCompleteLaunch, object: nil)
        center.addObserver(self, selector: #selector(handleLaunchDidFail(sender:)), name: Notification.Name.DidFailLaunch, object: nil)
    }
    
    /**
     Handles the launch did complete notification
     - parameter notification: The launch notification
     - Returns: void
     */
    @objc func handleLaunchDidComplete(sender:Notification) {
        #if DEBUG
        let handler = DebugLogHandler()
        handler.console("Launch Did COMPLETE")
        #endif
        
        deregisterForLaunchNotifications()
    }
    
    /**
     Handles the launch did fail notification
     - parameter: The launch notification
     - Returns: void
     */
    @objc func handleLaunchDidFail(sender:Notification) {
        #if DEBUG
        let handler = DebugLogHandler()
        handler.console("Launch Did FAIL")
        #endif
        
        deregisterForLaunchNotifications()
    }
}

