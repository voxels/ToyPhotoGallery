//
//  BucketHandlerDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import AWSCore
import AWSCognito

/// Protocol wrapper for reporting analytics to third-party services
protocol BucketHandlerDelegate : LaunchService {}

struct AWSBucketHandler : BucketHandlerDelegate {
    var launchControlKey: LaunchControlKey? = .AWSIdentityPoolId

    func launch(with key:String?, with center:NotificationCenter) throws {
        guard let poolID = launchControlKey?.decoded() else {
            throw ModelError.MissingValue
        }
        
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType:.USEast1,
                                                                identityPoolId:poolID)
        
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider:credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        center.post(name: Notification.Name.DidLaunchBucketHandler, object: nil)
    }
}
