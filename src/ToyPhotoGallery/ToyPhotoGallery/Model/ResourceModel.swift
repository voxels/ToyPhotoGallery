//
//  ImageResourceModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

typealias ResourceCompletion = ([URL])->Void

/// A struct used to handle image resources from the Parse interface
struct ResourceModel {
    static let remoteStoreController = ParseInterface()
    static let errorHandler = BugsnagInterface()
    
    func thumbnails(sortBy:String?, skip:Int, limit:Int, from service:RemoteStoreController = ResourceModel.remoteStoreController, completion:@escaping ResourceCompletion) {
        find(from: service, in: .Resource, sortBy: sortBy, skip: skip, limit: limit) { foundObjects in
            
        }
    }
}

extension ResourceModel {
    func find(from service:RemoteStoreController, in table:RemoteStoreTable, sortBy:String?, skip:Int, limit:Int, errorHandler:ErrorHandlerDelegate = ResourceModel.errorHandler, completion:@escaping FindCompletion) {
        
        service.find(table: table, sortBy: sortBy, skip: skip, limit: limit, errorHandler:errorHandler, completion:completion)
    }
}
