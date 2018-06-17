//
//  GIF.swift
//  gif king
//
//  Created by Jae Kyung Lee on 23/05/2018.
//  Copyright © 2018 Jae Kyung Lee. All rights reserved.
//

import Foundation
import UIKit

enum GIFType {
    case gif
    case image
}

class GIFData {
    let id: Int
    let type: GIFType
    var url: String?
    var image: UIImage?
    
    init(url: String, id: Int) {
        self.type = .gif
        self.url = url
        self.id = id
    }
    
    init(image: UIImage, id: Int) {
        self.type = .image
        self.image = image
        self.id = id
    }
}
