//
//  MenuCirculares.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 4/7/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class MenuCirculares: NSObject {
    var nombre:String
    var id:Int=0;
    var imagen:UIImage
    
    init(id:Int,nombre:String, imagen:UIImage) {
        self.id=id;
        self.nombre=nombre;
        self.imagen=imagen;
    }
}
