//
//  StoryboardMap.swift
//  ToyPhotoGallery
//
//  Created by Voxels on 7/4/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import Foundation

/// Enum referencing storyboard and view controller names
enum StoryboardMap : String {
    case Main
    enum ViewController : String {
        case GalleryViewController
        case PreviewViewController
    }
}
