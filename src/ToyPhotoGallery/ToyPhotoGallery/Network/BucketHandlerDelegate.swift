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
import AWSMobileClient
import AWSS3


/// Protocol wrapper for reporting analytics to third-party services
protocol BucketHandlerDelegate : LaunchService {}

class AWSBucketHandler : BucketHandlerDelegate {
    var launchControlKey: LaunchControlKey? = .AWSIdentityPoolId
    var bucketKey:LaunchControlKey = .AWSBucketName
    
    static let awsURLString = "s3.amazonaws.com"
    
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
    
    // TODO: Implement: https://docs.aws.amazon.com/aws-mobile/latest/developerguide/how-to-transfer-files-with-transfer-utility.html
    /**
     Intercept for fetching AWS urls since they fail with URLSession
     - parameter filename: the key *String* for the file
     - parameter queue: The queue that the fetch should be returned on
     - parameter errorHandler: The *ErrorHandlerDelegate* used to report errors
     - parameter completion: the callback used for the data
     */
    func fetchWithAWS(url:URL, on queue:DispatchQueue, with errorHandler:ErrorHandlerDelegate, completion:@escaping (Data?)->Void) {
        
        // If we can find a cached response, we will return that but run the fetch anyway to update the cache
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = {(task, progress) in DispatchQueue.main.async(execute: {
            // Do something e.g. Update a progress bar.
        })
        }
        
        var completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?
        completionHandler = { (task, URL, data, error) -> Void in
            queue.async {
                if let error = error {
                    errorHandler.report(error)
                }
                
                completion(data)
            }
        }
        
        guard let key = fileKey(for: url) else {
            completion(nil)
            return
        }
        
        let transferUtility = AWSS3TransferUtility.default()
        let _ = transferUtility.downloadData(
            fromBucket: bucketKey.decoded(),
            key: key,
            expression: expression,
            completionHandler: completionHandler
            ).continueWith {
                (task) -> AnyObject? in if let error = task.error {
                    errorHandler.report(error)
                    return nil
                }
                
                return task;
        }
    }
    
    /**
     Calculates the AWS filename from the given URL
     - parameter AWSUrl: the aws url
     - Returns: a *String* or nil if none is found
     */
    func fileKey(for AWSUrl:URL)->String? {
        let components = AWSUrl.absoluteString.split(separator: "/")
        var filename = ""
        for index in 3..<components.count {
            filename.append(String(components[index]))
            if index < components.count - 1 {
                filename.append("/")
            }
        }
        return filename
    }
}


extension BucketHandlerDelegate {
    /// Checks if a URL is from S3, because S3 needs its own network manager
    static func isAWS(url:URL)->Bool {
        return url.absoluteString.contains(AWSBucketHandler.awsURLString)
    }
}
