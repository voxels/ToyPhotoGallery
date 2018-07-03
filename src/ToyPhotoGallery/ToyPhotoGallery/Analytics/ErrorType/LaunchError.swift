//
//  LaunchError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Launch errors used in the LaunchController class
enum LaunchError : Error {
    case MissingRequiredKey
    case UnexpectedLaunchNotification
}

extension LaunchError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .MissingRequiredKey:
            return NSLocalizedString("The required API key is missing", comment: "")
        case .UnexpectedLaunchNotification:
            return NSLocalizedString("An unexpected launch notification was received", comment: "")
        }
    }
}
