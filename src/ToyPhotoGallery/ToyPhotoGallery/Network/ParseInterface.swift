//
//  ParseServerInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import Parse

typealias ParseFetchCompletion = ([PFObject]?, Error?) throws -> Void

enum ParseClassName : String {
    case Resource
}

/// A class for wrapping the Parse API service
class ParseInterface : RemoteStoreController {
    
    static let serverURLString = "http://ec2-54-210-146-169.compute-1.amazonaws.com/parse"
    
    /// The launch control key that decodes the Parse Application ID
    var launchControlKey: LaunchControlKey? = .ParseApplicationId
    
    /**
     Launches the Parse API and posts a DidLaunchRemoteStore notification when complete
     - parameter key: the *ApplicationId* Key for Parse as a String
     - parameter center: the *NotificationCenter* used to post the *DidLaunchRemoteStore* notification
     - Throws: No error is thrown in this class
     - Returns: void
     */
    func launch(with key: String?, with center:NotificationCenter = NotificationCenter.default) throws {
        guard let key = key else {
            throw LaunchError.MissingRequiredKey
        }
        
        Parse.initialize(with: ParseInterface.configuration(with: key, for: ParseInterface.serverURLString))
        center.post(name: Notification.Name.DidLaunchRemoteStore, object: nil)
    }
}

extension ParseInterface {
    func fetch(name:ParseClassName, startIndex:Int, count:Int, errorHandler:ErrorHandlerDelegate = BugsnagInterface(),  completion:@escaping ParseFetchCompletion ) {
        let query = PFQuery(className:"Resource")
        query.findObjectsInBackground { (objects, error) in
            do {
                try completion(objects, error)
            } catch {
                errorHandler.report(error)
            }
        }
    }
}

extension ParseInterface {
    /**
     Constructs a *ParseClientConfiguration* for a Parse Server using the given *applicationId*
     - parameter applicationId: a *String* key representing the *applicationId* for the Parse server
     - parameter serverURLString: an URL *String* for the Parse server
     - Returns: void
     */
    static func configuration(with applicationId:String, for serverURLString:String)->ParseClientConfiguration {
        let config = ParseClientConfiguration {
            $0.applicationId = applicationId
            $0.server = serverURLString
        }
        return config
    }
}
