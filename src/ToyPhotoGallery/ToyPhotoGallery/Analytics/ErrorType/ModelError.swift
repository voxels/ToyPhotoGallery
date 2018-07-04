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
    case EmptyObjectId
    case EmptyImageResourceModel
    case UnsupportedParsingType
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
        case .EmptyObjectId:
            return NSLocalizedString("No object id was found", comment: "")
        case .EmptyImageResourceModel:
            return NSLocalizedString("No results were found for the given query", comment: "")
        case .UnsupportedParsingType:
            return NSLocalizedString("The expected type to parse is unimplemented", comment: "")
        }
    }
}
