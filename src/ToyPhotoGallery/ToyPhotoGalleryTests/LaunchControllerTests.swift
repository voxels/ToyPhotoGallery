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
    
    func testLaunchStartsTimeOutTimer() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testService = TestErrorHandler()
        controller.launch(services: [testService], with:testCenter)
        XCTAssertNotNil(controller.timeOutTimer)
        controller.timeOutTimer?.invalidate()
    }
    
    func testLaunchAddsWaitNotifications() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testService = TestErrorHandler()
        controller.launch(services: [testService], with: testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchErrorHandler)
        XCTAssertTrue(actual)
        controller.timeOutTimer?.invalidate()
    }
    
    func testLaunchAttemptsLaunch() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testService = TestErrorHandler()
        controller.launch(services: [testService], with: testCenter)
        XCTAssertTrue(testService.didLaunch)
        controller.timeOutTimer?.invalidate()
    }
    
    func testWaitForLaunchNotificationWaitsForEachService() {
        let errorExpectation = expectation(forNotification: Notification.Name.DidLaunchErrorHandler, object: nil, handler: nil)
        let remoteStoreExpectation = expectation(forNotification: Notification.Name.DidLaunchRemoteStore, object: nil, handler: nil)
        let completeLaunchExpectation = expectation(forNotification: Notification.Name.DidCompleteLaunch, object: nil, handler: nil)

        let testCenter = NotificationCenter.default
        let controller = LaunchController()
        let testErrorHandlerService = TestErrorHandler()
        let testRemoteStoreControllerService = TestRemoteStoreController()
        controller.launch(services:[testErrorHandlerService, testRemoteStoreControllerService], with:testCenter)

        controller.timeOutTimer?.invalidate()
        
        let actual = register(expectations:[errorExpectation, remoteStoreExpectation, completeLaunchExpectation], duration:XCTestCase.defaultWaitDuration )
        XCTAssertTrue(actual)
    }
    
    func testAttemptLaunchesServices() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testErrorHandlerService = TestErrorHandler()
        let testRemoteStoreControllerService = TestRemoteStoreController()
        controller.attempt([testErrorHandlerService, testRemoteStoreControllerService], with: testCenter)
        
        XCTAssertTrue(testErrorHandlerService.didLaunch)
        XCTAssertTrue(testRemoteStoreControllerService.didLaunch)
    }
    
    func testWaitIfNecessaryInsertsWaitNotificationForRemoteStoreController() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testRemoteStoreController = TestRemoteStoreController()
        controller.waitIfNecessary(testRemoteStoreController, with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchRemoteStore)
        XCTAssertTrue(actual)
    }
    
    func testWaitIfNecessaryInsertsWaitNotificationForErrorHandlerDelegate() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testErrorHandlerService = TestErrorHandler()
        controller.waitIfNecessary(testErrorHandlerService, with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchErrorHandler)
        XCTAssertTrue(actual)
    }
    
    func testWaitIfNecessaryInsertsWaitNotificaitonForReportingHandlerDelegate() {
        let testCenter = NotificationCenter()
        let controller = LaunchController()
        let testReportingHandlerService = TestReportingHandler()
        controller.waitIfNecessary(testReportingHandlerService, with:testCenter)
        let actual = controller.waitForNotifications.contains(Notification.Name.DidLaunchReportingHandler)
        XCTAssertTrue(actual)
    }
    
    func testWaitIfNecessaryRegistersFoundNotificationName() {
        let testCenter = NotificationCenter.default
        let controller = TestNotificationLaunchController()
        let testReportingHandlerService = TestReportingHandler()
        controller.waitIfNecessary(testReportingHandlerService, with:testCenter)
        NotificationCenter.default.post(name: Notification.Name.DidLaunchReportingHandler, object: nil)
        XCTAssertTrue(controller.didReceiveLaunchReportingHandlerNotification)
    }
    
    func testCheckLaunchCompleteInsertsReceivedNotification() {
        let controller = LaunchController()
        controller.waitForNotifications = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchReportingHandler])
        let testReportingNotification = Notification(name: Notification.Name.DidLaunchReportingHandler)
        controller.checkLaunchComplete(with: testReportingNotification)
        let actual = controller.receivedNotifications.contains(Notification.Name.DidLaunchReportingHandler)
        XCTAssertTrue(actual)
    }
    
    func testCheckLaunchCompleteSignalsLaunchComplete() {
        let completeLaunchExpectation = expectation(forNotification: Notification.Name.DidCompleteLaunch, object: nil, handler: nil)

        let controller = LaunchController()
        controller.waitForNotifications = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchReportingHandler])
        let testReportingNotification = Notification(name: Notification.Name.DidLaunchReportingHandler)
        let testErrorHandlerNotification = Notification(name: Notification.Name.DidLaunchErrorHandler)
        controller.checkLaunchComplete(with: testReportingNotification)
        controller.checkLaunchComplete(with: testErrorHandlerNotification)
        let actual = register(expectations: [completeLaunchExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testVerifyCorrectlyReturnsFalse() {
        let controller = LaunchController()
        controller.waitForNotifications = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchReportingHandler])
        controller.receivedNotifications = Set([Notification.Name.DidLaunchErrorHandler])
        let expected = false
        let actual = controller.verify(received: controller.receivedNotifications, with: controller.waitForNotifications)
        XCTAssertEqual(expected, actual)
    }
    
    func testVerifyCorrectlyReturnsTrue() {
        let controller = LaunchController()
        let names = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchReportingHandler])
        controller.waitForNotifications = names
        controller.receivedNotifications = names
        let expected = true
        let actual = controller.verify(received: controller.receivedNotifications, with: controller.waitForNotifications)
        XCTAssertEqual(expected, actual)
    }
    
    func testSignalLaunchCompleteResetsProperties() {
        let controller = LaunchController()
        let names = Set([Notification.Name.DidLaunchErrorHandler, Notification.Name.DidLaunchReportingHandler])
        controller.waitForNotifications = names
        controller.receivedNotifications = names
        controller.timeOutTimer = Timer(timeInterval: 1, repeats: false, block: { (timer) in
            XCTFail("Should not be firing timer for this test")
        })
        controller.signalLaunchComplete()
        XCTAssertTrue(controller.waitForNotifications.count == 0)
        XCTAssertTrue(controller.receivedNotifications.count == 0)
        XCTAssertNil(controller.timeOutTimer)
    }
    
    func testSignalLaunchCompletePostsDidCompleteLaunchNotification() {
        let completeLaunchExpectation = expectation(forNotification: Notification.Name.DidCompleteLaunch, object: nil, handler: nil)
        
        let controller = LaunchController()
        controller.signalLaunchComplete()
        let actual = register(expectations: [completeLaunchExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testStartTimeoutTimerStartsTimer() {
        let controller = LaunchController()
        controller.startTimeOutTimer(duration: 10)
        XCTAssertNotNil(controller.timeOutTimer)
        controller.timeOutTimer?.invalidate()
    }
    
    func testStartTimeoutTimerFiresNotification() {
        let waitExpectation = expectation(forNotification: Notification.Name.DidFailLaunch, object: nil, handler: nil)
        let controller = LaunchController()
        controller.startTimeOutTimer(duration: 1)
        let actual = register(expectations: [waitExpectation], duration: XCTestCase.defaultWaitDuration)
        XCTAssertTrue(actual)
    }
    
    func testHandleErrorForwardsToErrorHandler() {
        let controller = LaunchController()
        let testErrorHandler = TestErrorHandler()
        controller.handle(error: LaunchError.DuplicateLaunch, with: testErrorHandler)
        XCTAssertTrue(testErrorHandler.didReport)
    }
    
    func testDidLaunchNotificationNameReturnsExpectedNameForService() {
        let testRemoteStoreController = TestRemoteStoreController()
        let testErrorHandler = TestErrorHandler()
        let testReportingHandler = TestReportingHandler()
        
        let controller = LaunchController()
        
        var actual = controller.didLaunchNotificationName(for: testRemoteStoreController)
        XCTAssertEqual(actual, Notification.Name.DidLaunchRemoteStore)
        
        actual = controller.didLaunchNotificationName(for: testErrorHandler)
        XCTAssertEqual(actual, Notification.Name.DidLaunchErrorHandler)
        
        actual = controller.didLaunchNotificationName(for: testReportingHandler)
        XCTAssertEqual(actual, Notification.Name.DidLaunchReportingHandler)
    }
    
    func testDidLaunchNotificationNameReturnsNilForUnexpectedService() {
        let fakeLaunchService = UnexpectedLaunchService()
        let controller = LaunchController()

        let actual = controller.didLaunchNotificationName(for: fakeLaunchService)
        XCTAssertNil(actual)
    }
    
    func testHandleNotificationSetsFlagForDidLaunchErrorHandler() {
        let notification = Notification(name: Notification.Name.DidLaunchErrorHandler)
        let controller = LaunchController()
        controller.handle(notification: notification)
        XCTAssertTrue(controller.didLaunchErrorHandler)
    }
}
