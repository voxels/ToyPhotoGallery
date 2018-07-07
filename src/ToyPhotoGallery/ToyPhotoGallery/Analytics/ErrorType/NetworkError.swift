//
//  NetworkError.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/6/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

enum NetworkError : Error {
    case DownloadTaskIsMissingURLRequest
    case CellIsNotReady
}

extension NetworkError : LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .DownloadTaskIsMissingURLRequest:
            return NSLocalizedString("The download task is missing the URL Request", comment: "")
        case .CellIsNotReady:
            return NSLocalizedString("The image cell is not expecting the incoming data", comment: "")
        }
    }
}

