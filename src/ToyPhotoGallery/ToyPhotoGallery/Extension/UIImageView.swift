//
//  UIImageView.swift
//  ToyPhotoGallery
//
//  Created by Michael Edgcumbe on 7/8/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

extension UIImageView {
    static func imageView(with resource:ImageResource, url:URL, networkSessionInterface:NetworkSessionInterface, completion: ImageCompletion?)->UIImageView {
        return BufferedImageView(url: url, networkSessionInterface: networkSessionInterface, completion: completion)
    }
}
