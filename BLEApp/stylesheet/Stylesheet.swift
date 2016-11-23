//
//  Stylesheet.swift
//  BLEApp
//
//  Created by Yevhen Kim on 2016-11-22.
//  Copyright © 2016 Yevhen Kim. All rights reserved.
//

import Foundation
import UIKit

class Stylesheet {
    
    static let sharedInstance = Stylesheet()
    
    let smallSize = CGFloat(12.0)
    let mediumSize = CGFloat(14.0)
    let largeSize = CGFloat(18.0)
    let xLargeSize = CGFloat(22.0)
    
    let titleText = UIFont(name: "BebasNeue Book", size: 18)
    let subTitleText = UIFont(name: "BebasNeue Light", size: 12)
    let bigText = UIFont(name: "BebasNeue Regular", size: 70)
    
    let centerAlignmant = NSTextAlignment.center
}
