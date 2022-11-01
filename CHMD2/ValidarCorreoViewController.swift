//
//  ValidarCorreoViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 8/9/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//
import UIKit
import Alamofire
import Firebase
import Network
import GoogleSignIn
import SQLite3
extension OperatingSystemVersion {
    func getFullVersion(separator: String = ".") -> String {
        return "\(majorVersion)\(separator)\(minorVersion)\(separator)\(patchVersion)"
    }
}

class ValidarCorreoViewController: UIViewController {
    var email:String=""
    var so:String=""
    var deviceToken = ""
    let v = UIView()
    var db: OpaquePointer?
    var idUsuario:String=""
    let base_url_foto:String="http://chmd.chmd.edu.mx:65083/CREDENCIALES/padres/"
    let base_url:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/";
    let get_usuario:String="getUsuarioEmail.php";
    let get_badge:String="recuentoBadge.php";
    
    
    @IBOutlet weak var lblMensaje: UILabel!
    @IBOutlet weak var btnContinuar: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        print("El email del usuario es: \(email)")
        
        obtenerDatosUsuario(uri:base_url+get_usuario+"?correo="+email)
        let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/validarEmail.php?correo=\(email)"
        let _url = URL(string: address)!
        
        let idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        
        validarEmail(url: _url)
        btnContinuar.isHidden=true
        
        let existe:String = UserDefaults.standard.string(forKey: "valida") ?? "0"
        let valida = Int(existe) ?? 0
      }
   
   
    
    
    func validarEmail(url:URL)->Int{
           var valida:Int=0
           self.lblMensaje.text="Validando cuenta de correo"
           URLSession.shared.dataTask(with: url) {
               (data, response, error) in
               if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                   
                   let obj = datos[0] as! [String : AnyObject]
                       let existe = obj["existe"] as! String
                       print("existe: "+existe)
                       valida = Int(existe) ?? 0
                       print("valida: \(valida)")
                if valida>0 {
                    valida=1
                    UserDefaults.standard.set(1, forKey: "valida")
                }else{
                    UserDefaults.standard.set(0, forKey: "valida")
                }
                       
               
                    
               }
               
               }.resume()
        
        
           return valida
           
       }
       
    
    @IBAction func btnContinuar_Click(_ sender: UIButton) {
        print("idUsuario_btn: \(UserDefaults.standard.string(forKey: "idUsuario"))")
       
        
        var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
        var metodoCirculares:String="getCirculares_iOS.php"
        var metodoNotificaciones:String="getNotificaciones_iOS.php"
        let address=urlBase+metodoCirculares+"?usuario_id=\(idUsuario)"
        guard let _url = URL(string: address) else { return };
        //Se hace con un completion handler para que espere a que la función termine de ejecutarse
        getDataFromURL(url: _url){[weak self] success, int in
            guard let strongSelf = self, success else { return }
            //Todos los cambios en la UI se hacen dentro del DispatchQueue
            DispatchQueue.main.async{
                strongSelf.lblMensaje.text="Circulares recuperadas."
                print("Circulares recuperadas....válido!")
                strongSelf.performSegue(withIdentifier: "validarSegue", sender: self)
            }
           
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print(email)
        
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        print("El email del usuario es(viewDidAppear): \(email)")
        
        
        let existe:String = UserDefaults.standard.string(forKey: "valida") ?? "0"
        
        let manzana:Int = UserDefaults.standard.integer(forKey: "manzana") ?? 0
        var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
        var metodoCirculares:String="getCirculares_iOS.php"
        var metodoNotificaciones:String="getNotificaciones_iOS.php"
        let valida = 1
        print("valida2: \(valida)")
        
        if(valida==0){
            self.lblMensaje.text="La cuenta no es válida"
            self.btnContinuar.setTitle("Salir", for: .normal)
          
        }
        if(valida==1 || manzana==1){
            self.lblMensaje.text="La cuenta es válida"
            self.btnContinuar.setTitle("Continuar", for: .normal)
            self.btnContinuar.isHidden=true
            //self.btnContinuar.visiblity(gone: true, dimension: 0)
            idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
            let address=urlBase+metodoCirculares+"?usuario_id=\(idUsuario)"
            guard let _url = URL(string: address) else { return };
            
            obtenerCirculares(url: _url){[weak self] success, int in
                guard let strongSelf = self, success else { return }
                //Todos los cambios en la UI se hacen dentro del DispatchQueue
                DispatchQueue.main.async{
                    //strongSelf.lblMensaje.text="Circulares recuperadas correctamente!"
                    //strongSelf.performSegue(withIdentifier: "validarSegue", sender: self)
                }
               
            }
            
            
            let addressN=urlBase+metodoNotificaciones+"?usuario_id=\(idUsuario)"
            guard let _urlN = URL(string: addressN) else { return };
            
            obtenerNotificaciones(url: _urlN){[weak self] success, int in
                guard let strongSelf = self, success else { return }
                if success {
                    DispatchQueue.main.async{
                        var segundos = 7
                        let t = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .medium)
                        
                        print("Circular almacenada correctamente en validar (completion) \(t)")
                        strongSelf.lblMensaje.text="¡Espera un momento, recuperando las últimas circulares!"
                        
                        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (Timer) in
                                if segundos > 0 {
                                    segundos -= 1
                                    
                                } else {
                                    Timer.invalidate()
                                    strongSelf.performSegue(withIdentifier: "validarSegue", sender: self)
                                }
                            }
                        
                        
                        
                    }
                }
               
               
            }
            
            
        }
         
    }
        
     
    @IBAction func continuar(_ sender: UIButton) {
        performSegue(withIdentifier: "validarSegue", sender: self)
     }
    
    func delete(tipo:Int) {
        
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
               
               if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
                   print("Error en la base de datos")
               }else{
        
      var deleteStatement: OpaquePointer?
        var deleteStatementString="DELETE FROM appCircularCHMD where tipo=\(tipo)"
      if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) ==
          SQLITE_OK {
        if sqlite3_step(deleteStatement) == SQLITE_DONE {
          print("BASE:Successfully deleted row.")
        } else {
          print("BASE:Could not delete row.")
        }
      } else {
        print("BASE:DELETE statement could not be prepared")
      }
      
      sqlite3_finalize(deleteStatement)
        }
    
    }
    func guardarCirculares(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int,especiales:String){
        var badge:Int=0
        
            //Abrir la base
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
                //La base de datos abrió correctamente
            var statement:OpaquePointer?
            let query = "INSERT INTO appCircularCHMD(idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales,tipo) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)"
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            let n = nombre as NSString
            if sqlite3_bind_text(statement,3,n.utf8String, -1, nil) != SQLITE_OK {
                print("Error campo 3")
            }
            let texto = textoCircular as NSString
            if sqlite3_bind_text(statement,4,texto.utf8String, -1, nil) != SQLITE_OK {
                print("Error campo 4")
            }
            
            if sqlite3_bind_int(statement,5,Int32(no_leida)) != SQLITE_OK {
                print("Error campo 5")
            }
            
            if sqlite3_bind_int(statement,6,Int32(leida)) != SQLITE_OK {
                print("Error campo 6")
            }
            
            if sqlite3_bind_int(statement,7,Int32(favorita)) != SQLITE_OK {
                print("Error campo 7")
            }
            
            if sqlite3_bind_int(statement,8,Int32(eliminada)) != SQLITE_OK {
                           print("Error campo 8")
              }
            
           if sqlite3_bind_text(statement,9,fecha, -1, nil) != SQLITE_OK {
               print("Error campo 9")
           }
             let fiIcs = fechaIcs as NSString
            if sqlite3_bind_text(statement,10,fiIcs.utf8String, -1, nil) != SQLITE_OK {
                print("Error campo 10")
            }
            let hiIcs = horaInicioIcs as NSString
            if sqlite3_bind_text(statement,11,hiIcs.utf8String, -1, nil) != SQLITE_OK {
                           print("Error campo 11")
            }
            let hfIcs = horaFinIcs as NSString
            if sqlite3_bind_text(statement,12,hfIcs.utf8String, -1, nil) != SQLITE_OK {
                           print("Error campo 12")
            }
            if sqlite3_bind_text(statement,13,nivel, -1, nil) != SQLITE_OK {
                           print("Error campo 13")
            }
            let espec = especiales as NSString
            if sqlite3_bind_text(statement,14,espec.utf8String, -1, nil) != SQLITE_OK {
                           print("Error campo 14")
            }
           
            
            
            if sqlite3_step(statement) == SQLITE_DONE {
                
                let t = DateFormatter.localizedString(from: NSDate() as Date, dateStyle: .short, timeStyle: .medium)
               
             
                
                print("Circular almacenada correctamente en validar \(t)")
            }else{
                print("Circular no se pudo guardar")
            }
            }
        
    
        
    }
    var notifNoLeidas=0
    func guardarNotificaciones(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int,especiales:String){
        
        
        //Abrir la base
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
                //La base de datos abrió correctamente
            var statement:OpaquePointer?
            let query = "INSERT INTO appCircularCHMD(idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales,tipo) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,2)"
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            let n = nombre as NSString
            if sqlite3_bind_text(statement,3,n.utf8String, -1, nil) != SQLITE_OK {
                print("Error campo 3")
            }
            let texto = textoCircular as NSString
            if sqlite3_bind_text(statement,4,texto.utf8String, -1, nil) != SQLITE_OK {
                print("Error campo 4")
            }
            
            if sqlite3_bind_int(statement,5,Int32(no_leida)) != SQLITE_OK {
                print("Error campo 5")
            }
            
            if sqlite3_bind_int(statement,6,Int32(leida)) != SQLITE_OK {
                print("Error campo 6")
            }
            
            if sqlite3_bind_int(statement,7,Int32(favorita)) != SQLITE_OK {
                print("Error campo 7")
            }
            
            if sqlite3_bind_int(statement,8,Int32(eliminada)) != SQLITE_OK {
                           print("Error campo 8")
              }
            
           if sqlite3_bind_text(statement,9,fecha, -1, nil) != SQLITE_OK {
               print("Error campo 9")
           }
             let fiIcs = fechaIcs as NSString
            if sqlite3_bind_text(statement,10,fiIcs.utf8String, -1, nil) != SQLITE_OK {
                print("Error campo 10")
            }
            let hiIcs = horaInicioIcs as NSString
            if sqlite3_bind_text(statement,11,hiIcs.utf8String, -1, nil) != SQLITE_OK {
                           print("Error campo 11")
            }
            let hfIcs = horaFinIcs as NSString
            if sqlite3_bind_text(statement,12,hfIcs.utf8String, -1, nil) != SQLITE_OK {
                           print("Error campo 12")
            }
            if sqlite3_bind_text(statement,13,nivel, -1, nil) != SQLITE_OK {
                           print("Error campo 13")
            }
            let espec = especiales as NSString
            if sqlite3_bind_text(statement,14,espec.utf8String, -1, nil) != SQLITE_OK {
                           print("Error campo 14")
            }
           
            
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Notificaciones almacenadas correctamente en validar")
            }else{
                print("Circular no se pudo guardar")
            }
            
        }
        
        
        UserDefaults.standard.set(self.notifNoLeidas, forKey: "totalNotif")
    
        
    }
    
    func obtenerDatosUsuario(uri:String) {
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
                    
                    
                    guard let correo = diccionario["correo"] as? String else {
                                           print("No se pudo obtener el correo")
                                           return
                    }
                    
                    
                    
                    
                    var foto:String = ""
                    
                    if(fotografia.count>5){
                        foto = self.base_url_foto+fotografia.components(separatedBy: "\\")[4]
                    }else{
                        foto = self.base_url_foto+"sinfoto.png"
                    }
                    
                    
                    
                    
                    var fotoUrl=foto;
                    //Guardar las variables
                    
                    
                    UserDefaults.standard.set(id, forKey: "idUsuario")
                    UserDefaults.standard.set(nombre, forKey: "nombreUsuario")
                    UserDefaults.standard.set(numero, forKey: "numeroUsuario")
                    UserDefaults.standard.set(familia, forKey: "familia")
                    UserDefaults.standard.set(fotoUrl, forKey: "fotoUrl")
                    
                    UserDefaults.standard.set(responsable, forKey: "responsable")
                    UserDefaults.standard.set(correo, forKey: "correo")
                    UserDefaults.standard.synchronize()
                    
                    
                    print("idUsuario: \(id)")
                    
                    //Registrar dispositivo
                             
                               let os = ProcessInfo().operatingSystemVersion
                               let so = "iOS \(os.getFullVersion())"
                               
                    
                    InstanceID.instanceID().instanceID { (result, error) in
                      if let error = error {
                        print("Error fetching remote instance ID: \(error)")
                      } else if let result = result {
                        print("Remote instance ID token: \(result.token)")
                        self.registrarDispositivo(direccion: "https://www.chmd.edu.mx/WebAdminCirculares/ws/registrarDispositivo.php", correo: correo, device_id: result.token, so: so,id:id)
                                           
                      }
                    }
                    
                  
                      
                    }
                }
                
        }
        
        
        /*let tmr = Timer.scheduledTimer(withTimeInterval:4.0,repeats:false){timer in
            self.performSegue(withIdentifier: "inicioSegue", sender: self)
            print("llamado el segue desde la funcion")
            timer.invalidate()
        }*/
        
        
    
    }
    
   
    
    
    func registrarDispositivo(direccion:String, correo:String, device_id:String, so:String,id:String){
        let parameters: Parameters = ["correo": correo, "device_token": device_id,"plataforma":so,"id_usuario":id]      //This will be your parameter
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
    
    
    
    func obtenerCirculares(url:URL,completion: @escaping (Bool, Int?) -> Void){
        
        self.delete(tipo:1)
     
        var request = URLRequest(url: url)
        var finalizado=false
        request.httpMethod="GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, _,error in
           
            guard let data = data,error == nil else {
                return
            }
            do{
                //let resp = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let resp = try JSONDecoder().decode([Circular2].self, from: data)
                //print("SUCCESS: \(resp)")
                
                for c in resp{
                    
                    var noLeida:Int
                    var leida:Int
                    if(Int(c.leido!)==0){
                        noLeida=1
                        leida=0
                    }else{
                        noLeida=0
                        leida=1
                    }
                    
                    var str = c.contenido!.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&amp;aacute;", with: "á")
                    .replacingOccurrences(of: "&amp;eacute;", with: "é")
                    .replacingOccurrences(of: "&amp;iacute;", with: "í")
                    .replacingOccurrences(of: "&amp;oacute;", with: "ó")
                    .replacingOccurrences(of: "&amp;uacute;", with: "ú")
                    .replacingOccurrences(of: "&amp;ordm;", with: "o.")
                    
                    var nombre = c.titulo!.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
                    
                    .replacingOccurrences(of: "&amp;aacute;", with: "á")
                    .replacingOccurrences(of: "&amp;eacute;", with: "é")
                    .replacingOccurrences(of: "&amp;iacute;", with: "í")
                    .replacingOccurrences(of: "&amp;oacute;", with: "ó")
                    .replacingOccurrences(of: "&amp;uacute;", with: "ú")
                    .replacingOccurrences(of: "&amp;ordm;", with: "o.")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    
                    var para:String = "\(c.grados!)/\(c.espec!)/\(c.adm!)/\(c.rts!)/"
                    para = para.trimmingCharacters(in: .whitespacesAndNewlines)
                    para = String(para.dropLast())
                    print("Para: \(para)")
                    if(c.envia_todos!.contains("1")){
                        para="Todos"
                    }
                    
                    if(c.envia_todos!.contains("0")){
                        para="Personal"
                    }
                    
                    self.guardarCirculares(idCircular: Int(c.id!)!, idUsuario: Int(c.id_usuario!)!, nombre: nombre, textoCircular: str.replacingOccurrences(of: "&nbsp;", with: ""), no_leida: noLeida, leida: leida, favorita: Int(c.favorito!)!, compartida: 0, eliminada: Int(c.eliminado!)!, fecha: c.created_at!, fechaIcs: c.fecha_ics!, horaInicioIcs: c.hora_inicial_ics!, horaFinIcs: c.hora_final_ics!, nivel: c.nivel!, adjunto: Int(c.adjunto!)!, especiales: para)
                  
                    
                }
             
                finalizado=true
                
            }catch{
                print(error)
            }
            
        }
        completion(finalizado, 1)
    
   
        task.resume()
        
    }
    
    
    func obtenerNotificaciones(url:URL,completion: @escaping (Bool, Int?) -> Void){
        var finalizado=false
        self.delete(tipo:2)
        var request = URLRequest(url: url)
        request.httpMethod="GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, _,error in
           
            guard let data = data,error == nil else {
                return
            }
            do{
                //let resp = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                let resp = try JSONDecoder().decode([Circular2].self, from: data)
                //print("SUCCESS: \(resp)")
                
                for c in resp{
                    
                    var noLeida:Int
                    var leida:Int
                    if(Int(c.leido!)==0){
                        noLeida=1
                        leida=0
                    }else{
                        noLeida=0
                        leida=1
                    }
                    
                    var str = c.contenido!.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
                    .replacingOccurrences(of: "&amp;aacute;", with: "á")
                    .replacingOccurrences(of: "&amp;eacute;", with: "é")
                    .replacingOccurrences(of: "&amp;iacute;", with: "í")
                    .replacingOccurrences(of: "&amp;oacute;", with: "ó")
                    .replacingOccurrences(of: "&amp;uacute;", with: "ú")
                    .replacingOccurrences(of: "&amp;ordm;", with: "o.")
                    
                    var nombre = c.titulo!.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
                    
                    .replacingOccurrences(of: "&amp;aacute;", with: "á")
                    .replacingOccurrences(of: "&amp;eacute;", with: "é")
                    .replacingOccurrences(of: "&amp;iacute;", with: "í")
                    .replacingOccurrences(of: "&amp;oacute;", with: "ó")
                    .replacingOccurrences(of: "&amp;uacute;", with: "ú")
                    .replacingOccurrences(of: "&amp;ordm;", with: "o.")
                    .replacingOccurrences(of: "&amp;", with: "&")
                    
                    var para:String = "\(c.grados!)/\(c.espec!)/\(c.adm!)/\(c.rts!)/"
                    para = para.trimmingCharacters(in: .whitespacesAndNewlines)
                    para = String(para.dropLast())
                    print("Para: \(para)")
                    if(c.envia_todos!.contains("1")){
                        para="Todos"
                    }
                    
                    if(c.envia_todos!.contains("0")){
                        para="Personal"
                    }
                    
                    self.guardarNotificaciones(idCircular: Int(c.id!)!, idUsuario: Int(c.id_usuario!)!, nombre: nombre, textoCircular: str, no_leida: noLeida, leida: leida, favorita: Int(c.favorito!)!, compartida: 0, eliminada: Int(c.eliminado!)!, fecha: c.created_at!, fechaIcs: c.fecha_ics!, horaInicioIcs: c.hora_inicial_ics!, horaFinIcs: c.hora_final_ics!, nivel: c.nivel!, adjunto: Int(c.adjunto!)!, especiales: para)
                    
                    
                    
                }
                
                finalizado=true
            }catch{
                print(error)
            }
            
        }
        task.resume()
        completion(true, 1)
        
        
    }
    
    func getDataFromURL(url: URL,completion: @escaping (Bool, Int?) -> Void) {
        print("Leer desde el servidor....")
        print(url)
       
        self.delete(tipo:1)
        DispatchQueue.global(qos: .background).async {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            
           
            if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                print("datos \(datos.count)")
                if(datos.count>0){
                    for index in 0...((datos).count) - 1
                    {
                        let obj = datos[index] as! [String : AnyObject]
                        guard let id = obj["id"] as? String else {
                            print("No se pudo obtener el id")
                            return
                        }
                        guard let titulo = obj["titulo"] as? String else {
                            print("No se pudo obtener el titulo")
                            return
                        }
                        
                        var imagen:UIImage
                           imagen = UIImage.init(named: "appmenu05")!
                           guard let fecha = obj["created_at"] as? String else {
                            print("No se pudo obtener la fecha")
                                                      return
                                                  }
                           
                           guard let favorito = obj["favorito"] as? String else {
                            print("No se pudo obtener el fav")
                               return
                           }
                           
                           guard let adjunto = obj["adjunto"] as? String else {
                            print("No se pudo obtener el adj")
                                                      return
                                                  }
                           
                           guard let eliminada = obj["eliminado"] as? String else {
                            print("No se pudo obtener el eliminado")
                               return
                           }
                           
                           guard let texto = obj["contenido"] as? String else {
                            print("No se pudo obtener el contenido")
                               return
                           }
                        
                        guard let leido = obj["leido"] as? String else {
                            print("No se pudo obtener el leido")
                            return
                        }
                           
                           guard let fechaIcs = obj["fecha_ics"] as? String else {
                            print("No se pudo obtener la fecha ics")
                             return
                           }
                           guard let horaInicioIcs = obj["hora_inicial_ics"] as? String else {
                            print("No se pudo obtener la hora ini ics")
                                                    return
                                                  }
                           
                          
                           guard let horaFinIcs = obj["hora_final_ics"] as? String else {
                            print("No se pudo obtener la hora fin ics")
                                                                           return
                                                                         }
                           var nv:String?
                           if (obj["nivel"] == nil){
                            print("No se pudo obtener el nivel")
                               nv=""
                           }else{
                               nv=obj["nivel"] as? String
                           }
                        
                        
                        var esp:String?=""
                        if (obj["espec"] == nil){
                            esp=""
                        }else{
                            esp=obj["espec"] as? String
                        }
                        
                        
                        var grados:String?=""
                        if (obj["grados"] == nil){
                            grados=""
                        }else{
                            grados=obj["grados"] as? String
                        }
                        
                        
                        var adm:String?=""
                        adm=obj["adm"] as? String
                        var rts:String?=""
                        rts=obj["rts"] as? String
                        var enviaTodos:String?=""
                        if (obj["envia_todos"] == nil){
                            enviaTodos=""
                        }else{
                            enviaTodos=obj["envia_todos"] as? String
                        }

                           
                        var noLeida:Int = 0
                       
                           //leídas
                           if(Int(leido)!>0){
                               imagen = UIImage.init(named: "circle_white")!
                           }
                           //No leídas
                           if(Int(leido)==0 && Int(favorito)==0){
                               imagen = UIImage.init(named: "circle")!
                            noLeida=1
                           }
                           if(Int(leido)! == 0){
                               noLeida = 1
                           }
                           
                           var adj=0;
                           if(Int(adjunto)!==1){
                               adj=1
                           }
                          
                           if(Int(favorito)!>0){
                               imagen = UIImage.init(named: "circle_white")!
                           }
                           
                           var str = texto.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
                           .replacingOccurrences(of: "&amp;aacute;", with: "á")
                           .replacingOccurrences(of: "&amp;eacute;", with: "é")
                           .replacingOccurrences(of: "&amp;iacute;", with: "í")
                           .replacingOccurrences(of: "&amp;oacute;", with: "ó")
                           .replacingOccurrences(of: "&amp;uacute;", with: "ú")
                           .replacingOccurrences(of: "&amp;ordm;", with: "o.")
                              
                        if(nv!.count>0){
                            nv = "\(nv!)/"
                        }
                       
                        if(grados!.count>0){
                            grados = "\(grados!)/"
                        }
                        
                        if(esp!.count>0){
                            esp = "\(esp!)/"
                        }
                        
                        if(adm!.count>0){
                            adm = "\(adm!)/"
                        }
                        
                        if(rts!.count>0){
                            rts = "\(rts!)/"
                        }
                        nv = nv?.replacingOccurrences(of: "/", with: "")
                        var para:String = "\(grados!) \(esp!) \(adm!) \(rts!)"
                        para = para.trimmingCharacters(in: .whitespacesAndNewlines)
                        para = String(para.dropLast())
                        print("Para: \(para)")
                        if(enviaTodos=="1"){
                            para="Todos"
                        }
                        
                        if(enviaTodos=="0" && esp=="" && adm=="" && rts=="" && nv!=="" && grados==""){
                            para="Personal"
                        }
                        
                        print("leida server: \(leido), no leida server: \(noLeida)")
                        self.guardarCirculares(idCircular: Int(id)!, idUsuario: Int(self.idUsuario)!, nombre: titulo, textoCircular: str.replacingOccurrences(of: "&nbsp;", with: ""), no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: 0, eliminada: Int(eliminada)!,fecha: fecha,fechaIcs: fechaIcs,horaInicioIcs: horaInicioIcs,horaFinIcs: horaFinIcs,nivel: nv ?? "",adjunto:adj,especiales: para)
                         
                    }
               }
                
            }else{
                print(error.debugDescription)
                print(error?.localizedDescription)
            }
            //Esto hace que la función devuelva el control al main thread después de haber terminado (IMPORTANTE: no olvidarlo)
            completion(true, 1)
            
            }.resume()
            
           
        }
            
           
        
        self.lblMensaje.text="Recuperando las circulares..."
             
    }
    
    
    
    
    
    
    /*func getDataFromURL(url: URL) {
        print("Leer desde el servidor....")
        print(url)
        let newQueue = DispatchQueue(label: "queue_label")
       
        self.delete()
        newQueue.async {
            
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            
            
            if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                print("datos \(datos.count)")
                if(datos.count>0){
                    for index in 0...((datos).count) - 1
                    {
                        let obj = datos[index] as! [String : AnyObject]
                        guard let id = obj["id"] as? String else {
                            print("No se pudo obtener el id")
                            return
                        }
                        guard let titulo = obj["titulo"] as? String else {
                            print("No se pudo obtener el titulo")
                            return
                        }
                        
                        var imagen:UIImage
                           imagen = UIImage.init(named: "appmenu05")!
                           
                           
                          
                           
                           guard let fecha = obj["created_at"] as? String else {
                            print("No se pudo obtener la fecha")
                                                      return
                                                  }
                           
                           guard let favorito = obj["favorito"] as? String else {
                            print("No se pudo obtener el fav")
                               return
                           }
                           
                           guard let adjunto = obj["adjunto"] as? String else {
                            print("No se pudo obtener el adj")
                                                      return
                                                  }
                           
                           guard let eliminada = obj["eliminado"] as? String else {
                            print("No se pudo obtener el eliminado")
                               return
                           }
                           
                           guard let texto = obj["contenido"] as? String else {
                            print("No se pudo obtener el contenido")
                               return
                           }
                        
                        guard let leido = obj["leido"] as? String else {
                            print("No se pudo obtener el leido")
                            return
                        }
                           
                           guard let fechaIcs = obj["fecha_ics"] as? String else {
                            print("No se pudo obtener la fecha ics")
                             return
                           }
                           guard let horaInicioIcs = obj["hora_inicial_ics"] as? String else {
                            print("No se pudo obtener la hora ini ics")
                                                    return
                                                  }
                           
                          
                           guard let horaFinIcs = obj["hora_final_ics"] as? String else {
                            print("No se pudo obtener la hora fin ics")
                                                                           return
                                                                         }
                           
                        
                           //Con esto se evita la excepcion por los valores nulos
                           var nv:String?
                           if (obj["nivel"] == nil){
                            print("No se pudo obtener el nivel")
                               nv=""
                           }else{
                               nv=obj["nivel"] as? String
                           }
                        
                        
                        var esp:String?=""
                        if (obj["espec"] == nil){
                            esp=""
                        }else{
                            esp=obj["espec"] as? String
                        }
                        
                        
                        var grados:String?=""
                        if (obj["grados"] == nil){
                            grados=""
                        }else{
                            grados=obj["grados"] as? String
                        }
                        
                        
                        var adm:String?=""
                        
                            adm=obj["adm"] as? String
                        
                        
                        var rts:String?=""
                        rts=obj["rts"] as? String
                        
                    
                        
                        
                        var enviaTodos:String?=""
                        if (obj["envia_todos"] == nil){
                            enviaTodos=""
                        }else{
                            enviaTodos=obj["envia_todos"] as? String
                        }

                           
                        var noLeida:Int = 0
                       
                           //leídas
                           if(Int(leido)!>0){
                               imagen = UIImage.init(named: "circle_white")!
                           }
                           //No leídas
                           if(Int(leido)==0 && Int(favorito)==0){
                               imagen = UIImage.init(named: "circle")!
                            noLeida=1
                           }
                           
                           
                           if(Int(leido)! == 0){
                               noLeida = 1
                           }
                           
                           var adj=0;
                           if(Int(adjunto)!==1){
                               adj=1
                           }
                          
                           if(Int(favorito)!>0){
                               imagen = UIImage.init(named: "circle_white")!
                            //imagen = nil
                           }
                           
                           var str = texto.replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
                           .replacingOccurrences(of: "&amp;aacute;", with: "á")
                           .replacingOccurrences(of: "&amp;eacute;", with: "é")
                           .replacingOccurrences(of: "&amp;iacute;", with: "í")
                           .replacingOccurrences(of: "&amp;oacute;", with: "ó")
                           .replacingOccurrences(of: "&amp;uacute;", with: "ú")
                           .replacingOccurrences(of: "&amp;ordm;", with: "o.")
                        print("adm: "+adm!)
                        
                        
                        
                        //grados:String,adm:String,grupos:String,rts:String,enviaTodos:String
                        
                          
                        
                        
                        if(nv!.count>0){
                            nv = "\(nv!)/"
                        }
                       
                        if(grados!.count>0){
                            grados = "\(grados!)/"
                        }
                        
                        if(esp!.count>0){
                            esp = "\(esp!)/"
                        }
                        
                        if(adm!.count>0){
                            adm = "\(adm!)/"
                        }
                        
                        if(rts!.count>0){
                            rts = "\(rts!)/"
                        }
                        nv=""
                        var para:String = "\(nv!) \(grados!) \(esp!) \(adm!) \(rts!)"
                        para = para.trimmingCharacters(in: .whitespacesAndNewlines)
                        para = String(para.dropLast())
                        print("Para: \(para)")
                        if(enviaTodos=="1"){
                            para="Todos"
                        }
                        
                        if(enviaTodos=="0" && esp=="" && adm=="" && rts=="" && nv!=="" && grados==""){
                            para="Personal"
                        }
                        
                        
                        /*
                         guardarCirculares(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int)
                         */
                        print("leida server: \(leido), no leida server: \(noLeida)")
                        self.guardarCirculares(idCircular: Int(id)!, idUsuario: Int(self.idUsuario)!, nombre: titulo, textoCircular: str, no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: 0, eliminada: Int(eliminada)!,fecha: fecha,fechaIcs: fechaIcs,horaInicioIcs: horaInicioIcs,horaFinIcs: horaFinIcs,nivel: nv ?? "",adjunto:adj,especiales: para)
                        
                        
                    }
                    
                    
                    
                    
                }
                
            }else{
                print(error.debugDescription)
                print(error?.localizedDescription)
            }
            
            
            }.resume()
            
            
            let delay = 6.0
           
            DispatchQueue.main.asyncAfter(deadline: .now()+delay){
                print("RECARGA")
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "validarSegue", sender: self)
                }
            }
         
            
            
        }
        
        self.lblMensaje.text="Recuperando las circulares..."
        //DispatchQueue.main.async{
         //   self.performSegue(withIdentifier: "validarSegue", sender: self)
        //}
       
        
    }*/
    
    
    struct Circular2:Codable{
        let adjunto:String?
        let adm:String?
        let ciclo_escolar_id:String?
        let compartida:String?
        let contenido:String?
        let created_at:String?
        let cu_created_at:String?
        let cu_id:String?
        let cu_updated_at:String?
        let deleted_at:String?
        let descripcion:String?
        let eliminado:String?
        let envia_todos:String?
        let espec:String?
        let estatus:String?
        let favorito:String?
        let fecha:String?
        let fecha_ics:String?
        let fecha_programada:String?
        let formateada:String?
        let grados:String?
        let grupos:String?
        let hora_final_ics:String?
        let hora_inicial_ics:String?
        let id:String?
        let id_nivel:String?
        let id_usuario:String?
        let leido:String?
        let nivel:String?
        let niveles:String?
        let notificacion:String?
        let rts:String?
        let slug:String?
        let status_envio:String?
        let tema_ics:String?
        let tipo:String?
        let titulo:String?
        let ubicacion_ics:String?
        let updated_at:String?
        let usuario_id:String?
        
    }

}
