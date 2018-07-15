//
//  ParseServerInterface.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation
import Parse

typealias ParseFindCompletion = ([PFObject]?, Error?) -> Void

// Global vars are only init once, which we *must* have for initializing Parse
// And Swift doesn't have dispatch_once, so we do this thing outside of any class instead

/// A class for wrapping the Parse API service
class ParseInterface : RemoteStoreController {
    /// The server URL String
    var serverURLString = "http://ec2-54-210-146-169.compute-1.amazonaws.com/parse"
    
    /// Default size for fetch results
    var defaultQuerySize = 20
    
    /// The launch control key that decodes the Parse Application ID
    var launchControlKey: LaunchControlKey? = .ParseApplicationId

    /// A calculated variable used to initialize Parse
    private lazy var initParse:(String, String)->Void = { key, server in
        Parse.initialize(with: ParseInterface.configuration(with: key, for: server))
    }
    
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

        if Parse.currentConfiguration() != nil {
            throw LaunchError.DuplicateLaunch
        }
        
        initParse(key, serverURLString)
       
        center.post(name: Notification.Name.DidLaunchRemoteStore, object: nil)
    }
    
    /**
     Finds the objects in the given schemaClass, sorted by the given String, with the expected fetch skip and limit constants.  Calls a completion block when completed
     - parameter table: a *RemoteStoreTable* table that should be queried on the remote store
     - parameter sortBy: the *String* of the column name to sort by, or nil if no sorting is needed
     - parameter skip: an *Int* of the number of records to skip in the query
     - parameter limit: an *Int* of the limit of the number of records returned by the query
     - parameter queue: The *DispatchQueue* we need to call the completion block on
     - parameter errorHandler: The *ErrorHandlerDelegate* that will report the error
     - parameter completion: the *FindCompletion* callback executed when the query is complete
     - Returns: void
     */
    func find(table: RemoteStoreTableMap, sortBy: String?, skip: Int, limit: Int, on queue:DispatchQueue, errorHandler: ErrorHandlerDelegate, completion: @escaping RawResourceArrayCompletion) {
        
        let wrappedCompletion = parseFindCompletion(with:errorHandler, for: completion)
        
        do {
            let pfQuery = try query(for: table, sortBy: sortBy, skip: skip, limit: limit)
            find(query: pfQuery, on:queue, completion: wrappedCompletion)
        } catch {
            errorHandler.report(error)
            completion(RawResourceArray())
        }
    }
    
    /**
     Constructs a *ParseFindCompletion* callback from a *FindCompletion* callback, essentially guaranteeing that the objects array will not be empty
     - parameter errorHandler: an *ErrorHandlerDelegate* that will report the caught error
     - parameter findCompletion: the *FindCompletion* block that needs to be wrapped for this interface
     - Returns: a *ParseFindCompletion* object that can be passed within this interface
     */
    func parseFindCompletion(with errorHandler:ErrorHandlerDelegate, for findCompletion:@escaping RawResourceArrayCompletion)->ParseFindCompletion {
        let wrappedCompletion:ParseFindCompletion = { (objects, error) in
            if let e = error {
                errorHandler.report(e)
            }
            
            var fetchedObjects = RawResourceArray()
            objects?.forEach({ (object) in
                fetchedObjects.append(self.dictionary(for: object))
            })
            
            findCompletion(fetchedObjects)
        }
        
        return wrappedCompletion
    }
    
    /**
     Executes the *PFQuery on a background thread and calls the callback when completed
     - parameter query: the *PFQuery* to run
     - parameter queue: The *DispatchQueue* we need to send the results back to.  Parse returns on the main thread by default.
     - parameter completion: the *ParseFindCompletion* callback to execute when the query has returned
     - Returns: void
     */
    func find(query:PFQuery<PFObject>, on queue:DispatchQueue, completion:@escaping ParseFindCompletion ) {
        query.findObjectsInBackground { (objects, error) in
            queue.async {
                completion(objects, error)
            }
        }
    }
    
    /**
     Constructs a *[String:AnyObject]* for the given *PFObject*
     - parameter object: the *PFObject* that needs to be converted to a dictionary
     - Returns: a *[String:AnyObject]* of the dictionary
     */
    func dictionary(for object:PFObject)->[String:AnyObject] {
        var dictionaryRepresentation = [String:AnyObject]()
        dictionaryRepresentation[RemoteStoreTableMap.CommonColumn.objectId.rawValue] = object.objectId as AnyObject
        dictionaryRepresentation[RemoteStoreTableMap.CommonColumn.createdAt.rawValue] = object.createdAt as AnyObject
        dictionaryRepresentation[RemoteStoreTableMap.CommonColumn.updatedAt.rawValue] = object.updatedAt as AnyObject
        object.allKeys.forEach { (key) in
            dictionaryRepresentation[key] = object[key] as AnyObject
        }
        return dictionaryRepresentation
    }
}

// MARK: - Query Construction
extension ParseInterface {
    /**
     Constructs a PFQuery for the given parameters
     - parameter table: a *RemoteStoreTable* table that should be queried on the remote store
     - parameter sortBy: the *String* of the column name to sort by, or nil if no sorting is needed
     - parameter skip: an *Int* of the number of records to skip in the query
     - parameter limit: an *Int* of the limit of the number of records returned by the query
     - parameter cachePoligy: the *PFCachePolicy* used for the query, defaults to *.networkElseCache*
     - Throws: Rethrows any errors generated by the call to validate the *sortBy* column
     - Returns: void
     */
    func query(for table:RemoteStoreTableMap, sortBy:String?, skip:Int, limit:Int, cachePolicy:PFCachePolicy = .networkElseCache) throws -> PFQuery<PFObject> {
        
        let query = PFQuery(className: table.rawValue)
        
        if let sortDescending = sortBy {
            do {
                try validate(sortBy: sortDescending, in:table)
            } catch {
                throw error
            }
            
            query.order(byDescending: sortDescending)
        }
        
        query.skip = skip
        query.limit = limit
        query.cachePolicy = cachePolicy
        
        return query
    }
}

// MARK: - Configuration

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
