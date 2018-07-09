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
    
    /// The launch controller handling all launch services
    var launchController:LaunchController?
    
    ///
    var backgroundSessionCompletionHandler:(()->Void)?
    
    /// A boolean indicating if unit tests are currently running
    private var isRunningUnitTests:Bool {
        return NSClassFromString("XCTestCase") != nil
    }
    
    deinit {
        deregisterForNotifications()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if isRunningUnitTests {
            return true
        }
        
        // Registers for *DidCompleteLaunch* notification
        registerForLaunchNotifications()
        
        // Start launch services
        let errorHandlerDelegate = BugsnagInterface()
        let remoteStoreController = ParseInterface()
        let networkSessionInterface = NetworkSessionInterface(with: errorHandlerDelegate)
        let resourceModelController = ResourceModelController(with: remoteStoreController, networkSessionInterface:networkSessionInterface, errorHandler: errorHandlerDelegate)
        launchController = LaunchController(with:resourceModelController)
        launchController?.launch(services: [errorHandlerDelegate, remoteStoreController])
        
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
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        backgroundSessionCompletionHandler = completionHandler
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
        
        do {
            try guaranteeControllers(from: self) { [weak self] (launchController, rootNavigationController) in
                self?.completeLaunch(with: launchController, navigationController: rootNavigationController, didSucceed: true)
            }
        } catch {
            launchController?.currentErrorHandler.report(error)
            kill()
        }
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

        do {
            try guaranteeControllers(from: self) { [weak self] (launchController, rootNavigationController) in
                self?.completeLaunch(with: launchController, navigationController: rootNavigationController, didSucceed: false)
            }
        } catch {
            launchController?.currentErrorHandler.report(error)
            kill()
        }
    }
}

// MARK: - ViewController Handling

extension AppDelegate {
    /**
     Completes the launch process with the given *LaunchController* and *UINavigationController*
     - parameter launchController: the *LaunchController* handling the launch process
     - parameter navigationController: the *UINavigationController* that is expected to be the root view controller of the AppDelegate's window
     - parameter didSucceed: a flag indicating if the launch process successfully completed
     - Returns: void
     */
    func completeLaunch(with launchController:LaunchController, navigationController:UINavigationController, didSucceed:Bool) {
        
        if didSucceed {
            do {
                try launchController.showGalleryView(in: navigationController, with: launchController.resourceModelController)
            } catch {
                launchController.currentErrorHandler.report(error)
                LaunchController.showLockoutViewController(with: window, message: error.localizedDescription)
            }
        } else {
            launchController.showReachabilityView(in: navigationController)
        }
    }
    
    /**
     Guarantees that the *AppDelegate* has a *LaunchController* and a *UINavigationController* as the root view controller of the *UIWindow*
     - parameter delegate: the *AppDelegate* to verify against
     - parameter completion: the callback used to hand back the *LaunchController* and *UINavigationController* located in the *AppDelegate*
     - Throws: a *LaunchError.MissingLaunchController* error if the *LaunchController* cannot be located, and a *ViewError.MissingNavigationController* error if the *UINavigationController* cannot be located
     - Returns: void
     */
    func guaranteeControllers(from delegate:AppDelegate, completion:(LaunchController, UINavigationController) ->Void) throws -> Void {
        guard let launchController = delegate.launchController else {
            throw LaunchError.MissingLaunchController
        }
        
        guard let rootNavigationController = delegate.window?.rootViewController as? UINavigationController else {
            throw ViewError.MissingNavigationController
        }
        
        completion(launchController, rootNavigationController)
    }
        
    // The app is broken because of a programming error.  We have no recourse except to
    // present an error if possible and kill the app
    /**
     Shows a fatal alert dialog, if possible, and kills the app.  
     */    
    func kill() {
        LaunchController.showLockoutViewController(with: window, message: "An unexpected error has occurred.  Please contact the developer at info@noisederived.com")
    }
}
