//
//  PrincipalTableViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/6/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//
import UIKit
import AVKit
import AVFoundation
import GoogleSignIn
import Alamofire
import Firebase

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


class PrincipalTableViewController: UITableViewController {
    //var avPlayer:AVPlayer!
    //var avPlayerLayer:AVPlayerLayer!
    //var paused:Bool = false
    
      var avPlayer:AVPlayer!
      var avPlayerLayer:AVPlayerLayer!
      var paused:Bool = false
    
    
    @IBOutlet var tableViewMenu: UITableView!
    
    var menu = [MenuPrincipal]()
    var resp = [Responsable]()
    let base_url_foto:String="http://chmd.chmd.edu.mx:65083/CREDENCIALES/padres/"
    let base_url:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/";
    let get_usuario:String="getUsuarioEmail.php";
    var email:String=""
    var idUsuario:String=""
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        email=UserDefaults.standard.string(forKey: "email") ?? ""
        idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? ""
        print("correo:"+email)
        
        let INICIO=1
        let MAGUEN=2
        let SIGN_OUT=3
        let CREDENCIAL=4
        //let NOTIFICACION=4
            
            menu.append(MenuPrincipal(id: INICIO, imagen:UIImage.init(named: "circulares256")!))
            menu.append(MenuPrincipal(id: MAGUEN,  imagen:UIImage.init(named: "mi_maguen256")!))
            menu.append(MenuPrincipal(id: CREDENCIAL,  imagen:UIImage.init(named: "mi_credencial256")!))
            //menu.append(MenuPrincipal(id: NOTIFICACION,  imagen:UIImage.init(named: "mi_maguen256")!))
            menu.append(MenuPrincipal(id: SIGN_OUT, imagen:UIImage.init(named: "cerrar_sesion256")!))
        
    
        /*let urlVideo = Bundle.main.url(forResource: "video_app", withExtension: "mp4")
        
        avPlayer = AVPlayer(url: urlVideo!)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avPlayer.volume = 0
        avPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        
        avPlayerLayer.frame = view.layer.bounds
        view.backgroundColor = UIColor.clear;
        view.layer.insertSublayer(avPlayerLayer, at: 0)
        
        NotificationCenter.default.addObserver(self,
                                               selector: Selector("playerItemDidReachEnd:"),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer.currentItem)
    
    */
        
        
        obtenerDatosUsuario(uri:base_url+get_usuario+"?correo="+email)
        cifrarIdUsuario(uri:base_url+"cifrar.php?idUsuario="+self.idUsuario)
        getVigenciaUsuario(uri:base_url+"getVigencia.php?idUsuario="+self.idUsuario)
    }

    /*@objc func playerItemDidReachEnd(notification: NSNotification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: CMTime.zero)
    }*/
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    
    func cifrarIdUsuario(uri:String){
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
                print(diccionario)
                  
                    guard let cifrado = diccionario["cifrado"] as? String else {
                        print("No se pudo obtener el cifrado")
                        return
                    }
                    
                    
                    
                    UserDefaults.standard.set(cifrado, forKey: "cifrado")
                  
                   
                             
                             
                    }
                }
                
        }
        
    
    }
    
    func getVigenciaUsuario(uri:String){
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
                print(diccionario)
                  
                    guard let vigencia = diccionario["texto"] as? String else {
                        print("No se pudo obtener el cifrado")
                        return
                    }
                    
                    
                    
                    UserDefaults.standard.set(vigencia, forKey: "vigencia")
                  
                   
                             
                             
                    }
                }
                
        }
        
    
    }
    
    func obtenerDatosUsuario(uri:String){
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
                    self.resp.append(Responsable(id:id,nombre:nombre,numero:numero,familia:familia,foto:foto,responsable: responsable))
                    
                    
                    UserDefaults.standard.set(id, forKey: "idUsuario")
                    UserDefaults.standard.set(nombre, forKey: "nombreUsuario")
                    UserDefaults.standard.set(numero, forKey: "numeroUsuario")
                    UserDefaults.standard.set(familia, forKey: "familia")
                    UserDefaults.standard.set(fotoUrl, forKey: "fotoUrl")
                    print("FOTO: \(fotoUrl)")
                    UserDefaults.standard.set(responsable, forKey: "responsable")
                    UserDefaults.standard.set(correo, forKey: "correo")
                  
                    
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
    
    
    /*
    
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
            
            
            if let diccionarios = response.result.value as? [Dictionary<String,AnyObject>]{
                for diccionario in diccionarios{
                    print(diccionario)//print each of the dictionaries
                    
                    guard let id = diccionario["id"] as? String else {
                        print("No se pudo obtener el id")
                        return
                    }
                    
                    guard let titulo = diccionario["titulo"] as? String else {
                        print("No se pudo obtener el titulo")
                        return
                    }
                    
                    guard let fecha = diccionario["updated_at"] as? String else {
                        print("No se pudo obtener la fecha")
                        return
                    }
                    
                    var imagen:UIImage
                    imagen = UIImage.init(named: "appmenu05")!
                    
                    
                    guard let leido = diccionario["leido"] as? String else {
                        return
                    }
                    
                    guard let favorito = diccionario["favorito"] as? String else {
                        return
                    }
                    
                    guard let compartida = diccionario["compartida"] as? String else {
                        return
                    }
                    guard let eliminada = diccionario["eliminada"] as? String else {
                        return
                    }
                    
                    //leídas
                    if(Int(leido)!>0){
                        imagen = UIImage.init(named: "leidas_azul")!
                    }
                    //No leídas
                    if(Int(leido)==0){
                        imagen = UIImage.init(named: "noleidas_celeste")!
                    }
                    if(Int(favorito)!>0){
                        imagen = UIImage.init(named: "appmenu06")!
                    }
                    
                    if(Int(compartida)!>0){
                        imagen = UIImage.init(named: "appmenu08")!
                    }
                    
                   
                    var noLeida:Int = 0
                    if(Int(leido)! == 0){
                        noLeida = 1
                    }
                    
                     self.circulares.append(CircularTodas(id:Int(id)!,imagen: imagen,encabezado: "",nombre: titulo,fecha: fecha,estado: 0))
                    //Guardar las circulares
                    self.guardarCirculares(idCircular: Int(id)!, idUsuario: 1660, nombre: titulo, textoCircular: "", no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: Int(compartida)!, eliminada: Int(eliminada)!)
                }
                
                self.tableViewCirculares.reloadData()
            }
    
    */
    
    
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return menu.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath)
            as! PrincipalTableViewCell
        let m = menu[indexPath.row]
        //cell.lblMenu.text?=m.nombre
        //cell.lblMenu.font = UIFont(name: "Gotham Rounded", size: 17.0)
        cell.imgMenu.image=m.imagen
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let valor = menu[indexPath.row]
        
        if (valor.id==1){
            UserDefaults.standard.set(1,forKey:"descarga")
            performSegue(withIdentifier: "inicioSegue", sender: self)
          }
        if (valor.id==2){
            
            performSegue(withIdentifier: "webSegue", sender: self)
        }
        if(valor.id==3){
            
            
            let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas cerrar sesión?", preferredStyle: .alert)
                       
                       // Create OK button with action handler
                       let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                           GIDSignIn.sharedInstance()?.signOut()
                            
                            UserDefaults.standard.set(0,forKey: "autenticado")
                            UserDefaults.standard.set(0,forKey: "cuentaValida")
                            UserDefaults.standard.set("", forKey: "nombre")
                            UserDefaults.standard.set("", forKey: "email")
                            self.performSegue(withIdentifier: "unwindSegueToVC1", sender: self)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                  exit(0)
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
        
        if (valor.id==4){
           performSegue(withIdentifier: "credencialSegue", sender: self)
        }
        
        /*if (valor.id==5){
            
            performSegue(withIdentifier: "notificacionesSegue", sender: self)
        }*/
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
     
        
        let valida:Int = UserDefaults.standard.integer(forKey: "valida")
               if(valida == 0){
                   UserDefaults.standard.set(0, forKey: "cuentaValida")
                   GIDSignIn.sharedInstance()?.signOut()
                   performSegue(withIdentifier: "unwindSegueToVC1", sender: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                         DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                          exit(0)
                         }
                    }
                
                
               }
        
        
        let urlVideo = Bundle.main.url(forResource: "video_app", withExtension: "mp4")
        
        avPlayer = AVPlayer(url: urlVideo!)
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        avPlayer.volume = 0
        avPlayer.actionAtItemEnd = AVPlayer.ActionAtItemEnd.none
        
        avPlayerLayer.frame = view.layer.bounds
        view.backgroundColor = UIColor.clear;
        view.layer.insertSublayer(avPlayerLayer, at: 0)
        avPlayer.seek(to: CMTime.zero)
        avPlayer.play()
        paused = false
        /*NotificationCenter.default.addObserver(self,
                                               selector: Selector("playerItemDidReachEnd:"),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer.currentItem)
        */
        
    }
    
    func playerItemDidReachEnd() {
        avPlayer!.seek(to: CMTime.zero)
        avPlayer!.play()
       }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avPlayer.pause()
        paused = true
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    @IBAction func unwindToPrincipal(segue:UIStoryboardSegue) {
        
    }
    
}
