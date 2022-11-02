//
//  CircularDetalleNotificacionViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 3/18/22.
//  Copyright © 2022 Rafael David Castro Luna. All rights reserved.
//

import UIKit

import SQLite3
class CircularDetalleNotificacionViewController: UIViewController {

    
    @IBOutlet weak var favorito: UIButton!
    @IBOutlet weak var home: UIButton!
    @IBOutlet weak var webViewSinConexion: UITextView!
    @IBOutlet weak var eliminar: UIButton!
    
    @IBOutlet weak var home2: UIButton!
    @IBOutlet weak var fav2: UIButton!
    @IBOutlet weak var elimina2: UIButton!
    
    
    var ids = [String]()
    var titulos = [String]()
    var fechas = [String]()
    var niveles = [String]()
    var fechasIcs = [String]()
    var horasInicioIcs = [String]()
    var horasFinIcs = [String]()
    var idInicial:Int=0
    var posicion:Int=0
    var viaNotif:Int=0
    var id:String=""
    var idUsuario=""
    var horaInicialIcs=""
    var nextHoraIcs=""
    var horaFinalIcs=""
    var fechaIcs=""
    var nivel=""
    var esFavorita:Int=0
    var favMetodo:String="favCircular.php"
    var delMetodo:String="eliminarCircular.php"
    var noleerMetodo:String="noleerCircular.php"
    var leerMetodo:String="leerCircular.php"
    var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
    var circularUrl:String=""
    var circularTitulo:String=""
    var metodo_circular="getCircularId6.php"
    var contenido:String=""
   
    var circulares = [CircularTodas]()
    var idCirculares = [Int]()
    var db: OpaquePointer?
    var tipoCircular:Int=0
    var leido:Int=0
    var globalId:String=""
    var circFav:Int=0
    var clickeado:Int=0
    
    
    var html1:String=""
    var htmlBottom:String=""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showToast(message:"Espera un momento...", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
        let idCircular:Int=Int(UserDefaults.standard.string(forKey: "idCircularViaNotif") ?? "0")!
        leerCirculares(id: idCircular)
        //aqui trono al recibir la notificacion y darle click en ios 15
        //let titulo = circulares[0].nombre
        let titulo = UserDefaults.standard.string(forKey:"tituloNotif") ?? ""
        
        let tituloP1 = self.partirTituloP1(titulo: titulo)
        let tituloP2 = self.partirTituloP2(titulo: titulo)
        
        let fechaNotif = UserDefaults.standard.string(forKey:"fechaNotif") ?? ""
        
        let anio = fechaNotif.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
        let mes = fechaNotif.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
        let dia = fechaNotif.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
        //let nivel = circulares[0].nivel
        let contenido = UserDefaults.standard.string(forKey:"contenidoNotif") ?? ""
        let nivel = UserDefaults.standard.string(forKey:"nivelNotif") ?? ""
        
                       let dateFormatter = DateFormatter()
                       dateFormatter.dateFormat = "dd/MM/yyyy"
                       dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                       let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                       dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                       var d = dateFormatter.string(from: date1!)
                       d = d.lowercased()
        //let decoded = circulares[posicion].contenido.stringByDecodingHTMLEntities
        let decoded = contenido.stringByDecodingHTMLEntities
        
        self.mostrarCircular(id:posicion, tituloP1:tituloP1,tituloP2:tituloP2,decoded:decoded,nivel:nivel,d:d)
        home.addTarget(self,action: #selector(volverViaNotificacion),for:.touchUpInside)
        home2.addTarget(self,action: #selector(volverViaNotificacion),for:.touchUpInside)
    }
    @objc func volverViaNotificacion(){
        UserDefaults.standard.setValue(1, forKey: "notificado")
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "ValidarCorreoViewController") as! ValidarCorreoViewController
                self.present(newViewController, animated: true, completion: nil)
    }
    @IBAction func homeClick(_ sender: UIButton) {
    }
    
    @IBAction func favClick(_ sender: UIButton) {
    }
    
    @IBAction func fav2Click(_ sender: UIButton) {
    }
    
    @IBAction func eliminarClick(_ sender: UIButton) {
    }
    
    @IBAction func eliminar2Click(_ sender: Any) {
    }
    
    
    @IBAction func calClick(_ sender: UIButton) {
    }
    
    
    @IBAction func cal2Click(_ sender: UIButton) {
    }
    
    func partirTituloP1(titulo:String)->String{
        var totalElementos:Int=0
        var t=""
              var tituloArreglo = titulo.split{$0 == " "}.map(String.init)
              totalElementos = tituloArreglo.count
              
              if(totalElementos>4){
                t=tituloArreglo[0]+" "+tituloArreglo[1]+" "+tituloArreglo[2]+" "+tituloArreglo[3]
              }else{
                t = titulo
            }
        
        return t
    }
    
    func partirTituloP2(titulo:String)->String{
        var totalElementos:Int=0
        var tituloArreglo = titulo.split{$0 == " "}.map(String.init)
        totalElementos = tituloArreglo.count
        var t:String=""
        var i:Int=0
        if(totalElementos>4){
            for i in 4...totalElementos-1{
                t += tituloArreglo[i]+" "
            }
        }else{
            t=""
        }
        
        
        return t
    }
    
    func partirTitulo(label1:UILabel,label2:UILabel, titulo:String){
        
        
        
        var totalElementos:Int=0
        var tituloArreglo = titulo.split{$0 == " "}.map(String.init)
        totalElementos = tituloArreglo.count
        
        if(totalElementos>3){
            
            let html1 = """
                   <html>
                    <head>
                    <style>
                        .myDiv {
                            background-color: #91caee;
                            color:#0c4866;
                            text-align: center;
                            height:50%;
                            padding:12px;
                            width:100%;
                        }
                    .myDivv {
                            background-color: #ffffff;
                            color:#ffffff;
                            text-align: center;
                            margin-bottom:0px;
                            height:50%;
                            padding:12px;
                            width:100%;
                            }
                    </style>
                    </head>
                   <body>
                        <div class="myDiv">\(tituloArreglo[0]+" "+tituloArreglo[1]+" "+tituloArreglo[2])<br></div>
                       
                   </body>
                   </html>
                   """
            
        
            
            let modifiedFont = NSString(format:"<span>%@</span>" as NSString, html1) as String

            let attrStr = try! NSMutableAttributedString(
                data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
            let textRangeForFont : NSRange = NSMakeRange(0, attrStr.length)
            attrStr.addAttributes([NSAttributedString.Key.font : UIFont(name: "GothamRounded-Medium",size:20)!], range: textRangeForFont)
            
            label1.attributedText = attrStr
            
            label1.contentMode = .bottom
            label1.sizeToFit()
 
 
            var t:String=""
            var i:Int=0
            for i in 3...totalElementos-1{
                t += tituloArreglo[i]+" "
            }
            
            
            let html2 = """
            <html>
             <head>
             <style>
            
                 
                 .myDiv2 {
                     background-color: #098FCF;
                     color:#0c4866;
                     text-align: center;
                     height:50%;
                    width:100px;
                 }
            
             </style>
             </head>
            <body>
            <center>
             <div class="myDiv2">\(t)</div></center>
            </body>
            </html>
            """
             let modifiedFont2 = NSString(format:"<span>%@</span>" as NSString, html2) as String
            //
            
            let attrStr2 = try! NSMutableAttributedString(
                data: modifiedFont2.data(using: .unicode, allowLossyConversion: true)!,
                options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
            let textRangeForFont1 : NSRange = NSMakeRange(0, attrStr2.length)
            attrStr2.addAttributes([NSAttributedString.Key.font : UIFont(name: "GothamRounded-Medium",size:20)!], range: textRangeForFont1)
           label2.isHidden=false
            label2.attributedText = attrStr2
            
            //label2.text = t
             //label2.attributedText = NSAttributedString(string: t, attributes: strokeTextAttributes2)
            //label2.isHidden = false
            //label2.sizeToFit()
         
        }else{
             //label2.isHidden = true
            //label1.text = titulo
            //1 linea
            
            let html1 = """
                       <html>
                        <head>
                        <style>
                            .myDiv {
                                background-color: #91caee;
                                color:#0c4866;
                                text-align: center;
                                height:50%;
                                padding:12px;
                                width:100%;
                            }
                        
                        </style>
                        </head>
                       <body>
                            <div class="myDiv">\(titulo)<br></div>
                           
                       </body>
                       </html>
                       """
                
            
                
                let modifiedFont = NSString(format:"<span>%@</span>" as NSString, html1) as String

                let attrStr = try! NSMutableAttributedString(
                    data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
                    options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                    documentAttributes: nil)
                let textRangeForFont : NSRange = NSMakeRange(0, attrStr.length)
                attrStr.addAttributes([NSAttributedString.Key.font : UIFont(name: "GothamRounded-Medium",size:20)!], range: textRangeForFont)
                
                label1.attributedText = attrStr
                label2.text=""
                label2.isHidden=true
            
            
            
             //label1.attributedText = NSAttributedString(string: titulo, attributes: strokeTextAttributes1)
           
        }
    }
    func leerCirculares(id:Int){
           print("Leer desde la base de datos local")
           let fileUrl = try!
                      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
           
           if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
               print("error opening database")
           }
                    
           
              let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto FROM appCircularCHMD WHERE idCircular=\(id)"
        
        
            
        
           var queryStatement: OpaquePointer? = nil
           var imagen:UIImage
           imagen = UIImage.init(named: "appmenu05")!
           
           if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
          
              
               
                while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                        let id = sqlite3_column_int(queryStatement, 0)
                           var titulo:String="";
                   
                          if let name = sqlite3_column_text(queryStatement, 1) {
                              titulo = String(cString: name)
                            print("titulo: \(titulo)")
                             } else {
                              print("name not found")
                          }
                   
                   
                           var cont:String="";
                   
                          if let contenido = sqlite3_column_text(queryStatement,2) {
                              cont = String(cString: contenido)
                             } else {
                              print("name not found")
                          }
                 
                           let leida = sqlite3_column_int(queryStatement, 3)
                           let favorita = sqlite3_column_int(queryStatement, 4)
                           let eliminada = sqlite3_column_int(queryStatement, 5)
                           
                           
                   
                            var fechaIcs:String="";
                            if let fIcs = sqlite3_column_text(queryStatement, 7) {
                            fechaIcs = String(cString: fIcs)
                            } else {
                                 print("name not found")
                            }
                        
                    
                     var hIniIcs:String="";
                     if  let horaInicioIcs = sqlite3_column_text(queryStatement, 8) {
                       hIniIcs = String(cString: horaInicioIcs)
                      } else {
                       print("hIniIcs not found")
                   }
                    
                    
                    var hFinIcs:String="";
                    if  let horaFinIcs = sqlite3_column_text(queryStatement, 9) {
                        hFinIcs = String(cString: horaFinIcs)
                        } else {
                          print("name not found")
                        }
                    
                   var nivel:String="";
                   if  let nv = sqlite3_column_text(queryStatement, 10) {
                       nivel = String(cString: nv)
                       } else {
                         print("name not found")
                       }
                           print("nivel \(nivel)")
                           let adj = sqlite3_column_int(queryStatement, 11)
                          
                           
                           if(Int(leida) == 1){
                              imagen = UIImage.init(named: "circle_white")!
                           }else{
                               imagen = UIImage.init(named: "circle")!
                           }
                   
                           if(Int(favorita)==1){
                              imagen = UIImage.init(named: "circle_white")!
                           }
                   
                           var noLeida:Int = 0
                          
                   var fechaCircular="";
                   if let fecha = sqlite3_column_text(queryStatement, 6) {
                       fechaCircular = String(cString: fecha)
                      
                   } else {
                       print("name not found")
                   }
                    print("fecha: \(fechaCircular)")
                   
                   
                   //if(eliminada==0 ){
                      self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
                    
                    self.ids.append("\(id)")
                    
                  // }
                  
                 }
               
              
                }
               else {
                print("SELECT statement could not be prepared for notifications")
              }

              sqlite3_finalize(queryStatement)
          }
    func mostrarCircular(id:Int, tituloP1:String,tituloP2:String,decoded:String,nivel:String,d:String){
       
        //947,936,930,928,919,926,917,913
        
        /*
         {
              "to" : "cpPQrxT9sEm5oWH-clujs6:APA91bHM2vl2IhdHoHksJnkOFN2aDQwewWFAdaHUJbzdiTdtJDMcmeFBeprfWc3rVkCVsfp64gF0drlkp309o4dJBcqt5Qrd6A9Xu4kr67c9_FFOOzX7g0Hse4v7iIko-vRClmamOODW",

              "notification" : {

                  "body" : "Tienes una nueva circular sin leer!",
                  "idCircular":"311",
                  "content_available" : true,
                  "priority" : "high",
                  "viaNotificacion":"1",
                  "badge":"10",
                  "click_action": "ValidarPadreActivity"

              },

              "data" : {
              "body" : "Nueva circular: Tienes una nueva circular sin leer!",

              "idCircular":"311",
              "content_available" : true,
              "priority" : "high",
              "click_action": "CircularNotificacionActivity",
              "viaNotificacion":"1"
              }


              }
         
         */
        
        
        
        print("id_circular \(id)")
        
        if(tituloP1.count>0 && tituloP2.count<=0){
            htmlBottom = "<h4><div style='color:#0E497B;font-weight:normal'>\(decoded)</div></h4>"
            if(nivel.count>0){
                html1 = """
                           <html>
                             <head>
                                 <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">

                           <!-- jQuery library -->
                           <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>

                           <!-- Latest compiled JavaScript -->
                           <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

                                 <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5,user-scalable=yes">
                           <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
                           <meta name="HandheldFriendly" content="true">
                            <meta name="viewport" content="width=device-width, initial-scale=1">
                            
                           <style>
                               @-webkit-viewport { width: device-width; }
                               @-moz-viewport { width: device-width; }
                               @-ms-viewport { width: device-width; }
                               @-o-viewport { width: device-width; }
                               @viewport { width: device-width; }
                           </style>
                             </head>
                            
                               <style>
                               @font-face {font-family: GothamRoundedMedium; src: url('GothamRoundedBook_21018.ttf'); }
                                @font-face {font-family: GothamRoundedBold; src: url('GothamRoundedBold_21016.ttf'); }
                               h3 {
                                    font-family: GothamRoundedBold;
                                    color:#ffffff;
                                 }
                                 
                                  h4 {
                                    font-family: GothamRoundedMedium;
                                   color:#0E497B;
                                 }
                                 
                               h5 {
                                    font-family: GothamRoundedMedium;
                                    color:#0E497B;
                                 }
                                   
                                 a {
                                   font-size: 14px;
                                   font-family: GothamRoundedBold;
                                   color:#0E497B;
                                 }
                              
                           body {
                           padding: 2px;
                           margin: 2px;
                           font-family: GothamRoundedMedium;
                           color:#0E497B;

                           }

                           p{
                               //text-align:justify;
                               line-height:20px;
                               width:100%;
                               resize:both;
                           }

                           li{
                               line-height:20px;
                                  width:100%;
                                  resize:both;
                           }

                           ol,ul{
                               line-height:20px;
                                  width:100%;
                                  resize:both;
                           }

                           .rgCol
                           {
                               width: 25%;
                               height: 100%;
                               text-align: center;
                               vertical-align: middle;
                               display: table-cell;
                           }

                           .boxCol
                           {
                               display: inline-block;
                               width: 100%;
                               text-align: center;
                               vertical-align: middle;
                           }

                           span{
                           color:#0E497B;
                           }
                           .marquee-parent {
                             position: relative;
                             width: 100%;
                             overflow: hidden;
                             height: 48px;
                             text-align:center;
                             vertical-align: center;
                           }
                           .marquee-child {
                             display: block;
                             width: 100%;
                             text-align:center;
                             vertical-align: center;
                             /* width of your text div */
                             height: 48px;
                             /* height of your text div */
                             position: absolute;
                             animation: marquee 8s linear infinite; /* change 5s value to your desired speed */
                           }
                           .marquee-child:hover {
                             animation-play-state: paused;
                             cursor: pointer;
                           }
                           @keyframes marquee {
                             0% {
                               left: 100%;
                             }
                             100% {
                               left: -100% /* same as your text width */
                             }
                           }


                               </style>
                               
                               <body style="padding:1px;">
                                 
                                     
                           <div id="nivel"  style="text-align:right; width:100%;text-color:#0E497B">
                                   <h5>\(nivel)</h5>
                            </div>
                           </p>
                           <div id="fecha"  style="text-align:right; width:100%;text-color:#0E497B">
                                   <h5>
                                 \(d.lowercased())</h5>
                           </div>

                           <center>
                            <div id="titulo" style="width:100%;height:48px;padding-top:2px;padding-bottom:2px;padding-left:12px;padding-right:12px;background-color:#91CAEE;text-align:center; vertical-align: middle;">
                              <h3><center><span id='text' style='display:inline-block;'><b>\(tituloP1)</b></span></center></div>
                            
                           
                           """
            }else{
                html1 = """
                           <html>
                             <head>
                                 <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">

                           <!-- jQuery library -->
                           <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>

                           <!-- Latest compiled JavaScript -->
                           <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

                                 <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5,user-scalable=yes">
                           <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
                           <meta name="HandheldFriendly" content="true">
                            <meta name="viewport" content="width=device-width, initial-scale=1">
                            
                           <style>
                               @-webkit-viewport { width: device-width; }
                               @-moz-viewport { width: device-width; }
                               @-ms-viewport { width: device-width; }
                               @-o-viewport { width: device-width; }
                               @viewport { width: device-width; }
                           </style>
                             </head>
                            
                               <style>
                               @font-face {font-family: GothamRoundedMedium; src: url('GothamRoundedBook_21018.ttf'); }
                                @font-face {font-family: GothamRoundedBold; src: url('GothamRoundedBold_21016.ttf'); }
                               h3 {
                                    font-family: GothamRoundedBold;
                                    color:#ffffff;
                                 }
                                 
                                  h4 {
                                    font-family: GothamRoundedMedium;
                                   color:#0E497B;
                                 }
                                 
                               h5 {
                                    font-family: GothamRoundedMedium;
                                    color:#0E497B;
                                 }
                                   
                                 a {
                                   font-size: 14px;
                                   font-family: GothamRoundedBold;
                                   color:#0E497B;
                                 }
                              
                           body {
                           padding: 2px;
                           margin: 2px;
                           font-family: GothamRoundedMedium;
                           color:#0E497B;

                           }

                           p{
                               //text-align:justify;
                               line-height:20px;
                               width:100%;
                               resize:both;
                           }

                           li{
                               line-height:20px;
                                  width:100%;
                                  resize:both;
                           }

                           ol,ul{
                               line-height:20px;
                                  width:100%;
                                  resize:both;
                           }

                           .rgCol
                           {
                               width: 25%;
                               height: 100%;
                               text-align: center;
                               vertical-align: middle;
                               display: table-cell;
                           }

                           .boxCol
                           {
                               display: inline-block;
                               width: 100%;
                               text-align: center;
                               vertical-align: middle;
                           }

                           span{
                           color:#0E497B;
                           }
                           .marquee-parent {
                             position: relative;
                             width: 100%;
                             overflow: hidden;
                             height: 48px;
                             text-align:center;
                             vertical-align: center;
                           }
                           .marquee-child {
                             display: block;
                             width: 100%;
                             text-align:center;
                             vertical-align: center;
                             /* width of your text div */
                             height: 48px;
                             /* height of your text div */
                             position: absolute;
                             animation: marquee 8s linear infinite; /* change 5s value to your desired speed */
                           }
                           .marquee-child:hover {
                             animation-play-state: paused;
                             cursor: pointer;
                           }
                           @keyframes marquee {
                             0% {
                               left: 100%;
                             }
                             100% {
                               left: -100% /* same as your text width */
                             }
                           }


                               </style>
                               
                               <body style="padding:1px;">
                           
                           <div id="fecha"  style="text-align:right; width:100%;text-color:#0E497B">
                                   <h5>
                                 \(d.lowercased())</h5>
                           </div>

                           <center>
                              <div id="titulo"  style="width:100%;height:48px;padding-top:2px;padding-bottom:2px;padding-left:12px;padding-right:12px;background-color:#91CAEE;text-align:center; vertical-align: middle;">
                               <h3><center><span id='text' style='display:inline-block;'><b>\(tituloP1)</b></span></center></div>
                            
                           
                           """
            }
           
        }
        
        
        if(tituloP1.count>0 && tituloP2.count>0){
            htmlBottom = "<h4><div style='color:#0E497B;font-weight:normal'>\(decoded)</div></h4>"
            if(nivel.count>0){
                html1 = """
                                                      <html>
                                                        <head>
                                                            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">

                                                      <!-- jQuery library -->
                                                      <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>

                                                      <!-- Latest compiled JavaScript -->
                                                      <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

                                                            <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5,user-scalable=yes">
                                                      <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
                                                      <meta name="HandheldFriendly" content="true">
                                                       <meta name="viewport" content="width=device-width, initial-scale=1">
                                                       
                                                      <style>
                                                          @-webkit-viewport { width: device-width; }
                                                          @-moz-viewport { width: device-width; }
                                                          @-ms-viewport { width: device-width; }
                                                          @-o-viewport { width: device-width; }
                                                          @viewport { width: device-width; }
                                                      </style>
                                                        </head>
                                                       
                                                          <style>
                                                          @font-face {font-family: GothamRoundedMedium; src: url('GothamRoundedBook_21018.ttf'); }
                                                           @font-face {font-family: GothamRoundedBold; src: url('GothamRoundedBold_21016.ttf'); }
                                                          h3 {
                                                               font-family: GothamRoundedBold;
                                                               color:#ffffff;
                                                            }
                                                            
                                                             h4 {
                                                               font-family: GothamRoundedMedium;
                                                              color:#0E497B;
                                                            }
                                                            
                                                          h5 {
                                                               font-family: GothamRoundedMedium;
                                                               color:#0E497B;
                                                            }
                                                              
                                                            a {
                                                              font-size: 14px;
                                                              font-family: GothamRoundedBold;
                                                              color:#0E497B;
                                                            }
                                                         
                                                      body {
                                                      padding: 2px;
                                                      margin: 2px;
                                                      font-family: GothamRoundedMedium;
                                                      color:#0E497B;

                                                      }

                                                      p{
                                                          //text-align:justify;
                                                          line-height:20px;
                                                          width:100%;
                                                          resize:both;
                                                      }

                                                      li{
                                                          line-height:20px;
                                                             width:100%;
                                                             resize:both;
                                                      }

                                                      ol,ul{
                                                          line-height:20px;
                                                             width:100%;
                                                             resize:both;
                                                      }

                                                      .rgCol
                                                      {
                                                          width: 25%;
                                                          height: 100%;
                                                          text-align: center;
                                                          vertical-align: middle;
                                                          display: table-cell;
                                                      }

                                                      .boxCol
                                                      {
                                                          display: inline-block;
                                                          width: 100%;
                                                          text-align: center;
                                                          vertical-align: middle;
                                                      }

                                                      span{
                                                      color:#0E497B;
                                                      }
                                                      .marquee-parent {
                                                        position: relative;
                                                        width: 100%;
                                                        overflow: hidden;
                                                        height: 48px;
                                                        text-align:center;
                                                        vertical-align: center;
                                                      }
                                                      .marquee-child {
                                                        display: block;
                                                        width: 100%;
                                                        text-align:center;
                                                        vertical-align: center;
                                                        /* width of your text div */
                                                        height: 48px;
                                                        /* height of your text div */
                                                        position: absolute;
                                                        animation: marquee 8s linear infinite; /* change 5s value to your desired speed */
                                                      }
                                                      .marquee-child:hover {
                                                        animation-play-state: paused;
                                                        cursor: pointer;
                                                      }
                                                      @keyframes marquee {
                                                        0% {
                                                          left: 100%;
                                                        }
                                                        100% {
                                                          left: -100% /* same as your text width */
                                                        }
                                                      }
                                                          </style>
                                                         
                                                          <body style="padding:9px;">
                                                           
                                                                
                                                       
                                                      <div id="nivel"  style="text-align:right; width:100%;text-color:#0E497B">
                                                              <h5>\(nivel)</h5>
                                                       </div>
                                                      </p>
                                                      <div id="fecha"  style="text-align:right; width:100%;text-color:#0E497B">
                                                              <h5>
                                                            \(d.lowercased())</h5>
                                                      </div>

                                                      <div id="titulo"  style="width:100%;height:48px;padding-top:2px;padding-bottom:2px;padding-left:12px;padding-right:12px;background-color:#91CAEE;text-align:center; vertical-align: middle;">
                                                          <h3>
                                                          
                                                      <center><span id='text' style='display: inline-block;'><b>\(tituloP1)</b></span></center></div><div id='titulo' style='width:100%;padding-top:6px;padding-bottom:6px;padding-left:12px;padding-right:12px;background-color:#098FCF;text-align:center; vertical-align: middle;margin-top:-10px'><center><span id='text'  style='display: inline-block; width:100%;'><b>\(tituloP2)</b></span></center></div>
                                                      <h3>
                                                      <p>
                                                         
                                                              </center>
                                                          
                                                             </div>
                                                          
                                                      
                           """
            }else{
                html1 = """
                                                      <html>
                                                        <head>
                                                            <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css">

                                                      <!-- jQuery library -->
                                                      <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>

                                                      <!-- Latest compiled JavaScript -->
                                                      <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js"></script>

                                                            <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5,user-scalable=yes">
                                                      <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
                                                      <meta name="HandheldFriendly" content="true">
                                                       <meta name="viewport" content="width=device-width, initial-scale=1">
                                                       
                                                      <style>
                                                          @-webkit-viewport { width: device-width; }
                                                          @-moz-viewport { width: device-width; }
                                                          @-ms-viewport { width: device-width; }
                                                          @-o-viewport { width: device-width; }
                                                          @viewport { width: device-width; }
                                                      </style>
                                                        </head>
                                                       
                                                          <style>
                                                          @font-face {font-family: GothamRoundedMedium; src: url('GothamRoundedBook_21018.ttf'); }
                                                           @font-face {font-family: GothamRoundedBold; src: url('GothamRoundedBold_21016.ttf'); }
                                                          h3 {
                                                               font-family: GothamRoundedBold;
                                                               color:#ffffff;
                                                            }
                                                            
                                                             h4 {
                                                               font-family: GothamRoundedMedium;
                                                              color:#0E497B;
                                                            }
                                                            
                                                          h5 {
                                                               font-family: GothamRoundedMedium;
                                                               color:#0E497B;
                                                            }
                                                              
                                                            a {
                                                              font-size: 14px;
                                                              font-family: GothamRoundedBold;
                                                              color:#0E497B;
                                                            }
                                                         
                                                      body {
                                                      padding: 2px;
                                                      margin: 2px;
                                                      font-family: GothamRoundedMedium;
                                                      color:#0E497B;

                                                      }

                                                      p{
                                                          //text-align:justify;
                                                          line-height:20px;
                                                          width:100%;
                                                          resize:both;
                                                      }

                                                      li{
                                                          line-height:20px;
                                                             width:100%;
                                                             resize:both;
                                                      }

                                                      ol,ul{
                                                          line-height:20px;
                                                             width:100%;
                                                             resize:both;
                                                      }

                                                      .rgCol
                                                      {
                                                          width: 25%;
                                                          height: 100%;
                                                          text-align: center;
                                                          vertical-align: middle;
                                                          display: table-cell;
                                                      }

                                                      .boxCol
                                                      {
                                                          display: inline-block;
                                                          width: 100%;
                                                          text-align: center;
                                                          vertical-align: middle;
                                                      }

                                                      span{
                                                      color:#0E497B;
                                                      }
                                                      .marquee-parent {
                                                        position: relative;
                                                        width: 100%;
                                                        overflow: hidden;
                                                        height: 48px;
                                                        text-align:center;
                                                        vertical-align: center;
                                                      }
                                                      .marquee-child {
                                                        display: block;
                                                        width: 100%;
                                                        text-align:center;
                                                        vertical-align: center;
                                                        /* width of your text div */
                                                        height: 48px;
                                                        /* height of your text div */
                                                        position: absolute;
                                                        animation: marquee 8s linear infinite; /* change 5s value to your desired speed */
                                                      }
                                                      .marquee-child:hover {
                                                        animation-play-state: paused;
                                                        cursor: pointer;
                                                      }
                                                      @keyframes marquee {
                                                        0% {
                                                          left: 100%;
                                                        }
                                                        100% {
                                                          left: -100% /* same as your text width */
                                                        }
                                                      }
                                                          </style>
                                                         
                                                          <body style="padding:9px;">
                                                        
                                                      <div id="fecha"  style="text-align:right; width:100%;text-color:#0E497B">
                                                              <h5>
                                                            \(d.lowercased())</h5>
                                                      </div>

                                                      <div id="titulo"  style="width:100%;height:48px;padding-top:2px;padding-bottom:2px;padding-left:12px;padding-right:12px;background-color:#91CAEE;text-align:center; vertical-align: middle;">
                                                          <h3>
                                                          
                                                      <center><span id='text' style='display: inline-block;'><b>\(tituloP1)</b></span></center></div><div id='titulo' style='width:100%;padding-top:6px;padding-bottom:6px;padding-left:12px;padding-right:12px;background-color:#098FCF;text-align:center; vertical-align: middle;margin-top:-10px'><center><span id='text'  style='display: inline-block; width:100%;'><b>\(tituloP2)</b></span></center></div>
                                                      <h3>
                                                      <p>
                                                         
                                                              </center>
                                                          
                                                             </div>
                                                          
                                                      
                           """
            }
           
       
        }
        
        let modifiedFont = NSString(format:"<span>%@</span>" as NSString, html1) as String

                   let attrStr = try! NSMutableAttributedString(
                       data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
                       options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                       documentAttributes: nil)
                   let textRangeForFont : NSRange = NSMakeRange(0, attrStr.length)
                   attrStr.addAttributes([NSAttributedString.Key.font : UIFont(name: "Gotham Rounded",size:18)!], range: textRangeForFont)
            
            
            let modifiedFont2 = NSString(format:"<span>%@</span>" as NSString, htmlBottom) as String
            let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .natural
        
        
                       let attrStr2 = try! NSMutableAttributedString(
                           data: modifiedFont2.data(using: .unicode, allowLossyConversion: true)!,
                           options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                           documentAttributes: nil)
                       let textRangeForFont2 : NSRange = NSMakeRange(0, attrStr2.length)
        //attrStr2.addAttributes([NSAttributedString.Key.font : UIFont(name: "Gotham Rounded",size:15)!,NSAttributedString.Key.paragraphStyle:paragraph], range: textRangeForFont2)
        attrStr2.addAttributes([NSAttributedString.Key.font:UIFont.systemFont(ofSize: CGFloat(16), weight: .medium)], range: textRangeForFont2)
        
            let finalAttributedString = NSMutableAttributedString()
            finalAttributedString.append(attrStr)
            finalAttributedString.append(attrStr2)
            webViewSinConexion.attributedText = finalAttributedString
        
    }
    
}
