//
//  ModelError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/3/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Remote Store Errors used in the ParseServerInterface class
enum ModelError : Error {
    case IncorrectType
    case InvalidURL
    case Deallocated
    case MissingGalleryModel
}

extension ModelError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .IncorrectType:
            return NSLocalizedString("The object was not the expected type", comment: "")
        case .InvalidURL:
            return NSLocalizedString("The expected URL could not be constructed", comment: "")
        case .Deallocated:
            return NSLocalizedString("The model has been deallocated", comment: "")
        case .MissingGalleryModel:
            return NSLocalizedString("The expected gallery model is missing", comment: "")
        }
    }
}
