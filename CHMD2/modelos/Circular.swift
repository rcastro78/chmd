//
//  Circular.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/23/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class Circular: NSObject {
    var nombre:String
    var encabezado:String
    var fecha:String
    var id:Int=0;
    var contenido:String
    
    init(id:Int,encabezado:String,nombre:String,fecha:String,contenido:String) {
        self.id=id
        self.nombre=nombre
        self.encabezado = encabezado
        self.fecha = fecha
        self.contenido = contenido
      }
}
