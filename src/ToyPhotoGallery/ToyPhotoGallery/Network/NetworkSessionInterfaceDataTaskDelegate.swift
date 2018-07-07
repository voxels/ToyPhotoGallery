//
//  NetworkSessionInterfaceDataTaskDelegate.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/7/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Protocol used to notify delegates of a data task's progress and received bytes
protocol NetworkSessionInterfaceDataTaskDelegate : class {
    var uuid:String { get }
    func didReceive(data: Data, for uuid:String?) throws
    func didReceive(response: URLResponse, for uuid:String?)
    func didFinish(uuid:String?)
    func didFail(uuid:String?, with error:URLError)
}
