//
//  CircularCompleta.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 2/2/21.
//  Copyright © 2021 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class CircularCompleta: NSObject {
    var nombre:String
    var encabezado:String
    var fecha:String
    var id:Int=0;
    var imagen:UIImage
    var estado:Int
    var contenido:String
    var adjunto:Int
    var favorita:Int
    var fechaIcs:String
    var horaInicialIcs:String
    var horaFinalIcs:String
    var nivel:String?
    var espec:String
    var noLeido:Int
    
   
    init(id:Int,imagen:UIImage,encabezado:String,nombre:String,fecha:String,estado:Int,contenido:String, adjunto:Int,fechaIcs:String,horaInicialIcs:String,horaFinalIcs:String,nivel:String,noLeido:Int,favorita:Int,espec:String) {
           self.id=id
           self.nombre=nombre
           self.encabezado = encabezado
           self.fecha = fecha
           self.imagen = imagen
           self.estado = estado
           self.contenido = contenido
           self.adjunto = adjunto
           self.fechaIcs=fechaIcs
           self.horaInicialIcs=horaInicialIcs
           self.horaFinalIcs=horaFinalIcs
           self.noLeido = noLeido
           self.nivel=nivel as? String ?? ""
           self.favorita = favorita
        self.espec = espec
       }
    
}
