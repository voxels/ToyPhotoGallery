//
//  NetworkSessionTask.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/7/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Class used to wrap the associated information used to track and notify objects
/// about URLSessionTask
class NetworkSessionTask : Hashable {

    /// A unique identifier for the task, also the taskDescription
    var uuid:String = ""

    /// The *URLSessionTask*
    var task:URLSessionTask
    
    /// A flag used to indicate if a data task should be archived locally
    var retain:Bool = false
    
    /// The location of the retained archive
    var dataLocation:URL?
    
    /// A *NetworkSessionInterfaceDataTaskDelegate* that wants to have signals for
    /// the task's process and potentially a copy of the fetched bytes
    weak var dataDelegate:NetworkSessionInterfaceDataTaskDelegate?
    
    init(with uuid:String, task:URLSessionTask, retain:Bool, dataDelegate:NetworkSessionInterfaceDataTaskDelegate?) {
        self.uuid = uuid
        self.task = task
        self.retain = retain
        self.dataDelegate = dataDelegate
    }
    
    var hashValue: Int {
        return task.hashValue ^ uuid.hashValue &* 16777619
    }
    
    static func == (lhs: NetworkSessionTask, rhs: NetworkSessionTask) -> Bool {
        return lhs.task == rhs.task && lhs.uuid == rhs.uuid
    }
}
