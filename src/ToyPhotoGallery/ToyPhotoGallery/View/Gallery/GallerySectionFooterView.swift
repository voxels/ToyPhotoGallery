//
//  GallerySectionFooterView.swift
//  ToyPhotoGallery
//
//  Created by Michael Edgcumbe on 7/15/18.
//  Copyright © 2018 Michael Edgcumbe. All rights reserved.
//

import UIKit

class GallerySectionFooterView: UICollectionReusableView {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.clipsToBounds = true
    }
    
    class func instanceFromNib() -> UICollectionReusableView {
        return GallerySectionFooterView.nib().instantiate(withOwner: nil, options: nil)[0] as! UICollectionReusableView
    }
    
    class func nib() -> UINib {
        return UINib(nibName: "GallerySectionFooterView", bundle: nil)
    }
}
