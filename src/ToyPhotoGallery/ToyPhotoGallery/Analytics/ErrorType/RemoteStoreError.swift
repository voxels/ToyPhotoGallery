//
//  RemoteStoreError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Remote Store Errors used in the ParseServerInterface class
enum RemoteStoreError : Error {
    case FetchError
}

extension RemoteStoreError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .FetchError:
            return NSLocalizedString("Unable to fetch", comment: "")
        }
    }
}
