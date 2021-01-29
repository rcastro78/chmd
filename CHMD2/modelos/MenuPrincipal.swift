//
//  MenuPrincipal.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/6/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class MenuPrincipal: NSObject {
    
    var id:Int=0;
    var imagen:UIImage
    
    init(id:Int,imagen:UIImage) {
        self.id=id;
    
        self.imagen=imagen;
    }
}
