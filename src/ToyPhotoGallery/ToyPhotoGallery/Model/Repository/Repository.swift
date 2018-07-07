//
//  Repository.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/5/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol Repository {
    associatedtype AssociatedType
    var map:[String:AssociatedType] { get set }
}
