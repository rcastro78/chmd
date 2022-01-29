//
//  CircularDetalleViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/26/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import EventKit
import Firebase
import BitlySDK
import MarqueeLabel
import SQLite3

private let characterEntities : [ Substring : Character ] = [
    // XML predefined entities:
    "&quot;"    : "\"",
    "&amp;"     : "&",
    "&apos;"    : "'",
    "&lt;"      : "<",
    "&gt;"      : ">",
    "&ntilde;"      : "ñ",
    "&Ntilde;"      : "Ñ",
    "&aacute;"      : "á",
    "&eacute;"      : "é",
    "&iacute;"      : "í",
    "&oacute;"      : "ó",
    "&uacute;"      : "ú",
    "&Aacute;"      : "Á",
    "&Eacute;"      : "É",
    "&Iacute;"      : "Í",
    "&Oacute;"      : "Ó",
    "&Uacute;"      : "Ú",
    // HTML character entity references:
    "&nbsp;"    : "\u{00a0}",
    // ...
    "&middot;"   : "♦",
    "&deg;"   : "o",
    
]

extension String {

    /// Returns a new string made by replacing in the `String`
    /// all HTML character entity references with the corresponding
    /// character.
    var stringByDecodingHTMLEntities : String {

        // ===== Utility functions =====

        // Convert the number in the string to the corresponding
        // Unicode character, e.g.
        //    decodeNumeric("64", 10)   --> "@"
        //    decodeNumeric("20ac", 16) --> "€"
        func decodeNumeric(_ string : Substring, base : Int) -> Character? {
            guard let code = UInt32(string, radix: base),
                let uniScalar = UnicodeScalar(code) else { return nil }
            return Character(uniScalar)
        }

        // Decode the HTML character entity to the corresponding
        // Unicode character, return `nil` for invalid input.
        //     decode("&#64;")    --> "@"
        //     decode("&#x20ac;") --> "€"
        //     decode("&lt;")     --> "<"
        //     decode("&foo;")    --> nil
        func decode(_ entity : Substring) -> Character? {

            if entity.hasPrefix("&#x") || entity.hasPrefix("&#X") {
                return decodeNumeric(entity.dropFirst(3).dropLast(), base: 16)
            } else if entity.hasPrefix("&#") {
                return decodeNumeric(entity.dropFirst(2).dropLast(), base: 10)
            } else {
                return characterEntities[entity]
            }
        }

        // ===== Method starts here =====

        var result = ""
        var position = startIndex

        // Find the next '&' and copy the characters preceding it to `result`:
        while let ampRange = self[position...].range(of: "&") {
            result.append(contentsOf: self[position ..< ampRange.lowerBound])
            position = ampRange.lowerBound

            // Find the next ';' and copy everything from '&' to ';' into `entity`
            guard let semiRange = self[position...].range(of: ";") else {
                // No matching ';'.
                break
            }
            let entity = self[position ..< semiRange.upperBound]
            position = semiRange.upperBound

            if let decoded = decode(entity) {
                // Replace by decoded character:
                result.append(decoded)
            } else {
                // Invalid entity, copy verbatim:
                result.append(contentsOf: entity)
            }
        }
        // Copy remaining characters to `result`:
        result.append(contentsOf: self[position...])
        return result
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}


extension UIView {

   public enum Visibility: String {
       case visible = "visible"
       case invisible = "invisible"
       case gone = "gone"
   }

   var visibility: Visibility {
       get {
           let constraint = (self.constraints.filter{$0.firstAttribute == .height && $0.constant == 0}.first)
           if let constraint = constraint, constraint.isActive {
               return .gone
           } else {
               return self.isHidden ? .invisible : .visible
           }
       }
       set {
           if self.visibility != newValue {
               self.setVisibility(newValue)
           }
       }
   }

   @IBInspectable
   var visibilityState: String {
       get {
           return self.visibility.rawValue
       }
       set {
           let _visibility = Visibility(rawValue: newValue)!
           self.visibility = _visibility
       }
   }

   public func setVisibility(_ visibility: Visibility) {
       let constraints = self.constraints.filter({$0.firstAttribute == .height && $0.constant == 0 && $0.secondItem == nil && ($0.firstItem as? UIView) == self})
       let constraint = (constraints.first)

       switch visibility {
       case .visible:
           constraint?.isActive = false
           self.isHidden = false
           break
       case .invisible:
           constraint?.isActive = false
           self.isHidden = true
           break
       case .gone:
           self.isHidden = true
           if let constraint = constraint {
               constraint.isActive = true
           } else {
               let constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
               // constraint.priority = UILayoutPriority(rawValue: 999)
               self.addConstraint(constraint)
               constraint.isActive = true
           }
           self.setNeedsLayout()
           self.setNeedsUpdateConstraints()
       }
   }
}



class CircularDetalleViewController: UIViewController,WKNavigationDelegate {
//WKNavigationDelegate
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var btnFavorita: UIButton!
    @IBOutlet weak var btnAnterior: UIButton!
    @IBOutlet weak var btnSiguiente: UIButton!
    @IBOutlet weak var btnHome: UIButton!
    @IBOutlet weak var btnHome2: UIButton!
    
    @IBOutlet weak var btnRecargar: UIBarButtonItem!
    @IBOutlet weak var lblFechaCircular: UILabel!
    //@IBOutlet weak var lblTituloParte1: UILabel!
    //@IBOutlet weak var lblTituloParte2: UILabel!
    @IBOutlet weak var lblTituloNivel: UILabel!
    @IBOutlet weak var imbCalendario: UIButton!
      
    @IBOutlet weak var webViewSinConexion: UITextView!
    @IBOutlet weak var btnCalendario: UIButton!
    @IBOutlet weak var lblNivel: UILabel!
    var pinchGesture = UIPinchGestureRecognizer()
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
    let eventStore = EKEventStore()
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
    
    @objc func volver(){
        self.performSegue(withIdentifier: "unwindToPrincipal", sender: self)
    }
    
    
    @objc func volverViaNotificacion(){
        UserDefaults.standard.setValue(1, forKey: "notificado")
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "ValidarCorreoViewController") as! ValidarCorreoViewController
                self.present(newViewController, animated: true, completion: nil)
    }
    
    
    func contarNotificaciones()->Int32{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT count(*) FROM appCircularCHMD where leida=0 AND tipo=2"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
       return total
    }
    
    
    func mostrarCircular(tituloP1:String,tituloP2:String,decoded:String,nivel:String,d:String){
       
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
    @objc func pinchText(sender:UIPinchGestureRecognizer){
        print("Se ha llamado al gesto del webview")
        /*var pSize = CGFloat(UserDefaults.standard.float(forKey: "fontSize"))
        pSize = ((sender.velocity>0) ? 1:-1)*1+pSize
        UserDefaults.standard.setValue(pSize, forKey: "fontSize")
        UserDefaults.standard.synchronize()
        let formattedText = NSMutableAttributedString.init(attributedString: webViewSinConexion!.attributedText)
        formattedText.addAttribute(NSAttributedString.Key.font,value:UIFont.systemFont(ofSize: pSize),range: NSRange(location: 0, length: formattedText.length))
        webViewSinConexion.attributedText = formattedText*/
        
        var pinchScale = sender.scale
               pinchScale = round(pinchScale * 1000) / 1000.0

               if (pinchScale > 1) {
                webViewSinConexion.font = UIFont( name: "arial", size: webViewSinConexion.font!.pointSize + pinchScale)
               }
                webViewSinConexion.frame.height * pinchScale
                webViewSinConexion.frame.size.height *= pinchScale
                webViewSinConexion.frame.size.width *= pinchScale
               self.webViewSinConexion.layoutIfNeeded()
               print(webViewSinConexion.frame.size.height)
               print(webViewSinConexion.frame.size.width)
        
        
        }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        circFav = UserDefaults.standard.integer(forKey: "circFav")
        clickeado = UserDefaults.standard.integer(forKey: "clickeado")
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchText(sender:)))
        if(circFav==1)
        {
             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
        }else{
             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
        }
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.configuration.preferences.javaScriptEnabled = true

            self.webView.navigationDelegate = self
            self.activity.hidesWhenStopped = true
        
        
        tipoCircular = UserDefaults.standard.integer(forKey: "tipoCircular")
        let noLeido = Int(UserDefaults.standard.string(forKey: "noLeido") ?? "0")!
        print("no leido: \(noLeido)")
        //Si no se ha leido
        if(noLeido==1){
            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
            print("Reducir badge (-1)...")
        }
        
        
        
        if(tipoCircular==5){
            btnFavorita.isEnabled = false
            btnFavorita.isHidden = true
        }
        
        imbCalendario.isHidden=true
        idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        viaNotif = UserDefaults.standard.integer(forKey: "viaNotif")
        horaInicialIcs = UserDefaults.standard.string(forKey: "horaInicialIcs") ?? "00:00:00"
        horaFinalIcs = UserDefaults.standard.string(forKey: "horaFinalIcs") ?? "0"
        fechaIcs = UserDefaults.standard.string(forKey: "fechaIcs") ?? "0"
        nivel = UserDefaults.standard.string(forKey: "nivel") ?? "0"
        self.btnRecargar.isEnabled=false
        self.btnRecargar.tintColor = UIColor.clear
        
         if(horaInicialIcs != "00:00:00"){
            imbCalendario.isHidden=false
            btnCalendario.isHidden=false
            btnCalendario.isUserInteractionEnabled=false
         }else{
            imbCalendario.isHidden=true
            btnCalendario.isHidden=true
            btnCalendario.isUserInteractionEnabled=true
         }
        
        
        webView.isHidden=true
        webViewSinConexion.isHidden=false
        
        
        if (viaNotif == 0){
            let titulo = UserDefaults.standard.string(forKey: "nombre") ?? ""
            circularTitulo = titulo
            let fecha = UserDefaults.standard.string(forKey: "fecha") ?? ""
            contenido = UserDefaults.standard.string(forKey:"contenido") ?? ""
            id = UserDefaults.standard.string(forKey: "id") ?? ""
            globalId=id
            idInicial = Int(UserDefaults.standard.string(forKey: "id") ?? "0")!
            leido = Int(UserDefaults.standard.string(forKey: "leido") ?? "0")!
             let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            let bannerWidth = navigationItem.accessibilityFrame.size.width
            let bannerX = bannerWidth / 2
            let imageView = UIImageView(frame: CGRect(x: bannerX, y: 0, width: 18, height: 18))
            imageView.contentMode = .scaleAspectFit
            let image = UIImage(named: "chmd_barra2")
            imageView.image = image
            imageView.isUserInteractionEnabled = true
            imageView.addGestureRecognizer(tapGestureRecognizer)
            navigationItem.titleView = imageView
            
            
            
           
                //webView.isHidden=true
                //webViewSinConexion.isHidden=false
                idInicial = Int(UserDefaults.standard.string(forKey: "id") ?? "0")!
                print("id de la circular: \(idInicial)")
               leerCircular(idCircular: idInicial)
                //let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/getCirculares_iOS.php?usuario_id=\(idUsuario)"
                //     let _url = URL(string: address);
                // self.obtenerCirculares(uri:address)
               
            
            
            //partirTitulo(label1:self.lblTituloParte1,label2:self.lblTituloParte2,titulo:titulo)
            
        }else{
            self.showToast(message:"Espera un momento!", font: UIFont(name:"GothamRounded-Bold",size:12.0)!)
            id = UserDefaults.standard.string(forKey: "idCircularViaNotif") ?? ""
            idInicial = Int(UserDefaults.standard.string(forKey: "idCircularViaNotif") ?? "0")!
            //obtenerCircular(uri: urlBase+"getCircularId6.php?id="+id)
            
            webView.isHidden=false
            webViewSinConexion.isHidden=true

            webView.load(URLRequest(url: URL(string: urlBase+"getCircularId6.php?id="+id)!))
            
            
            let btnVolver = UIBarButtonItem(title: "< Volver", style: .done, target: self, action: #selector(volver))
            self.navigationItem.rightBarButtonItem  = btnVolver
            
            btnHome.addTarget(self,action: #selector(volverViaNotificacion),for:.touchUpInside)
            btnHome2.addTarget(self,action: #selector(volverViaNotificacion),for:.touchUpInside)
           
        }
        
        
        self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: self.id)
       //Actualizarla en la base de datos
       self.leeCirc(idCircular:Int(self.id) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
        
        
        if(!ConexionRed.isConnectedToNetwork()){
         
          webView.isHidden=false
          webViewSinConexion.isHidden=true
            let link = URL(string:urlBase+"getCircularId6.php?id=\(id)")!
                  let request = URLRequest(url: link)
                  webView.contentMode = .scaleAspectFit
                  webView.load(request)
                  webView.scrollView.isScrollEnabled = true
                  webView.scrollView.bounces = false
                  webView.allowsBackForwardNavigationGestures = false
                 // webView.navigationDelegate = self
                    
            
                  let address=urlBase+"getCircularesUsuarios.php?usuario_id=\(idUsuario)"
                  circularUrl = address
                  if ConexionRed.isConnectedToNetwork() == true {
                    
                    //Todas
                    if(tipoCircular==1){
                        
                        
                        self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: self.id)
                       //Actualizarla en la base de datos
                       self.leeCirc(idCircular:Int(self.id) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                        
                        
                      
                    }
                    
                    //Favoritas
                    if(tipoCircular==2){
                         let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/getCirculares_iOS.php?usuario_id=\(idUsuario)"
                            let _url = URL(string: address);
                            self.obtenerCircularesFavoritas(uri:address)
                            self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                    }
                    //No leidas
                    if(tipoCircular==3){
                         self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: self.id)
                        //Actualizarla en la base de datos
                        self.leeCirc(idCircular:Int(self.id) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                        
                     let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/getCirculares_iOS.php?usuario_id=\(idUsuario)"
                      let _url = URL(string: address);
                      self.obtenerCircularesNoLeidas(uri:address)
                  }
                    
                    //Papelera
                      if(tipoCircular==4){
                       let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/getCirculares_iOS.php?usuario_id=\(idUsuario)"
                        let _url = URL(string: address);
                        self.obtenerCircularesEliminadas(uri:address)
                    }
                    //Notificaciones
                    if(tipoCircular==5){
                      let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/getNotificaciones_iOS.php?usuario_id=\(idUsuario)"
                       let _url = URL(string: address);
                        self.obtenerNotificaciones(uri:address)
                        self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: self.id)
                        self.leeNotificacion(idCircular: Int(self.id)!, idUsuario: Int(idUsuario)!)
                    }
                    
                }
                                
                  posicion = find(value: id,in: ids) ?? 0
                 }else{
            
            if (viaNotif == 1){
                let link = URL(string:urlBase+"getCircularId6.php?id=\(id)")!
                circularUrl = urlBase+"getCircularId6.php?id=\(id)"
                print(urlBase+"getCircularId6.php?id=\(id)")
                let request = URLRequest(url: link)
                self.webViewSinConexion.isHidden=true;
                self.webView.isHidden=false;
                webView.load(request)
                
            }
            
            
            
            
            if (viaNotif == 0){
            if(tipoCircular==1){
              self.leerCirculares()
            }
            if(tipoCircular==2){
              self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
              self.leerCircularesFavoritas()
             }
            
            if(tipoCircular==3){
              self.leerCircularesNoLeidas()
             }
            if(tipoCircular==4){
             self.leerCircularesEliminadas()
            }
            if(tipoCircular==5){
             self.leerNotificaciones()
             self.leeNotificacion(idCircular: Int(self.id)!, idUsuario: Int(idUsuario)!)
            
            }
            
            let titulo = circulares[posicion].nombre
            let tituloP1 = self.partirTituloP1(titulo: titulo)
            let tituloP2 = self.partirTituloP2(titulo: titulo)
            
            let anio = circulares[posicion].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
            //aqui dio error sin internet
            let mes = circulares[posicion].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
            let dia = circulares[posicion].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
            let nivel = circulares[posicion].nivel
            
                           let dateFormatter = DateFormatter()
                           dateFormatter.dateFormat = "dd/MM/yyyy"
                           dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                           let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                           dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                           var d = dateFormatter.string(from: date1!)
                           d = d.lowercased()

            webView.isHidden=true
            webViewSinConexion.isHidden=false
            
            let decoded = circulares[posicion].contenido.stringByDecodingHTMLEntities
            mostrarCircular(tituloP1:tituloP1,tituloP2:tituloP2,decoded:decoded,nivel:nivel!,d:d)
           
                /*
                 aqui estaba*/
                
                       
                   //webViewSinConexion.attributedText = attrStr
            
            
            }
            
          
        }
        
       
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activity.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activity.stopAnimating()
    }
    
    
    
   
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        let tappedImage = tapGestureRecognizer.view as! UIImageView
         //self.performSegue(withIdentifier: "unwindSegueToVC1", sender: self)
        //unwindToCirculares
        self.performSegue(withIdentifier: "unwindSegueToVC1", sender: self)
    }
   
    func find(value searchValue: String, in array: [String]) -> Int?
    {
        for (index, value) in array.enumerated()
        {
            if value == searchValue {
                return index
            }
        }
        
        return nil
    }
    
    func insertarEvento(store: EKEventStore,titulo:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,ubicacionIcs:String) {
        let calendario = store.calendars(for: .event)
        
        //Convertir las horas
        let dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "es_MX_POSIX")
        dateFormatter.dateFormat = dateFormat
        print("\(fechaIcs)'T'\(horaInicioIcs)")
        let calendar = calendario[0]
        let startDate = dateFormatter.date(from: "\(fechaIcs)T\(horaInicioIcs)")
        let eDate = dateFormatter.date(from:"\(fechaIcs)T\(horaFinIcs)")
        print("fecha \(startDate)")
         print("fecha \(eDate)")
        let endDate = eDate
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = titulo
        event.startDate = startDate
        event.endDate = eDate

        do {
            try store.save(event, span: .thisEvent)
            print("Evento guardado")
            //self.showToast(message:"Evento guardado", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
        }
        catch {
           print("Error guardando el evento")
            
        }
        
        
    }
     
   
    
    @IBAction func reload(_ sender: UIBarButtonItem) {
        if(ConexionRed.isConnectedToNetwork()){
                self.btnRecargar.isEnabled=false
                self.btnRecargar.tintColor = UIColor.clear
                let link = URL(string:urlBase+"getCircularId6.php?id=\(globalId)")!
                circularUrl = urlBase+"getCircularId6.php?id=\(globalId)"
                let request = URLRequest(url: link)
                webView.load(request)
        }else{
            
        }
    }
    
    
    
    @IBAction func btnCalendarioClick(_ sender: Any) {
        //if(ConexionRed.isConnectedToNetwork()){
               
                let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas agregar este evento a tu calendario?", preferredStyle: .alert)
                
                 //Create OK button with action handler
                let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                  
                    
                    
                    let eventStore = EKEventStore()
                               switch EKEventStore.authorizationStatus(for: .event) {
                               case .authorized:
                                self.insertarEvento(store: eventStore, titulo: self.circularTitulo, fechaIcs: self.fechaIcs, horaInicioIcs: self.horaInicialIcs, horaFinIcs: self.horaFinalIcs, ubicacionIcs: "")
                                  
                                  
                                  
                                   case .denied:
                                       print("Acceso denegado")
                                   case .notDetermined:
                                   // 3
                                       eventStore.requestAccess(to: .event, completion:
                                         {[weak self] (granted: Bool, error: Error?) -> Void in
                                             if granted {
                                                self?.insertarEvento(store: eventStore, titulo: self?.circularTitulo ?? "", fechaIcs: self?.fechaIcs ?? "", horaInicioIcs: self?.horaInicialIcs ?? "", horaFinIcs: self?.horaFinalIcs ?? "", ubicacionIcs: "")
                                             } else {
                                                   print("Acceso denegado")
                                             }
                                       })
                                       default:
                                           print("Case default")
                        
                        
                    }
                    
                    
                    
                    
                })
                
                // Create Cancel button with action handlder
                let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                    
                }
                
                //Add OK and Cancel button to dialog message
                dialogMessage.addAction(ok)
                dialogMessage.addAction(cancel)
                self.present(dialogMessage, animated: true, completion: nil)
             
        /*}else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                       alert.show()
        }*/
    }
    @IBAction func insertaEventoClick(_ sender: UIButton) {
       //if(ConexionRed.isConnectedToNetwork()){
              
               let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas agregar este evento a tu calendario?", preferredStyle: .alert)
               
               let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                 
                   
                   
                   let eventStore = EKEventStore()
                              switch EKEventStore.authorizationStatus(for: .event) {
                              case .authorized:
                               self.insertarEvento(store: eventStore, titulo: self.circularTitulo, fechaIcs: self.fechaIcs, horaInicioIcs: self.horaInicialIcs, horaFinIcs: self.horaFinalIcs, ubicacionIcs: "")
                                   
                                  case .denied:
                                      print("Acceso denegado")
                                  case .notDetermined:
                                      eventStore.requestAccess(to: .event, completion:
                                        {[weak self] (granted: Bool, error: Error?) -> Void in
                                            if granted {
                                               self?.insertarEvento(store: eventStore, titulo: self?.circularTitulo ?? "", fechaIcs: self?.fechaIcs ?? "", horaInicioIcs: self?.horaInicialIcs ?? "", horaFinIcs: self?.horaFinalIcs ?? "", ubicacionIcs: "")
                                            } else {
                                                  print("Acceso denegado")
                                            }
                                      })
                                      default:
                                          print("Case default")
                       
                       
                   }
                   
                   
                   
                   
               })

               let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                   
               }
               dialogMessage.addAction(ok)
               dialogMessage.addAction(cancel)
            
      /* }else{
           var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                      alert.show()
       }*/
    }
    
    
    
    
        
   var p = UserDefaults.standard.integer(forKey:"posicion")
    @IBAction func btnSiguienteClick(_ sender: UIButton) {
        
        
        
        
        //self.activity.startAnimating()
        //if(!ConexionRed.isConnectedToNetwork()){
             /*print("posicion \(p)")
             p = p+1
            if(p >= ids.count){
              btnSiguiente.isUserInteractionEnabled=false
            }
            
            if(p<ids.count){
               
                var nextId = ids[p]
                globalId=nextId
                //leer al server
               self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: nextId)
                //leer local
                self.leeCirc(idCircular:Int(nextId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                
                let f = self.getFavorita(idCircular:Int(nextId) ?? 0)
                if(f==1){
                 self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                }else{
                 self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                }
                if(self.tipoCircular==5){
                    let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                    if(leida==0){
                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                    }
                }else{
                    let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                    if(leida==0){
                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                    }
                }
                
                
                
                var nextTitulo = titulos[p]
                var nextFecha = fechas[p]
                //self.lblTituloParte1.text=nextTitulo
                var nextHoraIniIcs = horasInicioIcs[p]
                nextHoraIcs = horasInicioIcs[p]
                var nextHoraFinIcs = horasFinIcs[p]
                var nextFechaIcs = fechasIcs[p]
                var nextNivel = niveles[p]
                
                if(nextHoraIniIcs != "00:00:00"){
                    imbCalendario.isHidden=false
                    btnCalendario.isHidden=false
                }else{
                    imbCalendario.isHidden=true
                    btnCalendario.isHidden=true
                }
        
               // self.partirTitulo(label1:self.lblTituloParte1,label2:self.lblTituloParte2,titulo:nextTitulo)
                
                circularTitulo = nextTitulo
                let link = URL(string:urlBase+"getCircularId6.php?id=\(nextId)")!
                let request = URLRequest(url: link)
                circularUrl = urlBase+"getCircularId6.php?id=\(nextId)"
                webView.load(request)
                self.title = "Circular"
               
                id = nextId;
            }else{
       
            }
                
                
            */
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1), execute: {
            
        })
        if(clickeado==0){
            p=p+1
        }
        clickeado=1
        
        
       print("posicion \(p)")
        p = p+1
            
            if(p<circulares.count){
              
                if(p>=circulares.count){
                    p = 0
                }
               
               
                    
                    if(p<ids.count){
                                   
                                    let nextId = ids[p]
                                    globalId=nextId
                                    //leer al server
                                   self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: nextId)
                                    //leer local
                                    self.leeCirc(idCircular:Int(nextId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                                    
                                    let f = self.getFavorita(idCircular:Int(nextId) ?? 0)
                                    if(f==1){
                                     self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                                    }else{
                                     self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                                    }
                                    if(self.tipoCircular==5){
                                        let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                        if(leida==0){
                                            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                        }
                                    }else{
                                        let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                        if(leida==0){
                                            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                        }
                                    }
                    
                    
                    
                }
                
                
                
                
                let anio = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
                let mes = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
                let dia = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
                
                
                var nextHoraIniIcs = circulares[p].horaInicialIcs
                var nextHoraFinIcs = circulares[p].horaFinalIcs
                var nextFechaIcs = circulares[p].fechaIcs
                print("NEXT HORA \(nextHoraIcs)")
                if(nextHoraIniIcs != "00:00:00"){
                    imbCalendario.isHidden=false
                    btnCalendario.isHidden=false
                }else{
                    imbCalendario.isHidden=true
                    btnCalendario.isHidden=true
                }
                
               let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                let d = dateFormatter.string(from: date1!)
                //self.lblTituloParte1.text=circulares[p].nombre
                //self.partirTitulo(label1:self.lblTituloParte1,label2:self.lblTituloParte2,titulo:circulares[p].nombre)
                         webView.isHidden=true
                         webViewSinConexion.isHidden=false
                         
                          let titulo = circulares[p].nombre
                           let tituloP1 = self.partirTituloP1(titulo: titulo)
                           let tituloP2 = self.partirTituloP2(titulo: titulo)
                            let nivel=circulares[p].nivel
                          
                           let decoded = circulares[p].contenido.stringByDecodingHTMLEntities
                          //aqui estaba
                            mostrarCircular(tituloP1:tituloP1,tituloP2:tituloP2,decoded:decoded,nivel:nivel!,d:d)
               
                
            
            //}
          
            
        }
    }
    
    
    
    
  
    @IBAction func btnNextClick(_ sender: UIButton) {

      
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1), execute: {
            
        })
        
       print("posicion \(p)")
        if(clickeado==0){
            p=p+1
        }
        clickeado=1
        
        if(p<circulares.count){
            p = p+1
            if(p>=circulares.count){
                p = 0
            }
           
            
            if(p<ids.count){
                           
                            let nextId = ids[p]
                            globalId=nextId
                            //leer al server
                           self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: nextId)
                            //leer local
                            self.leeCirc(idCircular:Int(nextId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                            
                            let f = self.getFavorita(idCircular:Int(nextId) ?? 0)
                            if(f==1){
                             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                            }else{
                             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                            }
                            if(self.tipoCircular==5){
                                let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                if(leida==0){
                                    UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                }
                            }else{
                                let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                if(leida==0){
                                    UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                }
                            }
            
            
            
        }
            
            
            let f = self.getFavorita(idCircular:Int(circulares[p].id) ?? 0)
            if(f==1){
             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
            }else{
             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
            }
            
            
            if(self.tipoCircular==5){
                let leida = self.getLeida(idCircular: Int(circulares[p].id) ?? 0, tabla: "appCircularCHMD")
                if(leida==0){
                    UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                }
            }else{
                let leida = self.getLeida(idCircular: Int(circulares[p].id) ?? 0, tabla: "appCircularCHMD")
                if(leida==0){
                    UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                }
            }
            
            
            var nextHoraIniIcs = circulares[p].horaInicialIcs
            var nextHoraFinIcs = circulares[p].horaFinalIcs
            var nextFechaIcs = circulares[p].fechaIcs
            //self.lblTituloParte1.text=circulares[p].nombre
            print("NEXT HORA \(nextHoraIcs)")
            if(nextHoraIniIcs != "00:00:00"){
                imbCalendario.isHidden=false
                btnCalendario.isHidden=false
            }else{
                imbCalendario.isHidden=true
                btnCalendario.isHidden=true
            }
            
         
            
           webView.isHidden=true
           webViewSinConexion.isHidden=false
           
            let titulo = circulares[p].nombre
             let tituloP1 = self.partirTituloP1(titulo: titulo)
             let tituloP2 = self.partirTituloP2(titulo: titulo)
            let nivel = circulares[p].nivel
             let anio = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
             //aqui dio error sin internet
             let mes = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
            
             let dia = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
             
                             let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd/MM/yyyy"
                            dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                            let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                            dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                            let d = dateFormatter.string(from: date1!)
             webView.isHidden=true
             webViewSinConexion.isHidden=false
             
             let decoded = circulares[p].contenido.stringByDecodingHTMLEntities
             //aqui estaba
            mostrarCircular(tituloP1:tituloP1,tituloP2:tituloP2,decoded:decoded,nivel:nivel!,d:d)
           
            
            
            
                        //webViewSinConexion.attributedText = attrStr
             
            
        
        }
      
        
    //}
        
    }
        
    
    @IBAction func btnAnteriorClick(_ sender: UIButton) {
      
        if(clickeado==0){
            if(p>0){
                p=p-1
            }
        }
        clickeado=1
        
                      
                      p = p-1
                   if(p>0){
                    
                    
                    if(p<ids.count){
                                   
                                    let nextId = ids[p]
                                    globalId=nextId
                                    //leer al server
                                   self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: nextId)
                                    //leer local
                                    self.leeCirc(idCircular:Int(nextId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                                    
                                    let f = self.getFavorita(idCircular:Int(nextId) ?? 0)
                                    if(f==1){
                                     self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                                    }else{
                                     self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                                    }
                                    if(self.tipoCircular==5){
                                        let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                        if(leida==0){
                                            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                        }
                                    }else{
                                        let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                        if(leida==0){
                                            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                        }
                                    }
                    
                    
                    
                }
                    
                    
                    
                    let f = self.getFavorita(idCircular:Int(circulares[p].id) ?? 0)
                    if(f==1){
                     self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                    }else{
                     self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                    }
                    
                    
                    if(self.tipoCircular==5){
                        let leida = self.getLeida(idCircular: Int(circulares[p].id), tabla: "appCircularCHMD")
                        if(leida==0){
                            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                        }
                    }else{
                        let leida = self.getLeida(idCircular: Int(circulares[p].id), tabla: "appCircularCHMD")
                        if(leida==0){
                            UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                        }
                    }
                    
                    
                    
                                      
                                   webView.isHidden=true
                                             webViewSinConexion.isHidden=false
                                             
                                              let titulo = circulares[p].nombre
                                               let tituloP1 = self.partirTituloP1(titulo: titulo)
                                               let tituloP2 = self.partirTituloP2(titulo: titulo)
                                               let nivel = circulares[p].nivel
                                               let anio = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
                                               //aqui dio error sin internet
                                               let mes = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
                                               
                                               let dia = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
                                               
                                                               let dateFormatter = DateFormatter()
                                                              dateFormatter.dateFormat = "dd/MM/yyyy"
                                                              dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                                                              let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                                                              dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                                                              var d = dateFormatter.string(from: date1!)
                                                              d = d.lowercased()
                                               print("fecha: \(d)")
                                               webView.isHidden=true
                                               webViewSinConexion.isHidden=false
                                               
                                               let decoded = circulares[p].contenido.stringByDecodingHTMLEntities
                                               mostrarCircular(tituloP1:tituloP1,tituloP2:tituloP2,decoded:decoded,nivel:nivel!,d:d)
                   
                       
                       
                       
                       
                                                          //webViewSinConexion.attributedText = attrStr
                                   
                              }
                   //}
    }
    
    @IBAction func btnAntClick(_ sender: UIButton) {
    
        
        if(clickeado==0){
            if(p>0){
                p=p-1
            }
        }
        clickeado=1
        
        
            p = p-1
            if(p>0){
                //self.partirTitulo(label1:self.lblTituloParte1,label2:self.lblTituloParte2,titulo:circulares[p].nombre)
                               //lblNivel.text = circulares[p].nivel
                
                if(p<ids.count){
                               
                                let nextId = ids[p]
                                globalId=nextId
                                //leer al server
                               self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: nextId)
                                //leer local
                                self.leeCirc(idCircular:Int(nextId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                                
                                let f = self.getFavorita(idCircular:Int(nextId) ?? 0)
                                if(f==1){
                                 self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                                }else{
                                 self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                                }
                                if(self.tipoCircular==5){
                                    let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                    if(leida==0){
                                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                    }
                                }else{
                                    let leida = self.getLeida(idCircular: Int(nextId) ?? 0, tabla: "appCircularCHMD")
                                    if(leida==0){
                                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                    }
                                }
                
                
                
            }
                
                
                
            webView.isHidden=true
            webViewSinConexion.isHidden=false
                let f = self.getFavorita(idCircular:Int(circulares[p].id) ?? 0)
            if(f==1){
             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
            }else{
             self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
            }
                
                if(self.tipoCircular==5){
                    let leida = self.getLeida(idCircular: Int(circulares[p].id) ?? 0, tabla: "appCircularCHMD")
                    if(leida==0){
                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                    }
                }else{
                    let leida = self.getLeida(idCircular: Int(circulares[p].id) ?? 0, tabla: "appCircularCHMD")
                    if(leida==0){
                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                    }
                }
                
                
                
             let titulo = circulares[p].nombre
              let tituloP1 = self.partirTituloP1(titulo: titulo)
              let tituloP2 = self.partirTituloP2(titulo: titulo)
              let nivel = circulares[p].nivel
              let anio = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
              //aqui dio error sin internet
              let mes = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
              
              let dia = circulares[p].fecha.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
              
                              let dateFormatter = DateFormatter()
                             dateFormatter.dateFormat = "dd/MM/yyyy"
                             dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                             let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                             dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                             let d = dateFormatter.string(from: date1!)
              webView.isHidden=true
              webViewSinConexion.isHidden=false
              
              let decoded = circulares[p].contenido.stringByDecodingHTMLEntities
                mostrarCircular(tituloP1:tituloP1,tituloP2:tituloP2,decoded:decoded,nivel:nivel!,d:d)
               
                         //webViewSinConexion.attributedText = attrStr
                            
               }
        
           // }
            
        
    }
    
   func eliminaFavoritosCirculares(idCircular:Int,idUsuario:Int){
       let fileUrl = try!
           FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
       
       if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
           print("Error en la base de datos")
       }else{
           
           //La base de datos abrió correctamente
           var statement:OpaquePointer?
           
            //Vaciar la tabla
           
          
           let query = "UPDATE appCircularCHMD SET favorita=0 WHERE idCircular=\(idCircular) AND idUsuario=\(idUsuario) and tipo=1"
           
           if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
               print("Error")
           }
           
          
           if sqlite3_step(statement) == SQLITE_DONE {
                   print("Circular actualizada correctamente")
               }else{
                   print("Circular no se pudo eliminar")
               }
               
           }
           
   }
    
    func eliminaCircular(idCircular:Int,idUsuario:Int){
           let fileUrl = try!
               FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
           
           if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
               print("Error en la base de datos")
           }else{
               
               //La base de datos abrió correctamente
               var statement:OpaquePointer?
               
                //Vaciar la tabla
               
              
               let query = "UPDATE appCircularCHMD SET eliminada=1,favorita=0,leida=1 WHERE idCircular=\(idCircular) AND idUsuario=\(idUsuario) and tipo=1"
               
               if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                   print("Error")
               }
               
              
               if sqlite3_step(statement) == SQLITE_DONE {
                       print("Circular actualizada correctamente")
                       //self.btnSiguienteClick(self)
                   btnSiguiente.sendActions(for: .touchUpInside)
                   }else{
                       print("Circular no se pudo eliminar")
                   }
                   
               }
        
        
        
        
               
       }
       
    
    
    func leeNotificacion(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
           
            let query = "UPDATE appCircularCHMD SET leida=0 WHERE idCircular=\(idCircular) AND tipo=2"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
           
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Notificacion actualizada correctamente")
                
                let totalNotif = contarNotificaciones()
                UserDefaults.standard.set(totalNotif, forKey: "totalNotif")
                
                
                }else{
                    print("Notificacion no se pudo actualizar")
                }
                
            }
            
    }
    
    
    
    
    
    
    
    func leeCirc(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
           
            let query = "UPDATE appCircularCHMD SET leida=1 WHERE idCircular=\(idCircular) AND idUsuario=\(idUsuario) AND tipo=1"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
           
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular actualizada correctamente")
                }else{
                    print("Circular no se pudo eliminar")
                }
                
            }
            
    }
    
    @IBAction func btnFavoritoClick(_ sender: UIButton) {
        
        if(tipoCircular != 5){
            if(ConexionRed.isConnectedToNetwork()){
               
              
                let f = self.getFavorita(idCircular:Int(globalId) ?? 0)
                print(globalId)
                if(f==1){
                 self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono"), for: .normal)
                    //eliminarla de las fav
                    self.eliminaFavoritosCirculares(idCircular:Int(globalId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                    
                     self.favCircular(direccion: self.urlBase+"elimFavCircular.php", usuario_id: self.idUsuario, circular_id: globalId)
                    
                     self.showToast(message:"Se eliminó de las favoritas", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
                    
                }else{
                 self.btnFavorita.setImage(UIImage(named:"estrella_fav_icono_completo"), for: .normal)
                   
                   self.actualizaFavoritosCirculares(idCircular:Int(globalId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
                    
                     self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: globalId)
                    
                     self.showToast(message:"Marcada como favorita", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
                    
                }
                
            }else{
                var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                           alert.show()
            }
        }else{
            var alert = UIAlertView(title: "No Permitido", message: "Esta opción solo funciona con una circular y no una notificación", delegate: nil, cancelButtonTitle: "Aceptar")
             alert.show()
        }
        
        
    }
    
    
    @IBAction func btnFavClick(_ sender: UIButton) {
        //Hacer favorita la circular
        
        if(ConexionRed.isConnectedToNetwork()){
           // let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas agregar esta circular a tus favoritas?", preferredStyle: .alert)
            
            // Create OK button with action handler
            //let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: globalId)
            self.actualizaFavoritosCirculares(idCircular:Int(globalId) ?? 0,idUsuario:Int(self.idUsuario) ?? 0)
            
            //})
            
            // Create Cancel button with action handlder
            //let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                
            //}
            
            //Add OK and Cancel button to dialog message
            //dialogMessage.addAction(ok)
            //dialogMessage.addAction(cancel)
            
            // Present dialog message to user
            //self.present(dialogMessage, animated: true, completion: nil)
        }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                       alert.show()
        }
        
        
        
        
    }
    
    
    
    func actualizaFavoritosCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            self.circulares.removeAll()
            let query = "UPDATE appCircularCHMD SET favorita=1 WHERE idCircular=\(idCircular) AND idUsuario=\(idUsuario) and tipo=1"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular actualizada correctamente")
                }else{
                    print("Circular no se pudo actualizar")
                }
                
            }
            
    }
    
    @IBAction func btnCompartirClick(_ sender: UIButton) {
        //var link:String=""
        //Crear el link mediante bit.ly, para pruebas
        circularUrl = "https://www.chmd.edu.mx/WebAdminCirculares/ws/getCircularId6?id=\(id)"
        compartir(message:"Compartir",link:circularUrl)
        /*Bitly.shorten(circularUrl) { response, error in
            var link = response?.bitlink ?? ""
            self.compartir(message:"Compartir",link:link)
            
            print(response?.bitlink)
            print(response?.applink)
            print(response?.statusCode)
            print(response?.statusText)
        }*/
        
        /*guard let link = URL(string: circularUrl) else { return }
        let dynamicLinksDomainURIPrefix:String = "https://chmd1.page.link/"
        let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
        linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "mx.edu.CHMD1")
        linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "mx.edu.chmd1")
        
        guard let longDynamicLink = linkBuilder?.url else { return }
        print("The long URL is: \(longDynamicLink)")
        
        
        linkBuilder?.shorten() { url, warnings, error in
          guard let url = url, error != nil else { return }
          print("The short URL is: \(url)")
        }
        */
        
        
        
    }
    
    
   func compartir(message: String, link: String) {
       /*if let link = NSURL(string: link) {
           let objectsToShare = [message,link] as [Any]
           let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
           self.present(activityVC, animated: true, completion: nil)
       }*/
    
    let date = Date()
    let msg = message
    let urlWhats = "whatsapp://send?text=\(msg+"\n"+link)"

    if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
        if let whatsappURL = NSURL(string: urlString) {
            if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                UIApplication.shared.openURL(whatsappURL as URL)
            } else {
                print("Por favor instale whatsapp")
            }
        }
    }
    
   }
    
    
    
    @IBAction func btnNoLeerClick(_ sender: Any) {
        
         if(ConexionRed.isConnectedToNetwork()){
            //let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas marcar esta circular como no leída?", preferredStyle: .alert)
            
            // Create OK button with action handler
            //let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: self.id)
            //})
            
            // Create Cancel button with action handlder
            //let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                
            //}
            
            //Add OK and Cancel button to dialog message
            //dialogMessage.addAction(ok)
            //dialogMessage.addAction(cancel)
            
            // Present dialog message to user
            //self.present(dialogMessage, animated: true, completion: nil)
         }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                  alert.show()
        }

        
        
    }
    var pos = UserDefaults.standard.integer(forKey:"posicion")
    @IBAction func btnEliminaClick(_ sender: UIButton) {
       if(ConexionRed.isConnectedToNetwork()){
        
        var tituloEliminar:String
        if(self.tipoCircular != 5){
            tituloEliminar = "¿Deseas eliminar esta circular?"
        }else{
            tituloEliminar = "¿Deseas eliminar esta notificación?"
        }
        
        
                  let dialogMessage = UIAlertController(title: "CHMD", message: tituloEliminar, preferredStyle: .alert)
                  
                  // Create OK button with action handler
                  let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                    self.delCircularSinDialogo(direccion: self.urlBase+self.delMetodo, usuario_id:self.idUsuario, circular_id: self.globalId)
                    self.eliminaCircular(idCircular:Int(self.globalId) ?? 0 ,idUsuario:Int(self.idUsuario) ?? 0)
                      //Pasar a la siguiente
                    //self.btnSiguienteClick(self)
                      self.btnSiguiente.sendActions(for: .touchUpInside)
                      /*self.pos = self.pos+1
                      
                      //if(self.posicion<self.ids.count){
                          var nextId = self.ids[self.pos]
                          var nextTitulo = self.titulos[self.pos]
                          var nextFecha = self.fechas[self.pos]
                          
                          var nextHoraIniIcs = self.horasInicioIcs[self.pos]
                          var nextHoraFinIcs = self.horasFinIcs[self.pos]
                          var nextFechaIcs = self.fechasIcs[self.pos]
                          var nextNivel = self.niveles[self.pos]
                          
                          if(nextHoraIniIcs != "00:00:00"){
                              self.imbCalendario.isHidden=false
                          }
                          
                          
                          self.circularTitulo = nextTitulo
                          let link = URL(string:self.urlBase+"getCircularId6.php?id=\(nextId)")!
                          let request = URLRequest(url: link)
                          self.circularUrl = self.urlBase+"getCircularId6.php?id=\(nextId)"
                          self.webView.load(request)
                          self.title = "Circular"
                          self.id = nextId;
                     */
                      
                      
                      
                  })
                  
                  // Create Cancel button with action handlder
                  let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                      
                  }
                  
                  //Add OK and Cancel button to dialog message
                  dialogMessage.addAction(ok)
                  dialogMessage.addAction(cancel)
                  
                  // Present dialog message to user
                  self.present(dialogMessage, animated: true, completion: nil)
              }else{
                  var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                 alert.show()
              }
              
    }
    
    @IBAction func btnEliminarClick(_ sender: UIButton) {
        
        if(ConexionRed.isConnectedToNetwork()){
            
            
            var tituloEliminar:String
                   if(self.tipoCircular != 5){
                       tituloEliminar = "¿Deseas eliminar esta circular?"
                   }else{
                       tituloEliminar = "¿Deseas eliminar esta notificación?"
                   }
            
            
            let dialogMessage = UIAlertController(title: "CHMD", message: tituloEliminar, preferredStyle: .alert)
            
            // Create OK button with action handler
            let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                self.delCircularSinDialogo(direccion: self.urlBase+self.delMetodo, usuario_id:self.idUsuario, circular_id: self.globalId)
                 self.eliminaCircular(idCircular:Int(self.globalId) ?? 0 ,idUsuario:Int(self.idUsuario) ?? 0)
                //Pasar a la siguiente
               
                /*self.pos = self.pos+1
                
               
                    var nextId = self.ids[self.pos]
                    var nextTitulo = self.titulos[self.pos]
                    var nextFecha = self.fechas[self.pos]
                    
                    var nextHoraIniIcs = self.horasInicioIcs[self.pos]
                    var nextHoraFinIcs = self.horasFinIcs[self.pos]
                    var nextFechaIcs = self.fechasIcs[self.pos]
                    var nextNivel = self.niveles[self.pos]
                    
                    if(nextHoraIniIcs != "00:00:00"){
                        self.imbCalendario.isHidden=false
                    }
                     //self.lblNivel.text = nextNivel
                    
                    self.circularTitulo = nextTitulo
                    let link = URL(string:self.urlBase+"getCircularId6.php?id=\(nextId)")!
                    let request = URLRequest(url: link)
                    self.circularUrl = self.urlBase+"getCircularId6.php?id=\(nextId)"
                    self.webView.load(request)
                    self.title = "Circular"*/
                    //nextTitulo.uppercased()
                    
                    /*let anio = nextFecha.components(separatedBy: " ")[0].components(separatedBy: "-")[0]
                    let mes = nextFecha.components(separatedBy: " ")[0].components(separatedBy: "-")[1]
                    let dia = nextFecha.components(separatedBy: " ")[0].components(separatedBy: "-")[2]
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                    dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                    let date1 = dateFormatter.date(from: "\(dia)/\(mes)/\(anio)")
                    dateFormatter.dateFormat = "d 'de' MMMM 'de' YYYY"
                    let d = dateFormatter.string(from: date1!)
                    self.lblFechaCircular.text = d*/
                
                    //self.lblTituloParte1.text=nextTitulo
                    
                    
                    //self.id = nextId;
               
                
                
                
            })
            
            // Create Cancel button with action handlder
            let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                
            }
            
            //Add OK and Cancel button to dialog message
            dialogMessage.addAction(ok)
            dialogMessage.addAction(cancel)
            
            // Present dialog message to user
            self.present(dialogMessage, animated: true, completion: nil)
        }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
           alert.show()
        }
        
        
    }
    
    
    //Esta función es para ejecutar una petición POST
    func shareCircular(direccion:String){
        let url = URL(string: direccion)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("error: \(error)")
            } else {
                if let response = response as? HTTPURLResponse {
                    print("statusCode: \(response.statusCode)")
                }
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("data: \(dataString)")
                }
            }
        }
        task.resume()
    }
    
    func favCircular(direccion:String, usuario_id:String, circular_id:String){
        let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
         Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
            switch (response.result) {
            case .success:
                print(response)
               
                
            case .failure:
                print(Error.self)
                self.showToast(message:"Error", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
            }
        }
    }
    
    func leerCircular(direccion:String, usuario_id:String, circular_id:String){
        let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
        Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
            switch (response.result) {
            case .success:
                print(response)
                //UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                break
            case .failure:
                print(Error.self)
            }
        }
    }
    
    
    func noleerCircular(direccion:String, usuario_id:String, circular_id:String){
        let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
        Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
            switch (response.result) {
            case .success:
                print(response)
                 self.showToast(message:"Marcada como no leída", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
                break
            case .failure:
                print(Error.self)
            }
        }
    }
    
    func delCircular(direccion:String, usuario_id:String, circular_id:String){
        
        
        var tituloEliminar:String
               if(self.tipoCircular != 5){
                   tituloEliminar = "¿Deseas eliminar esta circular?"
               }else{
                   tituloEliminar = "¿Deseas eliminar esta notificación?"
               }
        
        
        let dialogMessage = UIAlertController(title: "CHMD", message: tituloEliminar, preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
            let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
            Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
                switch (response.result) {
                case .success:
                    print(response)
                    break
                case .failure:
                    print(Error.self)
                }
            }
        })
        
        // Create Cancel button with action handlder
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
            
        }
        
        //Add OK and Cancel button to dialog message
        dialogMessage.addAction(ok)
        dialogMessage.addAction(cancel)
        
        // Present dialog message to user
        self.present(dialogMessage, animated: true, completion: nil)
        
        
        
    }
    
    
    func delCircularSinDialogo(direccion:String, usuario_id:String, circular_id:String){
        
       
            let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
            Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
                switch (response.result) {
                case .success:
                    print(response)
                    break
                case .failure:
                    print(Error.self)
                }
            }
        
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
   /* func leerCirculares(){
     
     let fileUrl = try!
                FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
     
     if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
         print("error opening database")
     }
     
        let consulta = "SELECT * FROM appCirculares"
        var queryStatement: OpaquePointer? = nil
     var imagen:UIImage
     imagen = UIImage.init(named: "appmenu05")!
     
     if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
    
        
         
          while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                  let id = sqlite3_column_int(queryStatement, 0)
                     var titulo:String="";
             
                    if let name = sqlite3_column_text(queryStatement, 2) {
                        titulo = String(cString: name)
                       } else {
                        print("name not found")
                    }
             
             
                     var cont:String="";
             
                    if let contenido = sqlite3_column_text(queryStatement,3) {
                        cont = String(cString: contenido)
                       } else {
                        print("name not found")
                    }
           
                     let leida = sqlite3_column_int(queryStatement, 5)
                     let favorita = sqlite3_column_int(queryStatement, 6)
                     let eliminada = sqlite3_column_int(queryStatement, 8)
                     
             
                                     var fechaIcs:String="";
                                     if let fIcs = sqlite3_column_text(queryStatement, 10) {
                                       fechaIcs = String(cString: fIcs)
                                      } else {
                                       print("name not found")
                                   }
                    
               var hIniIcs:String="";
               if  let horaInicioIcs = sqlite3_column_text(queryStatement, 11) {
                 hIniIcs = String(cString: horaInicioIcs)
                } else {
                 print("name not found")
             }
             
              var hFinIcs:String="";
              if  let horaFinIcs = sqlite3_column_text(queryStatement, 12) {
                  hFinIcs = String(cString: horaFinIcs)
                  } else {
                    print("name not found")
                  }
             var nivel:String="";
             if  let nv = sqlite3_column_text(queryStatement, 12) {
                 nivel = String(cString: nv)
                 } else {
                   print("name not found")
                 }
             
                     let adj = sqlite3_column_int(queryStatement, 13)
                     if(Int(leida)>0){
                        imagen = UIImage.init(named: "circle_white")!
                      }
                     
                     if(Int(leida) == 1){
                 
                     }
             
                     if(Int(favorita)==1){
                        imagen = UIImage.init(named: "star")!
                       }
                     var noLeida:Int = 0
                     if(Int(leida) == 0){
                         noLeida = 1
                         imagen = UIImage.init(named: "circle")!
                        }
             var fechaCircular="";
             if let fecha = sqlite3_column_text(queryStatement, 8) {
                 fechaCircular = String(cString: fecha)
                 //print("fecha c: \(fechaCircular)")
                print("texto c: \(cont)")
                } else {
                 print("name not found")
             }
             
             
            self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont,adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:0,favorita:Int(favorita)))
           }
         
       

          }
         else {
          print("SELECT statement could not be prepared")
        }

        sqlite3_finalize(queryStatement)
    }
    */
    
    
    func leerCirculares(){
           print("Leer desde la base de datos local")
           let fileUrl = try!
                      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
           
           if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
               print("error opening database")
           }
           
           /*
            idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
            */
           
              let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto FROM appCircularCHMD WHERE tipo=1"
           var queryStatement: OpaquePointer? = nil
           var imagen:UIImage
           imagen = UIImage.init(named: "appmenu05")!
           
           if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
          
              
               
                while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                        let id = sqlite3_column_int(queryStatement, 0)
                           var titulo:String="";
                   
                          if let name = sqlite3_column_text(queryStatement, 1) {
                              titulo = String(cString: name)
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
                   
                           /*if(Int(favorita)==1 && Int(leida) == 0){
                               imagen = UIImage.init(named: "circle")!
                            }
                           if(Int(favorita)==1 && Int(leida) == 1){
                               imagen = UIImage.init(named: "circle_white")!
                           }*/
                   
                           var noLeida:Int = 0
                          
                   var fechaCircular="";
                   if let fecha = sqlite3_column_text(queryStatement, 6) {
                       fechaCircular = String(cString: fecha)
                      
                   } else {
                       print("name not found")
                   }
                   
                   
                   //if(eliminada==0 ){
                      self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
                    
                    
                    self.ids.append("\(id)")
                    
                  // }
                  
                 }
               
              
                }
               else {
                print("SELECT statement could not be prepared")
              }

              sqlite3_finalize(queryStatement)
          }
    
    func leerCirculares(idCircular:Int){
           print("Leer desde la base de datos local")
           let fileUrl = try!
                      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
           
           if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
               print("error opening database")
           }
           
           /*
            idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
            */
           
              let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto FROM appCircularCHMD WHERE idCircular=\(idCircular)"
           var queryStatement: OpaquePointer? = nil
           var imagen:UIImage
           imagen = UIImage.init(named: "appmenu05")!
           
           if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
          
              
               
                while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                        let id = sqlite3_column_int(queryStatement, 0)
                           var titulo:String="";
                   
                          if let name = sqlite3_column_text(queryStatement, 1) {
                              titulo = String(cString: name)
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
                   
                           /*if(Int(favorita)==1 && Int(leida) == 0){
                               imagen = UIImage.init(named: "circle")!
                            }
                           if(Int(favorita)==1 && Int(leida) == 1){
                               imagen = UIImage.init(named: "circle_white")!
                           }*/
                   
                           var noLeida:Int = 0
                          
                   var fechaCircular="";
                   if let fecha = sqlite3_column_text(queryStatement, 6) {
                       fechaCircular = String(cString: fecha)
                      
                   } else {
                       print("name not found")
                   }
                   
                   
                   //if(eliminada==0 ){
                      self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
                    
                    
                    self.ids.append("\(id)")
                    
                   //}
                  
                 }
               
              
                }
               else {
                print("SELECT statement could not be prepared")
              }

              sqlite3_finalize(queryStatement)
          }
    func getFavorita(idCircular:Int)->Int{
              print("Leer desde la base de datos local")
              let fileUrl = try!
                         FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
              
              if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
                  print("error opening database")
              }
              
              /*
               idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
               */
              
                 let consulta = "SELECT favorita FROM appCircularCHMD WHERE idCircular=\(idCircular) AND tipo=1"
              var queryStatement: OpaquePointer? = nil
              var imagen:UIImage
              imagen = UIImage.init(named: "appmenu05")!
              
              if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
             
                 
                  
                   while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let favorita = sqlite3_column_int(queryStatement, 0)
                    esFavorita = Int(favorita)
                    }
                  
                 
                   }
                  else {
                   print("SELECT statement could not be prepared")
                 }

                 sqlite3_finalize(queryStatement)
        
               return esFavorita
             }
    
    
    func getLeida(idCircular:Int,tabla:String)->Int{
              print("Leer desde la base de datos local")
              let fileUrl = try!
                         FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
              
              if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
                  print("error opening database")
              }
              
              /*
               idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
               */
              
                 let consulta = "SELECT leida FROM \(tabla) WHERE idCircular=\(idCircular)"
              var queryStatement: OpaquePointer? = nil
              var imagen:UIImage
              imagen = UIImage.init(named: "appmenu05")!
              
              if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
             
                 
                  
                   while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let favorita = sqlite3_column_int(queryStatement, 0)
                    esFavorita = Int(favorita)
                    }
                  
                 
                   }
                  else {
                   print("SELECT statement could not be prepared")
                 }

                 sqlite3_finalize(queryStatement)
        
               return esFavorita
             }
    
    
    func leerNotificaciones(){
     print("Leer desde la base de datos local")
     let fileUrl = try!
                FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
     
     if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
         print("error opening database")
     }
     
     /*
      idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
      */
     
        let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto FROM appCircularCHMD WHERE tipo=2"
     var queryStatement: OpaquePointer? = nil
     var imagen:UIImage
     imagen = UIImage.init(named: "appmenu05")!
     
     if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
    
        
         
          while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                  let id = sqlite3_column_int(queryStatement, 0)
                     var titulo:String="";
             
                    if let name = sqlite3_column_text(queryStatement, 1) {
                        titulo = String(cString: name)
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
             
                     let adj = sqlite3_column_int(queryStatement, 11)
                    
                     
                     if(Int(leida) == 1){
                        imagen = UIImage.init(named: "circle_white")!
                     }else{
                         imagen = UIImage.init(named: "circle")!
                     }
             
                     if(Int(favorita)==1){
                        imagen = UIImage.init(named: "circle_white")!
                     }
             
                     /*if(Int(favorita)==1 && Int(leida) == 0){
                         imagen = UIImage.init(named: "circle")!
                      }
                     if(Int(favorita)==1 && Int(leida) == 1){
                         imagen = UIImage.init(named: "circle_white")!
                     }*/
             
                     var noLeida:Int = 0
                    
             var fechaCircular="";
             if let fecha = sqlite3_column_text(queryStatement, 6) {
                 fechaCircular = String(cString: fecha)
                
             } else {
                 print("name not found")
             }
             
             
             //if(eliminada==0 ){
                self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
             //}
            
           }
         
        
          }
         else {
          print("SELECT statement could not be prepared")
        }

        sqlite3_finalize(queryStatement)
    }
    
    func leerCircularesNoLeidas(){
     print("Leer desde la base de datos local")
     let fileUrl = try!
                FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
     
     if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
         print("error opening database")
     }
     
     /*
      idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
      */
     
        let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto  FROM appCircularCHMD WHERE leida=0 and favorita=0 AND tipo=1"
     var queryStatement: OpaquePointer? = nil
         var imagen:UIImage
         imagen = UIImage.init(named: "appmenu05")!
         
         if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
        
            
             
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                      let id = sqlite3_column_int(queryStatement, 0)
                         var titulo:String="";
                 
                        if let name = sqlite3_column_text(queryStatement, 1) {
                            titulo = String(cString: name)
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
                 
                         let adj = sqlite3_column_int(queryStatement, 11)
                        
                         
                         if(Int(leida) == 1){
                            imagen = UIImage.init(named: "circle_white")!
                         }else{
                             imagen = UIImage.init(named: "circle")!
                         }
                 
                         if(Int(favorita)==1){
                            imagen = UIImage.init(named: "circle_white")!
                         }
                 
                         /*if(Int(favorita)==1 && Int(leida) == 0){
                             imagen = UIImage.init(named: "circle")!
                          }
                         if(Int(favorita)==1 && Int(leida) == 1){
                             imagen = UIImage.init(named: "circle_white")!
                         }*/
                 
                         var noLeida:Int = 0
                        
                 var fechaCircular="";
                 if let fecha = sqlite3_column_text(queryStatement, 6) {
                     fechaCircular = String(cString: fecha)
                    
                 } else {
                     print("name not found")
                 }
                 
                 
               
                    self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
                 
                
               }
             
            
              }
             else {
              print("SELECT statement could not be prepared")
            }

            sqlite3_finalize(queryStatement)
    }
    
    func leerCircularesEliminadas(){
     print("Leer desde la base de datos local")
     let fileUrl = try!
                FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
     
     if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
         print("error opening database")
     }
     
     /*
      idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
      */
     
        let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto  FROM appCircularCHMD WHERE eliminada=1 AND tipo=1"
     var queryStatement: OpaquePointer? = nil
         var imagen:UIImage
         imagen = UIImage.init(named: "appmenu05")!
         
         if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
        
            
             
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                      let id = sqlite3_column_int(queryStatement, 0)
                         var titulo:String="";
                 
                        if let name = sqlite3_column_text(queryStatement, 1) {
                            titulo = String(cString: name)
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
                 
                         let adj = sqlite3_column_int(queryStatement, 11)
                        
                         
                         if(Int(leida) == 1){
                            imagen = UIImage.init(named: "circle_white")!
                         }else{
                             imagen = UIImage.init(named: "circle")!
                         }
                 
                         if(Int(favorita)==1){
                            imagen = UIImage.init(named: "circle_white")!
                         }
                 
                         /*if(Int(favorita)==1 && Int(leida) == 0){
                             imagen = UIImage.init(named: "circle")!
                          }
                         if(Int(favorita)==1 && Int(leida) == 1){
                             imagen = UIImage.init(named: "circle_white")!
                         }*/
                 
                         var noLeida:Int = 0
                        
                 var fechaCircular="";
                 if let fecha = sqlite3_column_text(queryStatement, 6) {
                     fechaCircular = String(cString: fecha)
                    
                 } else {
                     print("name not found")
                 }
                 
                 
                 
                    self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
                 
                
               }
             
            
              }
             else {
              print("SELECT statement could not be prepared")
            }

            sqlite3_finalize(queryStatement)
    }
    
    func leerCircularesFavoritas(){
     print("Leer desde la base de datos local")
     let fileUrl = try!
                FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
     
     if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
         print("error opening database")
     }
     
     /*
      idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
      */
     
        let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto  FROM appCircularCHMD WHERE favorita=1 AND tipo=1"
    var queryStatement: OpaquePointer? = nil
         var imagen:UIImage
         imagen = UIImage.init(named: "appmenu05")!
         
         if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
        
            
             
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                      let id = sqlite3_column_int(queryStatement, 0)
                         var titulo:String="";
                 
                        if let name = sqlite3_column_text(queryStatement, 1) {
                            titulo = String(cString: name)
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
                 
                         let adj = sqlite3_column_int(queryStatement, 11)
                        
                         
                         if(Int(leida) == 1){
                            imagen = UIImage.init(named: "circle_white")!
                         }else{
                             imagen = UIImage.init(named: "circle")!
                         }
                 
                         if(Int(favorita)==1){
                            imagen = UIImage.init(named: "circle_white")!
                         }
                 
                         /*if(Int(favorita)==1 && Int(leida) == 0){
                             imagen = UIImage.init(named: "circle")!
                          }
                         if(Int(favorita)==1 && Int(leida) == 1){
                             imagen = UIImage.init(named: "circle_white")!
                         }*/
                 
                         var noLeida:Int = 0
                        
                 var fechaCircular="";
                 if let fecha = sqlite3_column_text(queryStatement, 6) {
                     fechaCircular = String(cString: fecha)
                    
                 } else {
                     print("name not found")
                 }
                 
                 
                 
                    self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
                 
                
               }
             
            
              }
             else {
              print("SELECT statement could not be prepared")
            }

            sqlite3_finalize(queryStatement)
    }
    
    
    func leerCircular(idCircular:Int){
     print("Leer desde la base de datos local")
     let fileUrl = try!
                FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
     
     if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
         print("error opening database")
     }
     
     /*
      idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
      */
     
        let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto  FROM appCircularCHMD WHERE idCircular=\(idCircular) AND tipo=1"
        var queryStatement: OpaquePointer? = nil
     var imagen:UIImage
     imagen = UIImage.init(named: "appmenu05")!
     
     if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
    
        
         
          while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                  let id = sqlite3_column_int(queryStatement, 0)
                     var titulo:String="";
             
                    if let name = sqlite3_column_text(queryStatement, 1) {
                        titulo = String(cString: name)
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
                     print("leida: \(leida)")
                     print("favorita: \(favorita)")
             
                      var fechaIcs:String="";
                      if let fIcs = sqlite3_column_text(queryStatement, 6) {
                      fechaIcs = String(cString: fIcs)
                      } else {
                           print("name not found")
                      }
             
                            
                                 
             
                    
               var hIniIcs:String="";
               if  let horaInicioIcs = sqlite3_column_text(queryStatement, 8) {
                 hIniIcs = String(cString: horaInicioIcs)
                } else {
                 print("name not found")
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
             
                     let adj = sqlite3_column_int(queryStatement, 14)
                    
                     
                     if(Int(leida) == 1){
                        imagen = UIImage.init(named: "circle_white")!
                     }else{
                         imagen = UIImage.init(named: "circle")!
                     }
             
                     if(Int(favorita)==1){
                        imagen = UIImage.init(named: "circle_white")!
                     }
             
                     /*if(Int(favorita)==1 && Int(leida) == 0){
                         imagen = UIImage.init(named: "circle")!
                      }
                     if(Int(favorita)==1 && Int(leida) == 1){
                         imagen = UIImage.init(named: "circle_white")!
                     }*/
             
                     var noLeida:Int = 0
                    
             var fechaCircular="";
             if let fecha = sqlite3_column_text(queryStatement, 6) {
                 fechaCircular = String(cString: fecha)
                
             } else {
                 print("name not found")
             }
             
            print("FECHA \(fechaCircular)")
             
             //if(eliminada==0 ){
                self.circulares.append(CircularTodas(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita)))
            // }
            
           }
         
        
          }
         else {
          print("SELECT statement could not be prepared")
        }

        sqlite3_finalize(queryStatement)
    }
    
    func obtenerCirculares(uri:String){
        
        Alamofire.request(uri)
            .responseJSON { response in
                // check for errors
                guard response.result.error == nil else {
                    // got an error in getting the data, need to handle it
                    print("error en la consulta")
                    print(response.result.error!)
                    return
                }
                /*
                 [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                 */
                
                if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                    for diccionario in diccionarios{
                        //print(diccionario)
                        
                        guard let id = diccionario["id"] as? String else {
                            print("No se pudo obtener el id")
                            return
                        }
                        print(id)
                        
                        guard let titulo = diccionario["titulo"] as? String else {
                            print("No se pudo obtener el titulo")
                            return
                        }
                      guard let fecha = diccionario["updated_at"] as? String else {
                                                                          print("No se pudo obtener la fecha")
                                                                          return
                                                                      }
                        guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                return
                                              }
                                              guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                       return
                                                                     }
                                              
                                             
                                              guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                              return
                                                                                            }
                                              
                                              //Esto si viene null desde el servicio web
                                                                var nv:String?
                                                                     if (diccionario["nivel"] == nil){
                                                                         nv=""
                                                                     }else{
                                                                         nv=diccionario["nivel"] as? String
                                                                     }
                        guard let eliminada = diccionario["eliminado"] as? String else {
                                                   return
                                               }
                       
                                               self.ids.append(id)
                                               self.titulos.append(titulo)
                                               self.fechas.append(fecha)
                                                  
                                              self.fechasIcs.append(fechaIcs)
                                              self.horasInicioIcs.append(horaInicioIcs)
                                              self.horasFinIcs.append(horaFinIcs)
                                              self.niveles.append(nv ?? "")
                        
                   
                }
                
                
            
        
    }
        
 }
        
        
        
        func obtenerCirculares(uri:String){
               
               Alamofire.request(uri)
                   .responseJSON { response in
                       // check for errors
                       guard response.result.error == nil else {
                           // got an error in getting the data, need to handle it
                           print("error en la consulta")
                           print(response.result.error!)
                           return
                       }
                       /*
                        [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                        */
                       
                       if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                           for diccionario in diccionarios{
                               //print(diccionario)
                               
                               guard let id = diccionario["id"] as? String else {
                                   print("No se pudo obtener el id")
                                   return
                               }
                               //print(id)
                            print("Tengo el id")
                               guard let titulo = diccionario["titulo"] as? String else {
                                   print("No se pudo obtener el titulo")
                                   return
                               }
                             guard let fecha = diccionario["updated_at"] as? String else {
                                                                                 print("No se pudo obtener la fecha")
                                                                                 return
                                                                             }
                               guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                       return
                                                     }
                                                     guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                              return
                                                                            }
                                                     
                                                    
                                                     guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                                     return
                                                                                                   }
                                                     
                                                     //Esto si viene null desde el servicio web
                                                                       var nv:String?
                                                                            if (diccionario["nivel"] == nil){
                                                                                nv=""
                                                                            }else{
                                                                                nv=diccionario["nivel"] as? String
                                                                            }
                               guard let eliminada = diccionario["eliminado"] as? String else {
                                                          return
                                                      }
                              
                                                      self.ids.append(id)
                                                      self.titulos.append(titulo)
                                                      self.fechas.append(fecha)
                                                         
                                                     self.fechasIcs.append(fechaIcs)
                                                     self.horasInicioIcs.append(horaInicioIcs)
                                                     self.horasFinIcs.append(horaFinIcs)
                                                     self.niveles.append(nv ?? "")
                               
                          
                       }
                       
                       
                   
               
           }
               
        }
    
        
}
        
}
                
        
        
        func obtenerCirculares2(uri:String){
                   
                   Alamofire.request(uri)
                       .responseJSON { response in
                           // check for errors
                           guard response.result.error == nil else {
                               // got an error in getting the data, need to handle it
                               print("error en la consulta")
                               print(response.result.error!)
                               return
                           }
                           /*
                            [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                            */
                           
                           if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                               for diccionario in diccionarios{
                                   //print(diccionario)
                                   
                                   guard let id = diccionario["id"] as? String else {
                                       print("No se pudo obtener el id")
                                       return
                                   }
                                   print(id)
                                   
                                   guard let titulo = diccionario["titulo"] as? String else {
                                       print("No se pudo obtener el titulo")
                                       return
                                   }
                                 guard let fecha = diccionario["updated_at"] as? String else {
                                                                                     print("No se pudo obtener la fecha")
                                                                                     return
                                                                                 }
                                   guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                           return
                                                         }
                                                         guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                                  return
                                                                                }
                                                         
                                                        
                                                         guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                                         return
                                                                                                       }
                                                         
                                                         //Esto si viene null desde el servicio web
                                                                           var nv:String?
                                                                                if (diccionario["nivel"] == nil){
                                                                                    nv=""
                                                                                }else{
                                                                                    nv=diccionario["nivel"] as? String
                                                                                }
                                   guard let eliminada = diccionario["eliminado"] as? String else {
                                                              return
                                                          }
                                if(Int(eliminada)==0){
                                    self.ids.append(id)
                                                                                                self.titulos.append(titulo)
                                                                                                self.fechas.append(fecha)
                                                                                                   
                                                                                               self.fechasIcs.append(fechaIcs)
                                                                                               self.horasInicioIcs.append(horaInicioIcs)
                                                                                               self.horasFinIcs.append(horaFinIcs)
                                                                                               self.niveles.append(nv ?? "")
                                }
                                                                                    
                           }
                     }
                   
            }
        }
    
    
    
    func obtenerCircularesNoLeidas(uri:String){
               
               Alamofire.request(uri)
                   .responseJSON { response in
                       // check for errors
                       guard response.result.error == nil else {
                           // got an error in getting the data, need to handle it
                           print("error en la consulta")
                           print(response.result.error!)
                           return
                       }
                       /*
                        [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                        */
                       
                       if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                           for diccionario in diccionarios{
                               //print(diccionario)
                               
                               guard let id = diccionario["id"] as? String else {
                                   print("No se pudo obtener el id")
                                   return
                               }
                               print(id)
                               
                               guard let titulo = diccionario["titulo"] as? String else {
                                   print("No se pudo obtener el titulo")
                                   return
                               }
                             guard let fecha = diccionario["updated_at"] as? String else {
                                                                                 print("No se pudo obtener la fecha")
                                                                                 return
                                                                             }
                               guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                       return
                                                     }
                                                     guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                              return
                                                                            }
                                                     
                                                    
                                                     guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                                     return
                                                                                                   }
                                                     
                                                     //Esto si viene null desde el servicio web
                                                                       var nv:String?
                                                                            if (diccionario["nivel"] == nil){
                                                                                nv=""
                                                                            }else{
                                                                                nv=diccionario["nivel"] as? String
                                                                            }
                               guard let leido = diccionario["leido"] as? String else {
                                                          return
                                                      }
                            if(Int(leido)==0){
                                self.ids.append(id)
                                                                                            self.titulos.append(titulo)
                                                                                            self.fechas.append(fecha)
                                                                                               
                                                                                           self.fechasIcs.append(fechaIcs)
                                                                                           self.horasInicioIcs.append(horaInicioIcs)
                                                                                           self.horasFinIcs.append(horaFinIcs)
                                                                                           self.niveles.append(nv ?? "")
                            }
                                                                                
                       }
                 }
               
        }
    }
    
    
    func obtenerCircularesEliminadas(uri:String){
               
               Alamofire.request(uri)
                   .responseJSON { response in
                       // check for errors
                       guard response.result.error == nil else {
                           // got an error in getting the data, need to handle it
                           print("error en la consulta")
                           print(response.result.error!)
                           return
                       }
                       /*
                        [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                        */
                       
                       if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                           for diccionario in diccionarios{
                               //print(diccionario)
                               
                               guard let id = diccionario["id"] as? String else {
                                   print("No se pudo obtener el id")
                                   return
                               }
                               print(id)
                               
                               guard let titulo = diccionario["titulo"] as? String else {
                                   print("No se pudo obtener el titulo")
                                   return
                               }
                             guard let fecha = diccionario["updated_at"] as? String else {
                                                                                 print("No se pudo obtener la fecha")
                                                                                 return
                                                                             }
                               guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                       return
                                                     }
                                                     guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                              return
                                                                            }
                                                     
                                                    
                                                     guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                                     return
                                                                                                   }
                                                     
                                                     //Esto si viene null desde el servicio web
                                                                       var nv:String?
                                                                            if (diccionario["nivel"] == nil){
                                                                                nv=""
                                                                            }else{
                                                                                nv=diccionario["nivel"] as? String
                                                                            }
                               guard let eliminado = diccionario["eliminado"] as? String else {
                                                          return
                                                      }
                            if(Int(eliminado)==1){
                                self.ids.append(id)
                                                                                            self.titulos.append(titulo)
                                                                                            self.fechas.append(fecha)
                                                                                               
                                                                                           self.fechasIcs.append(fechaIcs)
                                                                                           self.horasInicioIcs.append(horaInicioIcs)
                                                                                           self.horasFinIcs.append(horaFinIcs)
                                                                                           self.niveles.append(nv ?? "")
                            }
                                                                                
                       }
                 }
               
        }
    }
        
    
    
    func obtenerNotificaciones(uri:String){
               
               Alamofire.request(uri)
                   .responseJSON { response in
                       // check for errors
                       guard response.result.error == nil else {
                           // got an error in getting the data, need to handle it
                           print("error en la consulta")
                           print(response.result.error!)
                           return
                       }
                       /*
                        [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                        */
                       
                       if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                           for diccionario in diccionarios{
                               //print(diccionario)
                               
                               guard let id = diccionario["id"] as? String else {
                                   print("No se pudo obtener el id")
                                   return
                               }
                               print(id)
                               
                               guard let titulo = diccionario["titulo"] as? String else {
                                   print("No se pudo obtener el titulo")
                                   return
                               }
                             guard let fecha = diccionario["updated_at"] as? String else {
                                                                                 print("No se pudo obtener la fecha")
                                                                                 return
                                                                             }
                               guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                       return
                                                     }
                                                     guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                              return
                                                                            }
                                                     
                                                    
                                                     guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                                     return
                                                                                                   }
                                                     
                                                     //Esto si viene null desde el servicio web
                                                                       var nv:String?
                                                                            if (diccionario["nivel"] == nil){
                                                                                nv=""
                                                                            }else{
                                                                                nv=diccionario["nivel"] as? String
                                                                            }
                               guard let eliminado = diccionario["eliminado"] as? String else {
                                                          return
                                                      }
                            
                                self.ids.append(id)
                                self.titulos.append(titulo)
                                self.fechas.append(fecha)
                                self.fechasIcs.append(fechaIcs)
                                self.horasInicioIcs.append(horaInicioIcs)
                                self.horasFinIcs.append(horaFinIcs)
                                self.niveles.append(nv ?? "")
                            
                                                                                
                       }
                 }
               
        }
    }
      
    func obtenerCircularesFavoritas(uri:String){
               
               Alamofire.request(uri)
                   .responseJSON { response in
                       // check for errors
                       guard response.result.error == nil else {
                           // got an error in getting the data, need to handle it
                           print("error en la consulta")
                           print(response.result.error!)
                           return
                       }
                       /*
                        [{"id":"1008","titulo":"\u00a1Felices vacaciones!","estatus":"Enviada","ciclo_escolar_id":"4","created_at":"2019-04-12 13:02:19","updated_at":"2019-04-12 13:02:19","leido":"1","favorito":"1","compartida":"1","eliminado":"1","status_envio":null,"envio_todos":"0"},
                        */
                       
                       if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                           for diccionario in diccionarios{
                               //print(diccionario)
                               
                               guard let id = diccionario["id"] as? String else {
                                   print("No se pudo obtener el id")
                                   return
                               }
                               print(id)
                               
                               guard let titulo = diccionario["titulo"] as? String else {
                                   print("No se pudo obtener el titulo")
                                   return
                               }
                             guard let fecha = diccionario["updated_at"] as? String else {
                                                                                 print("No se pudo obtener la fecha")
                                                                                 return
                                                                             }
                               guard let fechaIcs = diccionario["fecha_ics"] as? String else {
                                                       return
                                                     }
                                                     guard let horaInicioIcs = diccionario["hora_inicial_ics"] as? String else {
                                                                              return
                                                                            }
                                                     
                                                    
                                                     guard let horaFinIcs = diccionario["hora_final_ics"] as? String else {
                                                                                                     return
                                                                                                   }
                                                     
                                                     //Esto si viene null desde el servicio web
                                                                       var nv:String?
                                                                            if (diccionario["nivel"] == nil){
                                                                                nv=""
                                                                            }else{
                                                                                nv=diccionario["nivel"] as? String
                                                                            }
                               guard let fav = diccionario["favorito"] as? String else {
                                                          return
                                                      }
                            if(Int(fav)==1){
                                self.ids.append(id)
                                                                                            self.titulos.append(titulo)
                                                                                            self.fechas.append(fecha)
                                                                                               
                                                                                           self.fechasIcs.append(fechaIcs)
                                                                                           self.horasInicioIcs.append(horaInicioIcs)
                                                                                           self.horasFinIcs.append(horaFinIcs)
                                                                                           self.niveles.append(nv ?? "")
                            }
                                                                                
                       }
                 }
               
        }
    }
    
  func obtenerCircular(uri:String){
          
          Alamofire.request(uri)
              .responseJSON { response in
                  // check for errors
                  guard response.result.error == nil else {
                      // got an error in getting the data, need to handle it
                      print("error en la consulta")
                      print(response.result.error!)
                      return
                  }
                  if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                      for diccionario in diccionarios{
                          //print(diccionario)
                          
                          guard let id = diccionario["id"] as? String else {
                              print("No se pudo obtener el id")
                              return
                          }
                          print(id)
                          
                          guard let titulo = diccionario["titulo"] as? String else {
                              print("No se pudo obtener el titulo")
                              return
                          }
                        guard let fecha = diccionario["updated_at"] as? String else {
                                                     print("No se pudo obtener la fecha")
                                                     return
                                                 }
                        self.ids.append(id)
                        self.titulos.append(titulo)
                        self.fechas.append(fecha)
                  }
                    
                    /*let anio = self.fechas[0].components(separatedBy: " ")[0].components(separatedBy: "-")[0]
                    let mes = self.fechas[0].components(separatedBy: " ")[0].components(separatedBy: "-")[1]
                    let dia = self.fechas[0].components(separatedBy: " ")[0].components(separatedBy: "-")[2]
                    self.lblFechaCircular.text = "\(dia)/\(mes)/\(anio)"
                    self.title = "Detalles de la circular"*/
                    //self.titulos[0].uppercased()
                //self.lblTituloParte1.text=self.titulos[0].capitalized
                   // self.partirTitulo(label1:self.lblTituloParte1,label2:self.lblTituloParte2,titulo:self.titulos[0])
              
          
      }
                
                
             
                
          
   }
      
      
  }
    
    
    let strokeTextAttributes1: [NSAttributedString.Key : Any] = [
    .foregroundColor : UIColor(hex: "#0e2455ff"),
    .backgroundColor:UIColor(hex: "#91caeeff"),
    .strokeWidth : -4.0,
    .baselineOffset:-8.0,
    ]
    
    let strokeTextAttributes2: [NSAttributedString.Key : Any] = [
    .foregroundColor : UIColor(hex: "#0e497bff"),
    .backgroundColor:UIColor(hex: "#098fcfff"),
    .strokeWidth : -4.0,
    .baselineOffset:-8.0,
    ]
   
    
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
   
    
    
    
    @IBAction func mostrarMenu(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Opciones", message: "Elige la opción que deseas", preferredStyle: .actionSheet)
        let actionFav = UIAlertAction(title: "Mover a favoritas", style: .default) { (action:UIAlertAction) in
           if(ConexionRed.isConnectedToNetwork()){
               //let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas agregar esta circular a tus favoritas?", preferredStyle: .alert)
               
               // Create OK button with action handler
               //let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                   self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: self.id)
               //})
               self.showToast(message:"Marcada como favorita", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
               // Create Cancel button with action handlder
               //let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                   
               //}
               
               //Add OK and Cancel button to dialog message
               //dialogMessage.addAction(ok)
               //dialogMessage.addAction(cancel)
               
               // Present dialog message to user
               //self.present(dialogMessage, animated: true, completion: nil)
           }else{
               var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                          alert.show()
           }
        }
        
        let actionNoLeer = UIAlertAction(title: "Mover a no leídas", style: .default) { (action:UIAlertAction) in
           if(ConexionRed.isConnectedToNetwork()){
                      //let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas marcar esta circular como no leída?", preferredStyle: .alert)
                      
                      // Create OK button with action handler
                      //let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                          self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: self.id)
             self.showToast(message:"Marcada como no leída", font: UIFont(name:"GothamRounded-Bold",size:11.0)!)
      
                   }else{
                      var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                            alert.show()
                  }
        }
        
        var tituloEliminar:String
               if(self.tipoCircular != 5){
                   tituloEliminar = "Eliminar esta notificación"
               }else{
                   tituloEliminar = "Eliminar esta circular"
               }
        
        let actionEliminar = UIAlertAction(title: tituloEliminar, style: .destructive) { (action:UIAlertAction) in
           if(ConexionRed.isConnectedToNetwork()){
            
            var tituloEliminar:String=""
            if(self.tipoCircular != 5){
                tituloEliminar = "¿Deseas eliminar esta circular?"
            }else{
               tituloEliminar = "¿Deseas eliminar esta notificación?"
            }
            
            
               let dialogMessage = UIAlertController(title: "CHMD", message: tituloEliminar, preferredStyle: .alert)
               
               // Create OK button with action handler
               let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                   self.delCircular(direccion: self.urlBase+self.delMetodo, usuario_id:self.idUsuario, circular_id: self.globalId)
                    self.eliminaCircular(idCircular:Int(self.globalId) ?? 0 ,idUsuario:Int(self.idUsuario) ?? 0)
                   //Pasar a la siguiente
                   
                   self.posicion = self.posicion+1
                   
                 
                   
                   if(self.posicion<self.ids.count){
                       var nextId = self.ids[self.posicion]
                       var nextTitulo = self.titulos[self.posicion]
                       var nextFecha = self.fechas[self.posicion]
                       
                       var nextHoraIniIcs = self.horasInicioIcs[self.posicion]
                       var nextHoraFinIcs = self.horasFinIcs[self.posicion]
                       var nextFechaIcs = self.fechasIcs[self.posicion]
                       var nextNivel = self.niveles[self.posicion]
                       
                       if(nextHoraIniIcs != "00:00:00"){
                           self.imbCalendario.isHidden=false
                       }
                        //self.lblNivel.text = nextNivel
                       
                       self.circularTitulo = nextTitulo
                       let link = URL(string:self.urlBase+"getCircularId6.php?id=\(nextId)")!
                       let request = URLRequest(url: link)
                       self.circularUrl = self.urlBase+"getCircularId6.php?id=\(nextId)"
                       self.webView.load(request)
                       self.title = "Circular"

                       
                       if(ConexionRed.isConnectedToNetwork()){

                       }
                       

                       self.id = nextId;
                   }else{
                       self.posicion = 0
                       self.id = UserDefaults.standard.string(forKey: "id") ?? ""
                   }
                   
                   
                   
               })
               
               // Create Cancel button with action handlder
               let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                   
               }
               
               //Add OK and Cancel button to dialog message
               dialogMessage.addAction(ok)
               dialogMessage.addAction(cancel)
               
               // Present dialog message to user
               self.present(dialogMessage, animated: true, completion: nil)
           }else{
               var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                                alert.show()
           }
        }
        
        
        var tituloCompartir:String=""
        if(tipoCircular != 5){
            tituloCompartir = "Compartir esta circular"
        }else{
           tituloCompartir = "Compartir esta notificación"
        }
        
        let actionCompartir = UIAlertAction(title: tituloCompartir, style: .default) { (action:UIAlertAction) in
            
            let circularUrl = "https://www.chmd.edu.mx/WebAdminCirculares/ws/getCircularId6.php?id=\(self.id)"
            guard let link = URL(string: circularUrl) else { return }
            let dynamicLinksDomainURIPrefix = "https://chmd1.page.link"
            let linkBuilder = DynamicLinkComponents(link: link, domainURIPrefix: dynamicLinksDomainURIPrefix)
            linkBuilder?.iOSParameters = DynamicLinkIOSParameters(bundleID: "mx.edu.CHMD1")
            linkBuilder?.androidParameters = DynamicLinkAndroidParameters(packageName: "mx.edu.CHMD1")

            
               let options = DynamicLinkComponentsOptions()
               options.pathLength = .short
               linkBuilder?.options = options

               linkBuilder?.shorten { (shortURL, warnings, error) in

                   if let error = error {
                       print(error.localizedDescription)
                       return
                   }

                   let shortLink = shortURL
                if(self.tipoCircular != 5){
                    let titulo = UserDefaults.standard.string(forKey: "nombre") ?? ""
                    self.compartir(message:  "Comparto: "+titulo, link: "\(shortLink!)")
                }else{
                     let titulo = UserDefaults.standard.string(forKey: "nombre") ?? ""
                     self.compartir(message: "Comparto: "+titulo, link: "\(shortLink!)")
                }
               }
            
            
            
            
        }
        
        let actionCalendario = UIAlertAction(title: "Agregar al calendario", style: .default) { (action:UIAlertAction) in
                   if(ConexionRed.isConnectedToNetwork()){
                           
                                  let eventStore = EKEventStore()
                                             switch EKEventStore.authorizationStatus(for: .event) {
                                             case .authorized:
                                              self.insertarEvento(store: eventStore, titulo: self.circularTitulo, fechaIcs: self.fechaIcs, horaInicioIcs: self.horaInicialIcs, horaFinIcs: self.horaFinalIcs, ubicacionIcs: "")
                                                
                                                
                                                
                                                 case .denied:
                                                     print("Acceso denegado")
                                                 case .notDetermined:
                                                 // 3
                                                     eventStore.requestAccess(to: .event, completion:
                                                       {[weak self] (granted: Bool, error: Error?) -> Void in
                                                           if granted {
                                                              self?.insertarEvento(store: eventStore, titulo: self?.circularTitulo ?? "", fechaIcs: self?.fechaIcs ?? "", horaInicioIcs: self?.horaInicialIcs ?? "", horaFinIcs: self?.horaFinalIcs ?? "", ubicacionIcs: "")
                                                           } else {
                                                                 print("Acceso denegado")
                                                           }
                                                     })
                                                     default:
                                                         print("Case default")
                                      
                                      
                                  }
                                  
                                  
                                  
                                  
                          }else{
                              var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                         alert.show()
                          }
               }
        
        let actionCancelar = UIAlertAction(title: "Cancelar", style:.cancel) { (action:UIAlertAction) in
                 // self.dismiss(animated: true, completion: nil)
              }
        
       
        if(tipoCircular != 5){
            alertController.addAction(actionFav)
            alertController.addAction(actionNoLeer)
        }
       
        alertController.addAction(actionCompartir)
        alertController.addAction(actionEliminar)
        alertController.addAction(actionCancelar)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == WKNavigationType.linkActivated {
            
            let docUrl = URL(string:navigationAction.request.url!.absoluteString)!
            recursoRemoto(at: docUrl, isOneOf: [.pdf]) { (result) in
                UserDefaults.standard.setValue(navigationAction.request.url!.absoluteString, forKey: "docUrl")
                DispatchQueue.main.async{
                    //self.performSegue(withIdentifier: "pdfSegue", sender: self)
                    
                    if UIPrintInteractionController.canPrint(docUrl) {
                        let printInfo = UIPrintInfo(dictionary: nil)
                                        printInfo.jobName = docUrl.lastPathComponent
                                        printInfo.outputType = .general
                                        let printController = UIPrintInteractionController.shared
                                        printController.printInfo = printInfo
                                        printController.showsNumberOfCopies = false
                                        printController.printingItem = docUrl
                                        printController.present(animated: true, completionHandler: nil)
                    }
                    
                    
                }
               
                //Detecta que es pdf
                /*if UIPrintInteractionController.canPrint(docUrl) {
                    let printInfo = UIPrintInfo(dictionary: nil)
                                    printInfo.jobName = docUrl.lastPathComponent
                                    printInfo.outputType = .general
                                    let printController = UIPrintInteractionController.shared
                                    printController.printInfo = printInfo
                                    printController.showsNumberOfCopies = false
                                    printController.printingItem = docUrl
                                    printController.present(animated: true, completionHandler: nil)
                }*/
            }

            
            
        print("link")
               self.btnRecargar.isEnabled=true
               self.btnRecargar.tintColor = UIColor.white
            decisionHandler(WKNavigationActionPolicy.allow)
               return
        }else{
        decisionHandler(WKNavigationActionPolicy.allow)
        }
    
    }
    
    //Funcion para determinar si el contenido es pdf
    enum MimeType: String {
        case jpeg = "image/jpeg"
        case png = "image/png"
        case pdf = "application/pdf"
    }

    func recursoRemoto(at url: URL, isOneOf types: [MimeType], completion: @escaping ((Bool) -> Void)) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, response.statusCode == 200, let mimeType = response.mimeType else {
                completion(false)
                return
            }
            if types.map({ $0.rawValue }).contains(mimeType) {
                completion(true)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    
    
    
}

    



