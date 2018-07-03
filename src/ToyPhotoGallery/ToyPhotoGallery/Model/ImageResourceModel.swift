//
//  ImageResourceModel.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

typealias ImageResourceFetchCompletion = ([UIImage]?) throws -> Void

/// A struct used to handle image resources from the Parse interface
struct ImageResourceModel {
    
    func fetchImages(from service:RemoteStoreController, startIndex:Int, count:Int, completion:ImageResourceFetchCompletion) {
//        let parseService = ParseInterface()
//        parseService.fetch(name: .Resource, startIndex: 0, count: 30) { (objects, error) in
//            if let e = error {
//                throw e
//            }
//
//            guard let objects = objects else {
//                return
//            }
//
//            for object in objects {
//                print(object.objectId ?? "")
//            }
//        }
    }
}
