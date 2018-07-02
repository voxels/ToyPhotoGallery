//
//  LogHandler.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

protocol LogHandlerDelegate {
    func console(_ message:String)
}

extension LogHandlerDelegate {
    func console(_ message:String) {
        print(message)
    }
}

struct DebugLogHandler : LogHandlerDelegate {
    
}
