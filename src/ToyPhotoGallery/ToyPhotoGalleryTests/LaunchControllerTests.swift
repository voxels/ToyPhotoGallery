//
//  LaunchControllerTests.swift
//  ToyPhotoGalleryTests
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import XCTest
@testable import ToyPhotoGallery

class UnexpectedLaunchService : LaunchService {
    var launchControlKey: LaunchControlKey?
    
    func launch(with key: String?, with center: NotificationCenter) throws {
        // Do nothing
    }
}

// NOTE: We use a NotificationCenter instance that is not the default
// for most of these tests so that they won't interfere with each other asynchronously
class LaunchControllerTests: XCTestCase {
    
    var testErrorHandler:TestErrorHandler?
    var testRemoteStoreController:TestRemoteStoreController?
    var resourceModelController:ResourceModelController?
    
    override func setUp() {
        testErrorHandler = TestErrorHandler()
        testRemoteStoreController = TestRemoteStoreController()
        let networkSessionInterface = NetworkSessionInterface(with: testErrorHandler!)
        resourceModelController = ResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface, errorHandler: testErrorHandler!)
    }
    
    func testLaunchStartsTimeOutTimer() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with: resourceModelController!)
        controller.launch(services: [testErrorHandler!], with:testCenter)
        XCTAssertNotNil(controller.timeoutTimer)
        controller.timeoutTimer?.invalidate()
    }
    
    func testLaunchAddsWaitNotifications() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with: resourceModelController!)
        controller.launch(services: [testErrorHandler!], with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchErrorHandler)
        XCTAssertTrue(actual)
        controller.timeoutTimer?.invalidate()
    }
    
    func testLaunchAttemptsLaunch() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with: resourceModelController!)
        controller.launch(services: [testErrorHandler!], with:testCenter)
        XCTAssertTrue(testErrorHandler!.didLaunch)
        controller.timeoutTimer?.invalidate()
    }
    
    func testAttemptLaunchesServices() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with: resourceModelController!)
        controller.attempt([testErrorHandler!, testRemoteStoreController!], with: testCenter)
        
        XCTAssertTrue(testErrorHandler!.didLaunch)
        XCTAssertTrue(testRemoteStoreController!.didLaunch)
    }
    
    func testWaitIfNecessaryInsertsWaitNotificationForRemoteStoreController() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with:resourceModelController!)
        controller.waitIfNecessary(testRemoteStoreController!, with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchRemoteStore)
        XCTAssertTrue(actual)
    }
    
    func testWaitIfNecessaryInsertsWaitNotificationForErrorHandlerDelegate() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with:resourceModelController!)
        controller.waitIfNecessary(testErrorHandler!, with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchErrorHandler)
        XCTAssertTrue(actual)
    }
    
    func testWaitIfNecessaryInsertsWaitNotificaitonForReportingHandlerDelegate() {
        let testCenter = NotificationCenter()
        let controller = LaunchController(with:resourceModelController!)
        let testReportingHandler = TestReportingHandler()
        controller.waitIfNecessary(testReportingHandler, with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchBucketHandler)
        XCTAssertTrue(actual)
    }
    
    func testWaitIfNecessaryRegistersFoundNotificationName() {
        let testCenter = NotificationCenter.default
        let controller = TestNotificationLaunchController(with:resourceModelController!)
        let testReportingHandler = TestReportingHandler()
        controller.waitIfNecessary(testReportingHandler, with:testCenter)
        NotificationCenter.default.post(name: Notification.Name.DidLaunchBucketHandler, object: nil)
        XCTAssertTrue(controller.didReceiveLaunchReportingHandlerNotification)
    }
    
    func testCheckLaunchCompleteInsertsReceivedNotification() {
        let controller = LaunchController(with:resourceModelController!)
        controller.waitForNotifications = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchBucketHandler])
        let testReportingNotification = Notification(name: Notification.Name.DidLaunchBucketHandler)
        controller.checkLaunchComplete(with: testReportingNotification)
        let actual = controller.receivedNotifications.contains(Notification.Name.DidLaunchBucketHandler)
        XCTAssertTrue(actual)
    }
    
    func testCheckLaunchCompleteBuildsResourceModelControllerRepository() {
        let networkSessionInterface = NetworkSessionInterface(with: testErrorHandler!)
        let testResourceModelController = TestResourceModelController(with: testRemoteStoreController!, networkSessionInterface: networkSessionInterface, errorHandler: testErrorHandler!)

        let waitExpectation = expectation(forNotification: Notification.Name.DidCompleteLaunch, object: nil) { (notification) -> Bool in
            let actual = testResourceModelController.didBuildRepository
            XCTAssertTrue(actual)
            return actual
        }

        let controller = LaunchController(with: testResourceModelController)
        controller.waitForNotifications = Set([Notification.Name.DidLaunchBucketHandler])
        let testReportingNotification = Notification(name: Notification.Name.DidLaunchBucketHandler)
        controller.checkLaunchComplete(with: testReportingNotification)

        let completed = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(completed)
    }
   
    func testModelUpdateFailedReturnsExpectedFailure() {
        let errors = [ModelError.EmptyObjectId]
        let actual = ResourceModelController.modelUpdateFailed(with: errors)
        XCTAssertTrue(actual)
    }
    
    func testModelUpdateFailedReturnsExpectedPass() {
        let errors = [ModelError.NoNewValues]
        let actual = ResourceModelController.modelUpdateFailed(with: errors)
        XCTAssertFalse(actual)
    }
    
    func testVerifyCorrectlyReturnsFalse() {
        let controller = LaunchController(with:resourceModelController!)
        controller.waitForNotifications = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchBucketHandler])
        controller.receivedNotifications = Set([Notification.Name.DidLaunchErrorHandler])
        let expected = false
        let actual = controller.verify(received: controller.receivedNotifications, with: controller.waitForNotifications)
        XCTAssertEqual(expected, actual)
    }
    
    func testVerifyCorrectlyReturnsTrue() {
        let controller = LaunchController(with: resourceModelController!)
        let names = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchBucketHandler])
        controller.waitForNotifications = names
        controller.receivedNotifications = names
        let expected = true
        let actual = controller.verify(received: controller.receivedNotifications, with: controller.waitForNotifications)
        XCTAssertEqual(expected, actual)
    }
    
    func testSignalLaunchCompleteResetsProperties() {
        let controller = LaunchController(with: resourceModelController!)
        let names = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchBucketHandler])
        controller.waitForNotifications = names
        controller.receivedNotifications = names
        controller.timeoutTimer = Timer(timeInterval: 1, repeats: false, block: { (timer) in
            XCTFail("Should not be firing timer for this test")
        })
        controller.signalLaunchComplete()
        XCTAssertTrue(controller.waitForNotifications.count == 0)
        XCTAssertTrue(controller.receivedNotifications.count == 0)
        XCTAssertNil(controller.timeoutTimer)
    }
    
    func testSignalLaunchCompletePostsDidCompleteLaunchNotification() {
        let completeLaunchExpectation = expectation(forNotification: Notification.Name.DidCompleteLaunch, object: nil, handler: nil)
        
        let controller = LaunchController(with:resourceModelController!)
        controller.signalLaunchComplete()
        let actual = register(expectations: [completeLaunchExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testSignalLaunchFailedResetsProperties() {
        let controller = LaunchController(with: resourceModelController!)
        let names = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchBucketHandler])
        controller.waitForNotifications = names
        controller.receivedNotifications = names
        controller.timeoutTimer = Timer(timeInterval: 1, repeats: false, block: { (timer) in
            XCTFail("Should not be firing timer for this test")
        })
        controller.signalLaunchFailed(reason: nil)
        XCTAssertTrue(controller.waitForNotifications.count == 0)
        XCTAssertTrue(controller.receivedNotifications.count == 0)
        XCTAssertNil(controller.timeoutTimer)
    }
    
    func testSignalLaunchFailedPostsDidFailLaunchNotification() {
        let completeLaunchExpectation = expectation(forNotification: Notification.Name.DidFailLaunch, object: nil, handler: nil)
        
        let controller = LaunchController(with:resourceModelController!)
        controller.signalLaunchFailed(reason: nil)
        let actual = register(expectations: [completeLaunchExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testResetResetsProperties() {
        let controller = LaunchController(with: resourceModelController!)
        let names = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchBucketHandler])
        controller.waitForNotifications = names
        controller.receivedNotifications = names
        controller.timeoutTimer = Timer(timeInterval: 1, repeats: false, block: { (timer) in
            XCTFail("Should not be firing timer for this test")
        })
        controller.reset()
        XCTAssertTrue(controller.waitForNotifications.count == 0)
        XCTAssertTrue(controller.receivedNotifications.count == 0)
        XCTAssertNil(controller.timeoutTimer)
    }
    
    func testStartTimeoutTimerStartsTimer() {
        let controller = LaunchController(with:resourceModelController!)
        controller.startTimeOutTimer(duration: 10)
        XCTAssertNotNil(controller.timeoutTimer)
        controller.timeoutTimer?.invalidate()
    }
    
    func testStartTimeoutTimerFiresNotification() {
        let waitExpectation = expectation(forNotification: Notification.Name.DidFailLaunch, object: nil, handler: nil)
        let controller = LaunchController(with:resourceModelController!)
        controller.startTimeOutTimer(duration: 1)
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testHandleErrorForwardsToErrorHandler() {
        let controller = LaunchController(with:resourceModelController!)
        let testErrorHandler = TestErrorHandler()
        controller.handle(error: LaunchError.DuplicateLaunch, with: testErrorHandler)
        XCTAssertTrue(testErrorHandler.didReport)
    }
    
    func testDidLaunchNotificationNameReturnsExpectedNameForService() {
        let testReportingHandler = TestReportingHandler()
        let controller = LaunchController(with:resourceModelController!)
        
        var actual = controller.didLaunchNotificationName(for: testRemoteStoreController!)
        XCTAssertEqual(actual, Notification.Name.DidLaunchRemoteStore)
        
        actual = controller.didLaunchNotificationName(for: testErrorHandler!)
        XCTAssertEqual(actual, Notification.Name.DidLaunchErrorHandler)
        
        actual = controller.didLaunchNotificationName(for: testReportingHandler)
        XCTAssertEqual(actual, Notification.Name.DidLaunchBucketHandler)
    }
    
    func testDidLaunchNotificationNameReturnsNilForUnexpectedService() {
        let fakeLaunchService = UnexpectedLaunchService()
        let controller = LaunchController(with:resourceModelController!)

        let actual = controller.didLaunchNotificationName(for: fakeLaunchService)
        XCTAssertNil(actual)
    }
    
    func testHandleNotificationSetsFlagForDidLaunchErrorHandler() {
        let notification = Notification(name: Notification.Name.DidLaunchErrorHandler)
        let controller = LaunchController(with:resourceModelController!)
        controller.handle(notification: notification)
        XCTAssertTrue(controller.didLaunchErrorHandler)
    }
    
    func testDidUpdateModelSignalsLaunchCompletion() {
        let waitExpectation = expectation(forNotification: Notification.Name.DidCompleteLaunch, object: nil, handler: nil)
        let controller = LaunchController(with:resourceModelController!)
        controller.didUpdateModel()        
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
}
