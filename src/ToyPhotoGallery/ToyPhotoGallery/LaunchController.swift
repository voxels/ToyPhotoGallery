//
//  LaunchController.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

class LaunchController {
    /// Flag to print API key encryption bytes to the console
    static let showKeyEncryption = false
    
    init() {
        #if DEBUG
        show(hidden: [.BugsnagAPIKey, .ParseApplicationId])
        #endif
    }
}

private extension LaunchController {
    #if DEBUG
    /**
     Debug method used to print the bytes for an array of LaunchControllerKey encrypted by the Obfuscator class
     - parameter keys: an array of LaunchControllerKey to print to the console
     - parameter handler: The LogHandlerDelegate responsible for displaying the string
     */
    func show(hidden keys:[LaunchControlKey], with handler:LogHandlerDelegate = DebugLogHandler()) {
        if !LaunchController.showKeyEncryption {
            return
        }
        
        for key in keys {
            let bytes = key.generate(with:Obfuscator.saltObjects())
            handler.console("Key for \(key):")
            handler.console("\t\(String(describing:bytes))")
            handler.console("Decoded string:")
            handler.console(key.decoded())
            handler.console("\n\n")
        }
    }
    #endif
}
