//
//  PhotoViewCell.swift
//  Virtual Tourist
//
//  Created by Sam Black on 3/24/22.
//

import Foundation
import UIKit


class PhotoViewCell: UICollectionViewCell {
    
    @IBOutlet weak var flickrImageView:UIImageView!
    
    @IBOutlet weak var opaqueView: UIImageView!
    
    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            if newValue {
                super.isSelected = true
                self.flickrImageView.alpha = 0.35
                print("selected")
            } else if newValue == false {
                super.isSelected = false
                self.flickrImageView.alpha = 1.0
                print("deselected")
            }
        }
    }
}
