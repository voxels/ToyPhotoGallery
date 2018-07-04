//
//  RemoteStoreController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

typealias FindCompletion = ([[String:AnyObject]]) -> Void

/// Protocol wrapper for handling a remote store service such as Parse or Firebase
protocol RemoteStoreController : LaunchService {
    var serverURLString:String { get }
    var defaultQuerySize:Int { get }
    
    func find(table: RemoteStoreTable, sortBy: String?, skip: Int, limit: Int, errorHandler:ErrorHandlerDelegate, completion: @escaping FindCompletion) -> Void
    func validate(sortBy:String, in schemaClass:RemoteStoreTable) throws -> Void
}

extension RemoteStoreController {
    /**
     Validates that the sortBy column name exists in the *RemoteStoreTable* type
     - parameter sortBy: the *String* of the column name to validate
     - parameter table: the *RemoteStoreTable* containing the desired column
     - Throws: a *RemoteStoreError.InvalidSortByColumn* error if the column does not exist in the table schema
     */
    func validate(sortBy:String, in table:RemoteStoreTable) throws -> Void {
        if RemoteStoreTable.CommonColumn.init(rawValue: sortBy) != nil{
            return
        }
        
        switch table {
        case .Resource:
            if RemoteStoreTable.ResourceColumn.init(rawValue: sortBy) != nil {
                return
            }
        case .EXIF:
            if RemoteStoreTable.EXIFColumn.init(rawValue: sortBy ) != nil {
                return
            }
        }
        
        throw RemoteStoreError.InvalidSortByColumn
    }
}
