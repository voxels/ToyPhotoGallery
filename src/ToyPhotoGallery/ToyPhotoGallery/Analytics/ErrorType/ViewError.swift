//
//  ViewError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Remote Store Errors used in the ParseServerInterface class
enum ViewError : Error {
    case MissingNavigationController
}

extension ViewError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .MissingNavigationController:
            return NSLocalizedString("The expected navigation controller cannot be found", comment: "")
        }
    }
}
