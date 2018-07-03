//
//  LaunchControllerKey.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/2/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Enum for handling launch control of services that need obfuscated API Keys
enum LaunchControlKey : String {
    case BugsnagAPIKey
    case ParseApplicationId
    
    /**
     Decodes the encrypted string for a LaunchControlKey
     - parameter obfuscator: an Obfuscator object configured with the same salt array of AnyObject used during the string's encryption
     - Returns: the decrypted API key String
     */
    func decoded(with obfuscator:Obfuscator = Obfuscator.init(withSalt: Obfuscator.saltObjects()))->String {
        return obfuscator.reveal(key())
    }
    
    /**
     Encodes an array of UInt8 that can be used with the Obfuscator class to decrypt an API key
     - Returns: a hard coded array of UInt8 with encrypted bytes
     */
    func key()->[UInt8] {
        switch self {
        case .BugsnagAPIKey:
            return [99, 48, 87, 77, 50, 94, 94, 77, 90, 119, 3, 85, 93, 4, 71, 78, 29, 116, 20, 64, 112, 87, 89, 85, 95, 7, 18, 82, 21, 66, 119, 48]
        case .ParseApplicationId:
            return [98, 53, 89, 75, 102, 81, 87, 70, 10, 126, 80, 89, 89, 0, 16, 28, 75, 116, 67, 22, 37, 4, 13, 87, 3, 83, 76, 7, 79, 24, 118, 99, 49, 68, 71, 10, 90, 87, 29, 22]
        }
    }

    #if DEBUG
    /**
     Generates the byte array for an API Key.
     - Returns: an array of UInt8 representing the encrypted API Key
     */
    func generate(with salt:[AnyObject])->[UInt8] {
        let obfuscator = Obfuscator(withSalt:salt)
        var hideString = ""
        switch self {
        case .BugsnagAPIKey:
            hideString = "8d84b61950b91a5735d042508ff79b9c"
        case .ParseApplicationId:
            hideString = "9a626982e9155ebee53faaa2d28bc880b05c4016"
        }
        
        return obfuscator.bytesByObfuscatingString(hideString)
    }
    #endif
}
