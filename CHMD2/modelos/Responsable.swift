//
//  Responsable.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 10/21/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class Responsable: NSObject {
    var id:String
    var nombre:String
    var numero:String
    var familia:String
    var foto:String
    var responsable:String
    
    init(id:String,nombre:String,numero:String,familia:String,foto:String,responsable:String){
        self.id = id
        self.nombre=nombre
        self.numero=numero
        self.familia=familia
        self.foto=foto
        self.responsable=responsable
    }
    
/*
     guard let id = diccionario["id"] as? String else {
                            print("No se pudo obtener el codigo")
                            return
                        }
                        
                        guard let nombre = diccionario["nombre"] as? String else {
                                               print("No se pudo obtener el codigo")
                                               return
                        }
                        
                        guard let numero = diccionario["numero"] as? String else {
                                               print("No se pudo obtener el numero")
                                               return
                        }
                        
                        guard let familia = diccionario["familia"] as? String else {
                                                                  print("No se pudo obtener el numero")
                                                                  return
                                           }
                        
                        guard let fotografia = diccionario["fotografia"] as? String else {
                                                                  print("No se pudo obtener el numero")
                                                                  return
                                           }
                        
                        guard let responsable = diccionario["responsable"] as? String else {
                                               print("No se pudo obtener el numero")
                                               return
                        }
                        
     
     */
}
