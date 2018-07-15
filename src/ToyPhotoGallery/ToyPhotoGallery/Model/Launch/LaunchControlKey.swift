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
    case AWSIdentityPoolId
    case AWSBucketName
    
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
        case .AWSIdentityPoolId:
            return [46, 39, 66, 28, 49, 27, 27, 89, 94, 125, 84, 94, 84, 82, 74, 26, 75, 112, 93, 69, 125, 93, 93, 72, 83, 7, 71, 84, 1, 24, 40, 107, 100, 89, 75, 80, 13, 85, 28, 69, 118, 97, 106, 3, 18, 59]
        case .AWSBucketName:
            return [56, 59, 2, 84, 54, 13, 11, 17, 29, 38, 13, 10, 3, 23, 21, 28, 3, 51, 21, 0, 43, 22, 5, 17, 8, 19, 13]
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
        case .AWSIdentityPoolId:
            hideString = "us-east-1:52878ce1-5981-4f31-8f87-99c20e829fff"
        case .AWSBucketName:
            hideString = "com-federalforge-repository"
        }
        
        return obfuscator.bytesByObfuscatingString(hideString)
    }
    #endif
}
