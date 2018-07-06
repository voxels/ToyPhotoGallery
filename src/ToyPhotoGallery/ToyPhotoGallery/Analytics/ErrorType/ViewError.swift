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
    case MissingViewController
    case MissingView
    case ViewHierarchyError
}

extension ViewError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .MissingNavigationController:
            return NSLocalizedString("The expected navigation controller cannot be found", comment: "")
        case .MissingViewController:
            return NSLocalizedString("The expected view controller cannot be found", comment: "")
        case .MissingView:
            return NSLocalizedString("The expected view cannot be found", comment: "")
        case .ViewHierarchyError:
            return NSLocalizedString("The view hierarchy is not configured for this case", comment: "")
        }
    }
}
