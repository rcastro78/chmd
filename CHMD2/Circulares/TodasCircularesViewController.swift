//
//  TodasCircularesViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 4/10/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import Alamofire
import SQLite3
import Firebase
import Foundation


class TodasCircularesViewController: UIViewController,UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate,UIGestureRecognizerDelegate,UITableViewDataSourcePrefetching {
func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetching row of \(indexPaths)")
    
    }
    
    
   @IBOutlet weak var btnDeshacer: UIBarButtonItem!
   
   @IBOutlet var tableViewCirculares: UITableView!
   @IBOutlet weak var barBusqueda: UISearchBar!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet weak var btnMarcarFavoritas: UIButton!
    @IBOutlet weak var btnMarcarNoLeidas: UIButton!
    @IBOutlet weak var btnMarcarEliminadas: UIButton!
    @IBOutlet weak var btnMarcarLeidas: UIButton!
    
    @IBOutlet weak var lblNoLeidas: UILabel!
    @IBOutlet weak var lblLeidas: UILabel!
    @IBOutlet weak var lblEliminar: UILabel!
    
    @IBOutlet weak var lblFavoritas: UILabel!
    
    @IBOutlet weak var btnEditar: UIBarButtonItem!
    
    var indexEliminar:Int=0
    var buscando=false
    var editando=false
    var circulares = [CircularCompleta]()
    var circularesFiltradas = [CircularCompleta]()
    var db: OpaquePointer?
    var idUsuario:String=""
    var descarga:Int=0
    var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
    var noleerMetodo:String="noleerCircular.php"
    var leerMetodo:String="leerCircular.php"
    var metodoCirculares:String="getCirculares_iOS.php"
    var metodoNotificaciones:String="getNotificaciones_iOS.php"
    var selecMultiple=false
    var circularesSeleccionadas = [Int]()
    var seleccion=[Int]()
    
    let base_url:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/";
    let get_usuario:String="getUsuarioEmail.php";
    let get_badge:String="recuentoBadge.php";
    
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    var refreshControl = UIRefreshControl()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(_:true)
        /*circulares.removeAll()
        descarga = UserDefaults.standard.integer(forKey: "descarga")
       
        let primeraCarga = UserDefaults.standard.integer(forKey: "primeraCarga")
        print("will appear primeraCarga \(primeraCarga)")
        
        
        if(primeraCarga==0){
            let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
                       guard let _url = URL(string: address) else { return };
                       self.getDataFromURL(url: _url)
            
        }else{
            self.leerCirculares()
        }*/
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(_:true)
        //circulares.removeAll()
        descarga = UserDefaults.standard.integer(forKey: "descarga")
        
        let primeraCarga = UserDefaults.standard.integer(forKey: "primeraCarga")
        
        if(primeraCarga==0){
            let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
                       guard let _url = URL(string: address) else { return };
                       self.getDataFromURL(url: _url)
            
        }else{
            self.leerCirculares()
        }
        
        UIApplication.shared.applicationIconBadgeNumber = contarCircularesNoLeidas()
    }
    
    func contarCircularesNoLeidas()->Int{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
      
        
           let consulta = "SELECT count(*) FROM appCircularCHMD where leida=0 and eliminada=0 and favorita=0 and tipo=1"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
        return Int(total)
    }
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
      
        
        self.hideKeyboardWhenTappedAround()
        self.tableViewCirculares.delegate=self
        self.tableViewCirculares.dataSource=self
        self.barBusqueda.delegate=self
        let pantalla: CGRect = UIScreen.main.bounds
        let ancho = pantalla.width
        self.revealViewController().rearViewRevealWidth = ancho
        if #available(iOS 13.0, *) {
            self.isModalInPresentation=false
        }
        
        btnMarcarFavoritas.isHidden=true
        btnMarcarNoLeidas.isHidden=true
        btnMarcarLeidas.isHidden=true
        btnMarcarEliminadas.isHidden=true
        lblFavoritas.isHidden=true
        lblNoLeidas.isHidden=true
        lblLeidas.isHidden=true
        lblEliminar.isHidden=true
        
        
        btnMarcarFavoritas.addTarget(self,action: #selector(agregarFavoritos), for: .touchUpInside)
        btnMarcarNoLeidas.addTarget(self,action: #selector(noleer), for: .touchUpInside)
        btnMarcarLeidas.addTarget(self,action: #selector(leer), for: .touchUpInside)
        btnMarcarEliminadas.addTarget(self,action: #selector(eliminar), for: .touchUpInside)
        
        tableViewCirculares.prefetchDataSource = self
        selecMultiple=false
        circularesSeleccionadas.removeAll()
        setupLongPressGesture()
       
        idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        
        self.tableViewCirculares.allowsMultipleSelection = true
        self.tableViewCirculares.allowsMultipleSelectionDuringEditing = true
        
     
        if ConexionRed.isConnectedToNetwork() == true {
            /*let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
             guard let _url = URL(string: address) else { return };
             getDataFromURL(url: _url)*/
            self.leerCirculares()
            
        } else {
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Se muestran las últimas circulares registradas", delegate: nil, cancelButtonTitle: "Aceptar")
            alert.show()
            
            //print("Leer desde la base")
            self.leerCirculares()
            
        }
        
        
    refreshControl.attributedTitle = NSAttributedString(string: "Suelta para refrescar")
      refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
      self.tableViewCirculares.addSubview(refreshControl)
       
        let idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
       
        
    }
  
    @objc func refresh(_ sender: AnyObject) {
      circulares.removeAll()
        print("se ha refrescado...")
        //self.leerCirculares()
        let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
        guard let _url = URL(string: address) else { return };
         self.getDataFromURL(url: _url)
        
    }
   
   
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    
    }
    
   
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return circulares.count
    
}
    

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath)
            as! CircularTableViewCell
        if(circulares.count>0){
            if (indexPath.item >= 0 || indexPath.item < circulares.count) {
                guard let c = circulares[safe: indexPath.row] else{
                    return cell
                }
                cell.lblTitulo.text? = c.nombre
                
                
                var nivel:String=""
                if(c.nivel!.count>0){
                    nivel = "\(c.nivel!) /"
                }
                
                var grados:String=""
                if(c.grados.count>0){
                    grados = "\(c.grados) /"
                }
                
                var espec:String=""
                if(c.espec.count>0){
                    espec = "\(c.espec) /"
                }
                
                var adm:String=""
                if(c.adm.count>0){
                    adm = "\(c.adm) /"
                }
                
                var rts:String=""
                if(c.rts.count>0){
                    rts = "\(c.rts) /"
                }
                
                var gps:String=""
                if(c.grupos.count>0){
                    gps = "\(c.grupos) /"
                }
                
                //nivel+grados+espec+adm+rts
                var para:String = "\(nivel) \(grados) \(espec) \(adm) \(rts)"
                para = para.trimmingCharacters(in: .whitespacesAndNewlines)
                para = String(para.dropLast())
                print("Para: \(para)")
                if(c.enviaTodos=="1"){
                    para="Todos"
                }
                
                if(c.enviaTodos=="0" && c.espec=="" && c.adm=="" && c.rts=="" && c.nivel!=="" && c.grados==""){
                    para="Personal"
                }
                
                
                cell.lblPara.text?="Para: \(para)"
                
                
                if c.favorita == 1
                {
                    let favImage = UIImage(named: "favIconCompleto")! as UIImage
                    cell.btnHacerFav.setImage(favImage, for: UIControl.State.normal)
                    
                }else{
                    let favImage = UIImage(named: "favIcon")! as UIImage
                    cell.btnHacerFav.setImage(favImage, for: UIControl.State.normal)
                }
                
                
                //Para hacer favoritas con un boton
                cell.btnHacerFav.addTarget(self, action: #selector(toggleFavorita), for: .touchUpInside)
                //cell.btnHacerFav.addTarget(self, action: #selector(makeNoLeida), for: .touchUpInside)
                cell.chkSeleccionar.addTarget(self, action: #selector(seleccionMultiple), for: .touchUpInside)
                
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                let date1 = dateFormatter.date(from: c.fecha)
                
                
                let intervalo = Date() - date1!
                let diferenciaDias:Int = intervalo.day!
                print("Intervalo en dias: \(diferenciaDias)")
                
                if(diferenciaDias<=7){
                    dateFormatter.dateFormat = "EEEE"
                }
                if(diferenciaDias>7 && diferenciaDias<=365){
                    dateFormatter.dateFormat = "dd/MM/yyyy"
                }
                if(diferenciaDias>365){
                    dateFormatter.dateFormat = "MMMM/yyyy"
                }
                
                let dia = dateFormatter.string(from: date1!)
                cell.lblFecha.text?=dia
                cell.imgCircular.image = c.imagen
            }
            
            if(!seleccion.contains(indexPath.row)){
                print("No seleccionada")
                cell.chkSeleccionar.isChecked=false
            }else{
                print("Seleccionada")
                cell.chkSeleccionar.isChecked=true
            }
            
            
            if(editando){
                let isEditing: Bool = self.isEditing
                cell.chkSeleccionar.isHidden = !isEditing
                cell.chkSeleccionar.setVisibility(UIView.Visibility(rawValue: "visible")!)
            }else{
                let isEditing: Bool = false
                cell.chkSeleccionar.isChecked=false
                
                cell.chkSeleccionar.isHidden = !isEditing
                cell.chkSeleccionar.setVisibility(UIView.Visibility(rawValue: "gone")!)
            }
            
            
        }
        
        return cell
        
    }
    
    
    //Función para manejar el swipe
    //comentado RCASTRO 08/04/2020
    //Si tiene un menú a la izquierda el leadingSwipe no funciona
    //El leadingSwipe es para manejar el swipe de izquierda a derecha
    /*override func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        
        let noleeAction = self.contextualUnreadAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [noleeAction])
        return swipeConfig
    }*/
    
    
    
    //El trailingSwipe es para manejar el swipe de derecha a izquierda
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let eliminaAction = self.contextualDelAction(forRowAtIndexPath: indexPath)
        let masAction = self.contextualMasAction(forRowAtIndexPath: indexPath)
        //let leeAction = self.contextualReadAction(forRowAtIndexPath: indexPath)
        //let noleeAction = self.contextualUnreadAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [eliminaAction,masAction])
        return swipeConfig
    }
    
    func contextualReadAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
           // 1
           let circular = circulares[indexPath.row]
           // 2
           let action = UIContextualAction(style: .normal,
                                           title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                                let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                            self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                              //self.circulares.remove(at: indexPath.row)
                                              //self.tableViewCirculares.reloadData()
                                                self.actualizaLeidosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                                                              
                                               }else{
                                                  var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                                  alert.show()
                                     }
               
           }
           // 7
        action.image = UIImage(named: "read32")
        action.backgroundColor = UIColor.blue
           
           return action
       }
    
    
    func contextualMasAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
    
         let circular = circulares[indexPath.row]
         let action = UIContextualAction(style: .normal,
                                         title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                             let idCircular:String = "\(circular.id)"
                                             if ConexionRed.isConnectedToNetwork() == true {
                                             
                                                //Mostrar el alert
                                                let alertController = UIAlertController(title: "Opciones", message: "Elige la opción que deseas", preferredStyle: .actionSheet)
                                                
                                                let actionFavorita = UIAlertAction(title: "Mover a favoritas", style: .default) { (action:UIAlertAction) in
                                                
                                                if(ConexionRed.isConnectedToNetwork()){
                                                                                                      
                                                    //capturar la celda
                                                       let cell = self.tableViewCirculares.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! CircularTableViewCell
                                                           self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                                  
                                                    let favImage = UIImage(named: "favIconCompleto")! as UIImage
                                                      cell.btnHacerFav.setImage(favImage, for: UIControl.State.normal)
                                                    
                                                    
                                                    self.actualizaFavoritosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                    
                                                    //self.circulares.removeAll()
                                                    //self.leerCirculares()
                                                    self.viewWillAppear(true)
                                                    self.viewDidLoad()
                                                    
                                                   /* self.tableViewCirculares.reloadRows(at: [indexPath], with: .fade)
                                                                                                          
                                                    let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)
                                                           
                                                               //Modificar la imagen de la celda
                                                                //cell.imgCircular.image = UIImage(named:"star")
                                                                }else{
                                                                var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                                            alert.show()*/
                                                       }
                                                
                                                }
                                                
                                                
                                                
                                                let actionLeer = UIAlertAction(title: "Mover a leídas", style: .default) { (action:UIAlertAction) in
                                                    
                                                    if(ConexionRed.isConnectedToNetwork()){
                                                                                                          
                                                        //capturar la celda
                                                           let cell = self.tableViewCirculares.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! CircularTableViewCell
                                                               self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                        
                                                        self.actualizaLeidosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                                                                     
                                                      self.viewWillAppear(true)
                                                      self.viewDidLoad()
                                                       
                                                        
                                                        //let timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)
                                                                   //Modificar la imagen de la celda
                                                             /*       cell.imgCircular.image = UIImage(named:"circle_white")
                                                        
                                                        self.tableViewCirculares.reloadRows(at: [indexPath], with: .fade)
                                                        
                                                        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)*/
                                                        //Modificar la imagen de la celda
                                                        
                                                        
                                                                    }else{
                                                                    var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                                                alert.show()
                                                           }
                                                    
                                                    }
                                                
                                                let actionNoLeer = UIAlertAction(title: "Mover a no leídas", style: .default) { (action:UIAlertAction) in
                                                
                                                    
                                                    
                                                    if(ConexionRed.isConnectedToNetwork()){
                                                                                                          
                                                        //capturar la celda
                                                         //capturar la celda
                                                              let cell = self.tableViewCirculares.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! CircularTableViewCell
                                                                  self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                        
                                                        self.actualizaNoLeidosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                         
                                                                       cell.imgCircular.image = UIImage(named:"circle")
                                                         
                                                                 }else{
                                                                    var alert = UIAlertView(title: "No está conectado a Internet", message: "Esta opción solo funciona con una conexión a Internet", delegate: nil, cancelButtonTitle: "Aceptar")
                                                                alert.show()
                                                           }
                                                    
                                                }
                                                    
                                                
                                                let actionCompartir = UIAlertAction(title: "Compartir esta circular", style: .default) { (action:UIAlertAction) in
                                                
                                                    let circularUrl = "https://www.chmd.edu.mx/WebAdminCirculares/ws/getCircularId6.php?id=\(idCircular)"
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
                                                        self.compartir(message: "Comparto: \(UserDefaults.standard.string(forKey:"nombre"))", link: "\(shortLink!)")
                                                       }
                                                
                                                }
                                                let actionCancelar = UIAlertAction(title: "Cancelar", style:.cancel) { (action:UIAlertAction) in
                                                              // self.dismiss(animated: true, completion: nil)
                                                           }
                                                alertController.addAction(actionFavorita)
                                                alertController.addAction(actionLeer)
                                                alertController.addAction(actionNoLeer)
                                                alertController.addAction(actionCompartir)
                                                alertController.addAction(actionCancelar)
                                                self.present(alertController, animated: true, completion: nil)
                                                
                                             }else{
                                             var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                             alert.show()
                                         }
                                             
                                             
             
         }
         // 7
         action.image = UIImage(named: "mas32")
        action.backgroundColor = UIColor.gray
         
         return action
     }
    
    
    
    
    
    func contextualUnreadAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
          let circular = circulares[indexPath.row]
          let action = UIContextualAction(style: .normal,
                                           title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                                let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                            self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                self.actualizaNoLeidosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                }else{
                                                  var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                                  alert.show()
                                     }
               
           }
           // 7
        action.image = UIImage(named: "unread32")
        action.backgroundColor = UIColor.blue
           
           return action
       }
    
    func contextualDelAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
        
        let circular = circulares[indexPath.row]

        let action = UIContextualAction(style: .normal,
                                        title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                            let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                                //Al eliminar una no leída, debe bajar el num. de notificaciones
                                                if circular.leido==0 {
                                                     UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                                }
                                                
                                                
                                            //Borrar en el servidor
                                            
                                            self.delCircular(direccion: self.urlBase+"eliminarCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                            self.borraCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                            
                                            }else{
                                                var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                                 alert.show()
                                            }
                                            
            
        }
        // 7
        action.image = UIImage(named: "delIcon32")
        action.backgroundColor = UIColor.red
        
        return action
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
       
        
        if (revealViewController().frontViewPosition == FrontViewPosition.right){
             self.revealViewController()?.revealToggle(animated: true)
        }
       
       
        if(editando==false){
        if (indexPath.item >= 0 || indexPath.item < circulares.count) {
            guard let c = circulares[safe: indexPath.row] else{
                return
            }
            
            let cell = tableView.cellForRow(at: indexPath)
            cell?.selectionStyle = .none
            UserDefaults.standard.set(indexPath.row,forKey:"posicion")
            UserDefaults.standard.set(c.id,forKey:"id")
            print("circular_id \(c.id)")
            UserDefaults.standard.set(c.nombre,forKey:"nombre")
            UserDefaults.standard.set(c.fecha,forKey:"fecha")
            UserDefaults.standard.set(c.contenido,forKey:"contenido")
            UserDefaults.standard.set(c.fechaIcs,forKey:"fechaIcs")
            UserDefaults.standard.set(c.horaInicialIcs,forKey:"horaInicialIcs")
            UserDefaults.standard.set(c.horaFinalIcs,forKey:"horaFinalIcs")
            UserDefaults.standard.set(c.nivel,forKey:"nivel")
            UserDefaults.standard.set(0, forKey: "viaNotif")
            UserDefaults.standard.set(c.noLeido, forKey: "noLeido")
            UserDefaults.standard.set(1, forKey: "tipoCircular")
            UserDefaults.standard.set(0, forKey: "clickeado")
            UserDefaults.standard.set(c.favorita, forKey: "circFav")
            self.actualizaLeidosCirculares(idCircular: c.id, idUsuario: Int(self.idUsuario)!)
                                                           
            print("selected leido -> \(c.leido) selected no leido -> \(c.noLeido)")
            
            performSegue(withIdentifier: "TcircularSegue", sender:self)
            }
        }else{
         //está editando
            let c = circulares[indexPath.row]
            let cell = tableView.cellForRow(at: indexPath) as! CircularTableViewCell
            cell.selectionStyle = .none
            if(cell.chkSeleccionar.isChecked==false){
                cell.chkSeleccionar.isChecked=true
            }else{
                 cell.chkSeleccionar.isChecked=false
            }
            seleccionMultiple(cell.chkSeleccionar)
            
        }
  
              
}
    
  
    
    //Leer las circulares cuando no haya internet
    func leerCirculares(){
        circulares.removeAll()
        print("Leer desde la base de datos local")
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales  FROM appCircularCHMD WHERE tipo=1 ORDER BY idCircular DESC"
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
                
                
                var especiales:String="";
                if  let es = sqlite3_column_text(queryStatement, 11) {
                    especiales = String(cString: es)
                    } else {
                      print("name not found")
                    }
                
                
               
                        let adj = sqlite3_column_int(queryStatement, 14)
                var nl:Int=0
                       
                        if(Int(leida) == 1){
                           imagen = UIImage.init(named: "circle_white")!
                            nl=0
                        }else{
                            imagen = UIImage.init(named: "circle")!
                            nl=1
                        }
                
                
                        print("titulo> \(titulo), nl \(leida)")
                
                        /*if(Int(favorita)==1){
                           imagen = UIImage.init(named: "circle_white")!
                        }*/
                        if(Int(favorita)==1 && Int(leida)==0){
                          imagen = UIImage.init(named: "circle")!
                        }
                        if(Int(favorita)==1 && Int(leida)==1){
                          imagen = UIImage.init(named: "circle_white")!
                        }
                
                var fechaCircular="";
                if let fecha = sqlite3_column_text(queryStatement, 6) {
                    fechaCircular = String(cString: fecha)
                   
                   } else {
                    print("name not found")
                }
                
                print("FECHACIRC \(fechaCircular)")
                 
                 
                 var fechaCircular2="";
                 var fechaCircular3="";
                 
                
                
                //grados:String,adm:String,grupos:String,rts:String,enviaTodos:String
                if(eliminada==0 ){
                    self.circulares.append(CircularCompleta(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,leido:Int(leida),favorita: Int(favorita),espec:especiales,noLeido:nl,grados: "",adm: "",grupos: "",rts: "",enviaTodos: ""))
                }
               
              }
            
            self.tableViewCirculares.reloadData()

             }
            else {
             print("SELECT statement could not be prepared")
           }

        
        if self.refreshControl.isRefreshing {
          self.refreshControl.endRefreshing()
        }
        
        
           sqlite3_finalize(queryStatement)
        
        DispatchQueue.main.async {
            self.tableViewCirculares.reloadData()
        }
        
       }
   
    
    //Esta función se utiliza para limpiar
    //la base de datos cuando se abra al tener conexión a internet
    
    
    func delete() {
        
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
               
               if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
                   print("Error en la base de datos")
               }else{
        
      var deleteStatement: OpaquePointer?
        var deleteStatementString="DELETE FROM appCircularCHMD"
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
    
    
    func deleteNotificaciones() {
           
           let fileUrl = try!
                      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
                  
                  if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
                      print("Error en la base de datos")
                  }else{
           
         var deleteStatement: OpaquePointer?
           var deleteStatementString="DELETE FROM appNotificacionCHMD"
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
    
    func borraCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            
            let query = "UPDATE appCircularCHMD SET eliminada=1,favorita=0 WHERE idCircular=? AND idUsuario=?"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular eliminada correctamente")
                }else{
                    print("Circular no se pudo eliminar")
                }
                
            }
            
    }
    
    func actualizaFavoritosCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            self.circulares.removeAll()
            let query = "UPDATE appCircularCHMD SET favorita=1 WHERE idCircular=? AND idUsuario=?"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular eliminada correctamente")
                }else{
                    print("Circular no se pudo eliminar")
                }
                
            }
            
    }
    
    func eliminaFavoritosCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            self.circulares.removeAll()
            let query = "UPDATE appCircularCHMD SET favorita=0 WHERE idCircular=? AND idUsuario=?"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular actualizada correctamente")
                }else{
                    print("Circular no se pudo eliminar")
                }
                
            }
            
    }
    
    
    func actualizaLeidosCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            self.circulares.removeAll()
            let query = "UPDATE appCircularCHMD SET leida=1 WHERE idCircular=? AND idUsuario=?"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular actualizada correctamente")
                }else{
                    print("Circular no se pudo actualizar")
                }
                
            }
            
    }
    
    
    
    func actualizaNoLeidosCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            self.circulares.removeAll()
            let query = "UPDATE appCircularCHMD SET leida=0 WHERE idCircular=? AND idUsuario=?"
            
            if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                print("Error")
            }
            
            if sqlite3_bind_int(statement,1,Int32(idCircular)) != SQLITE_OK {
                print("Error campo 1")
            }
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
                print("Error campo 2")
            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                    print("Circular actualizada correctamente")
                }else{
                    print("Circular no se pudo actualizar")
                }
                
            }
            
    }
    
    
    
    
    func guardarCirculares(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int,especiales:String){
        var badge:Int=0
        //Abrir la base
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
           
            
            
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
       

            let query = "INSERT INTO appCircularCHMD(idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales,tipo) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,1)"
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
              
                print("Circular almacenada correctamente!")
            }else{
                print("Circular no se pudo guardar")
            }
          
        }
        
    
        
    }
    var notifNoLeidas=0
    func guardarNotificaciones(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int){
        
        //Abrir la base
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
           
            
            
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            
            let query = "INSERT INTO appCircularCHMD(idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,tipo) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,2)"
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
            
           
            
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Notificacion_ almacenada correctamente")
                self.notifNoLeidas += 1
                
                
            }else{
                print("Notificacion_ no se pudo guardar")
            }
            
        }
        
        UserDefaults.standard.set(self.notifNoLeidas, forKey: "totalNotif")
    
        
    }
    
    
    
    
   
    
    
    
    
    
    func getDataFromURL(url: URL) {
        print("Leer desde el servidor....")
        print(url)
        circulares.removeAll()
        UserDefaults.standard.setValue(1, forKey: "primeraCarga")
        self.delete()
        
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
                           
                           
                          
                           
                           guard let fecha = obj["fecha"] as? String else {
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
                        
                           if(Int(eliminada)!==0){
                            print(titulo)
                            self.circulares.append(CircularCompleta(id:Int(id)!,imagen: imagen,encabezado: "",nombre: titulo,fecha: fecha,estado: 0,contenido:"",adjunto:adj,fechaIcs: fechaIcs,horaInicialIcs: horaInicioIcs,horaFinalIcs: horaFinIcs, nivel:nv ?? "",leido:Int(leido)!,favorita:Int(favorito)!,espec:esp!,noLeido:noLeida,
                                                                    grados: grados!,adm: adm!,grupos: "",rts: rts!,enviaTodos: enviaTodos!))
                           }
                        
                        
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
                        self.guardarCirculares(idCircular: Int(id)!, idUsuario: Int(self.idUsuario)!, nombre: titulo, textoCircular: str.replacingOccurrences(of: "&nbsp;", with: ""), no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: 0, eliminada: Int(eliminada)!,fecha: fecha,fechaIcs: fechaIcs,horaInicioIcs: horaInicioIcs,horaFinIcs: horaFinIcs,nivel: nv ?? "",adjunto:adj,especiales: para)
                        
                        
                    }
                    OperationQueue.main.addOperation {
                        
                        self.tableViewCirculares.reloadData();
                    }
                }
                
            }else{
                print(error.debugDescription)
                print(error?.localizedDescription)
            }
            
            
            }.resume()
        
        if self.refreshControl.isRefreshing {
          self.refreshControl.endRefreshing()
        }
        
        
        UserDefaults.standard.set(0, forKey: "descarga")
        
    }
    
    
    func getDataFromURLNotificaciones(url: URL) {
        print("Leer desde el servidor....")
        print(url)
        circulares.removeAll()
        self.deleteNotificaciones()
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            print(data)
            
            if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                print(datos.count)
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
                       
                       
                       guard let leido = obj["leido"] as? String else {
                           return
                       }
                       
                       guard let fecha = obj["fecha"] as? String else {
                                                  return
                                              }
                       
                       guard let favorito = obj["favorito"] as? String else {
                           return
                       }
                       
                       guard let adjunto = obj["adjunto"] as? String else {
                                                  return
                                              }
                       
                       guard let eliminada = obj["eliminado"] as? String else {
                           return
                       }
                       
                       guard let texto = obj["contenido"] as? String else {
                           return
                       }
                       
                       guard let fechaIcs = obj["fecha_ics"] as? String else {
                         return
                       }
                       guard let horaInicioIcs = obj["hora_inicial_ics"] as? String else {
                                                return
                                              }
                       
                      
                       guard let horaFinIcs = obj["hora_final_ics"] as? String else {
                                                                       return
                                                                     }
                       
                   
                       //Con esto se evita la excepcion por los valores nulos
                       var nv:String?
                       if (obj["nivel"] == nil){
                           nv=""
                       }else{
                           nv=obj["nivel"] as? String
                       }

                       
                    var noLeido:Int=0
                       
                       //leídas
                       if(Int(leido)!>0){
                           imagen = UIImage.init(named: "circle_white")!
                           
                       }
                       //No leídas
                       if(Int(leido)==0 && Int(favorito)==0){
                           imagen = UIImage.init(named: "circle")!
                        noLeido=1
                       }
                    
                    if(Int(leido)==0){
                     noLeido=1
                    }
                    
                       
                       var noLeida:Int = 0
                       if(Int(leido)! == 0){
                           noLeida = 1
                       }else{
                        noLeida = 0
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
                     
                    
                    print("notif- guardar nl: \(noLeida)")
                  
                  
                     self.guardarNotificaciones(idCircular: Int(id)!, idUsuario: Int(self.idUsuario)!, nombre: titulo, textoCircular: str, no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: 0, eliminada: Int(eliminada)!,fecha: fecha,fechaIcs: fechaIcs,horaInicioIcs: horaInicioIcs,horaFinIcs: horaFinIcs,nivel: nv ?? "",adjunto:adj)
                    
                }
                }
                OperationQueue.main.addOperation {
                    
                }
            }else{
                print(error.debugDescription)
                print(error?.localizedDescription)
            }
            
            
            }.resume()
        
        
        
    }
    
    
    
    func setupLongPressGesture() {
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        longPressGesture.minimumPressDuration = 1.0 // 1 second press
        longPressGesture.delegate = self
        self.tableViewCirculares.addGestureRecognizer(longPressGesture)
        
        //Mostrar los botones
              
        
    }
    
    
    
    /*let footerView = UIView()
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        footerView.isHidden=true
        footerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height:
       100)
     
                                //Favoritos al pie
                                let btnFavoritos = UIButton(type: .custom)
                                 btnFavoritos.frame=CGRect(x:10,y:20,width:32,height:32)
                                 btnFavoritos.setImage(UIImage(named:"estrella_fav"), for: .normal)
                                 //btnFavoritos.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
                                 btnFavoritos.clipsToBounds = true
                                 //btnFavoritos.layer.cornerRadius = 32
                                 //btnFavoritos.layer.borderColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
                               
                                 btnFavoritos.addTarget(self,action: #selector(agregarFavoritos), for: .touchUpInside)
        
        
        let btnNoLeidos = UIButton(type: .custom)
        btnNoLeidos.frame=CGRect(x:100,y:20,width:32,height:32)
        btnNoLeidos.setImage(UIImage(named:"icono_noleido"), for: .normal)
        //btnNoLeidos.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        btnNoLeidos.clipsToBounds = true
        //btnNoLeidos.layer.cornerRadius = 32
        //btnNoLeidos.layer.borderColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        
        btnNoLeidos.addTarget(self,action: #selector(noleer), for: .touchUpInside)
        
        
              let btnEliminar = UIButton(type: .custom)
               btnEliminar.frame=CGRect(x:180,y:20,width:32,height:32)
               btnEliminar.setImage(UIImage(named:"delIcon"), for: .normal)
               //btnEliminar.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
               btnEliminar.clipsToBounds = true
               //btnEliminar.layer.cornerRadius = 32
               //btnEliminar.layer.borderColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
              
               btnEliminar.addTarget(self,action: #selector(eliminar), for: .touchUpInside)
        
        
        let btnDeshacer = UIButton(type: .custom)
        btnDeshacer.frame=CGRect(x:260,y:20,width:32,height:32)
        btnDeshacer.setImage(UIImage(named:"undo"), for: .normal)
        //btnDeshacer.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        btnDeshacer.clipsToBounds = true
        //btnDeshacer.layer.cornerRadius = 32
        //btnDeshacer.layer.borderColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
       
        btnDeshacer.addTarget(self,action: #selector(deshacer), for: .touchUpInside)
        
        
       footerView.addSubview(btnFavoritos)
       footerView.addSubview(btnNoLeidos)
       footerView.addSubview(btnEliminar)
       footerView.addSubview(btnDeshacer)
       return footerView
    }
    */
    //el pie
    
    @objc func reaccionar()
    {
        self.viewDidLoad()
        self.viewWillAppear(true)
        //tableViewCirculares.reloadData()
    }
    
    
    
    
    @objc func toggleFavorita(_ sender:UIButton){
           var superView = sender.superview
           
           while !(superView is UITableViewCell) {
               superView = superView?.superview
           }
           let cell = superView as! CircularTableViewCell
           if let indexpath = tableViewCirculares.indexPath(for: cell){
               let favImage = UIImage(named: "favIconCompleto")! as UIImage
               cell.btnHacerFav.setImage(favImage, for: UIControl.State.normal)
            
            
             guard let c = circulares[safe: indexpath.row] else{
                    return
                }
            
            if c.favorita==1 {
                
                              
                let favImage = UIImage(named: "favIcon")! as UIImage
                              cell.btnHacerFav.setImage(favImage, for: UIControl.State.normal)
                
            }
            
            
                let idCircular = c.id
                if ConexionRed.isConnectedToNetwork() == true {
                    /*self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))*/
                    if c.favorita==0 {
                    self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))
                        //self.viewDidLoad()
                        //self.viewWillAppear(true)
                        
                        self.actualizaFavoritosCirculares(idCircular: idCircular, idUsuario: Int(self.idUsuario)!)
                        self.circulares.removeAll()
                        self.leerCirculares()
                    
                    }else{
                        self.favCircular(direccion: self.urlBase+"elimFavCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))
                            //                   self.viewDidLoad()
                            //                   self.viewWillAppear(true)
                        self.eliminaFavoritosCirculares(idCircular: idCircular, idUsuario: Int(self.idUsuario)!)
                        self.circulares.removeAll()
                        self.leerCirculares()
                        
                    }
                    
                    
                    }else{
                    var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                    alert.show()
                }
            
            
            }else{
            
        }
        
    }
    
    @objc func makeNoLeida(_ sender:UIButton){
        var superView = sender.superview
        
        while !(superView is UITableViewCell) {
            superView = superView?.superview
        }
        let cell = superView as! CircularTableViewCell
        if let indexpath = tableViewCirculares.indexPath(for: cell){
            let noLeeImg = UIImage(named: "circle")! as UIImage
            cell.imgCircular.image=noLeeImg
            
            let c = circulares[indexpath.row]
                   let idCircular = c.id
                   
                   if ConexionRed.isConnectedToNetwork() == true {
                    noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: String(idCircular))
                   }
            
        }
       
            
    }
    
    
    @objc func hacerFavorita(_ sender:UIButton){
           var superView = sender.superview
           
           while !(superView is UITableViewCell) {
               superView = superView?.superview
           }
           let cell = superView as! CircularTableViewCell
           if let indexpath = tableViewCirculares.indexPath(for: cell){
               let favImage = UIImage(named: "favIconCompleto")! as UIImage
               cell.btnHacerFav.setImage(favImage, for: UIControl.State.normal)
            
            
                let c = circulares[indexpath.row]
                let idCircular = c.id
                if ConexionRed.isConnectedToNetwork() == true {
                    /*self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))*/
                    self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))
                       // self.viewDidLoad()
                      //  self.viewWillAppear(true)
                    self.actualizaFavoritosCirculares(idCircular: idCircular, idUsuario: Int(self.idUsuario)!)
                    }else{
                    var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                    alert.show()
                }
            
            
            }else{
            
        }
        
    }
    
    
     @objc func seleccionMultiple(_ sender:UIButton){
        var superView = sender.superview
        
        while !(superView is UITableViewCell) {
            superView = superView?.superview
        }
        let cell = superView as! CircularTableViewCell
        if let indexpath = tableViewCirculares.indexPath(for: cell){
            if(cell.chkSeleccionar.isChecked){
               
                //let c = tableViewCirculares.cellForRow(at: indexpath) as! CircularTableViewCell
                btnMarcarFavoritas.isHidden=false
                btnMarcarNoLeidas.isHidden=false
                btnMarcarLeidas.isHidden=false
                btnMarcarEliminadas.isHidden=false
                
                lblFavoritas.isHidden=false
                lblNoLeidas.isHidden=false
                lblLeidas.isHidden=false
                lblEliminar.isHidden=false
                
                /*btnFavs.isHidden=false
                btnNoLeer.isHidden=false
                btnEliminar.isHidden=false
                btnDeshacer.isHidden=false*/
                tableViewCirculares.allowsSelection = true
                guard let c = circulares[safe: indexpath.row] else{
                    return
                }
                //print("Seleccionado: \(c.id)")
                circularesSeleccionadas.append(c.id)
                seleccion.append(indexpath.row)
                print("recuento: \(circularesSeleccionadas.count)")
            }else{
               guard let c = circulares[safe: indexpath.row] else{
                   return
               }
                //print("No Seleccionado: \(c.id)")
                let itemEliminar = c.id
                let selecEliminar = indexpath.row
                while circularesSeleccionadas.contains(itemEliminar) {
                    if let indice = circularesSeleccionadas.firstIndex(of: itemEliminar) {
                        let index = seleccion.firstIndex(of: selecEliminar) ?? 0
                        circularesSeleccionadas.remove(at: indice)
                        seleccion.remove(at: index)
                    }
                }
                
                if(circularesSeleccionadas.count<=0){
                      /*btnFavs.isHidden=true
                      btnNoLeer.isHidden=true
                      btnEliminar.isHidden=true
                      btnDeshacer.isHidden=true*/
                    
                    btnMarcarFavoritas.isHidden=true
                    btnMarcarNoLeidas.isHidden=true
                    btnMarcarLeidas.isHidden=true
                    btnMarcarEliminadas.isHidden=true
                    
                    lblFavoritas.isHidden=true
                                  lblNoLeidas.isHidden=true
                                  lblLeidas.isHidden=true
                                  lblEliminar.isHidden=true
                    
                    tableViewCirculares.allowsSelection = false
                }
                         
              
                
                //print("recuento: \(circularesSeleccionadas.count)")
            }
        }
    }
    
    
    
    @objc func agregarFavoritos(){
         
        circulares.removeAll()
          if ConexionRed.isConnectedToNetwork() == true {
          for c in circularesSeleccionadas{
            self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: "\(c)")
            self.actualizaFavoritosCirculares(idCircular: c, idUsuario: Int(self.idUsuario)!)
            
           }
            
            circulares.removeAll()
            circularesSeleccionadas.removeAll()
            seleccion.removeAll()
            self.leerCirculares()
            
          }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
             alert.show()
        }
         _ = btnEditar.target?.perform(btnEditar.action, with: nil)
    }
    
    
   @objc func noleer(){
        //
       circulares.removeAll()
         if ConexionRed.isConnectedToNetwork() == true {
         for c in circularesSeleccionadas{
            self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: "\(c)")
           self.actualizaNoLeidosCirculares(idCircular: c, idUsuario: Int(self.idUsuario)!)
            
            //Boton fav a favIcon
            
            
            
         }
           
            circulares.removeAll()
                      circularesSeleccionadas.removeAll()
                      seleccion.removeAll()
                      self.leerCirculares()
                    self.tableViewCirculares.reloadData()
                    }else{
                      var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                       alert.show()
                  }
       
       _ = btnEditar.target?.perform(btnEditar.action, with: nil)
   }
    
   
    @objc func eliminar(){
       
         if ConexionRed.isConnectedToNetwork() == true {
             //
                    for c in circularesSeleccionadas{
                      self.delCircularCompleta(direccion: self.urlBase+"eliminarCircular.php", usuario_id: self.idUsuario, circular_id: "\(c)")
                     
                   self.borraCirculares(idCircular: c, idUsuario: Int(self.idUsuario)!)
                                }
                                  
                                   circulares.removeAll()
                                             circularesSeleccionadas.removeAll()
                                             seleccion.removeAll()
                                             self.leerCirculares()
                                             
                                           }else{
                                             var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                              alert.show()
                                         }
                              
                              _ = btnEditar.target?.perform(btnEditar.action, with: nil)
        
    }
    
    
    
    @objc func deshacer(){
    
    }
    
     @objc func leer(){
     
        
           circulares.removeAll()
             if ConexionRed.isConnectedToNetwork() == true {
             for c in circularesSeleccionadas{
                self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: "\(c)")
            self.actualizaLeidosCirculares(idCircular: c, idUsuario: Int(self.idUsuario)!)
                    }
                      
                       circulares.removeAll()
                                 circularesSeleccionadas.removeAll()
                                 seleccion.removeAll()
                                 self.leerCirculares()
                                 
                               }else{
                                 var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                  alert.show()
                             }
                  
                  _ = btnEditar.target?.perform(btnEditar.action, with: nil)
       }

    //Pie
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            //footerView.isHidden=false
            //footerView.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
           
        }
    }
    
    

    //Operaciones con las circulares
    func favCircular(direccion:String, usuario_id:String, circular_id:String){
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
    
    func leerCircular(direccion:String, usuario_id:String, circular_id:String){
           let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
           Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
               switch (response.result) {
               case .success:
                   print(response)
                    UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                   
                   self.circulares.removeAll()
                   self.leerCirculares()
                   
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
                   self.circulares.removeAll()
                   self.leerCirculares()
                   break
               case .failure:
                   print(Error.self)
               }
           }
       }
    
    
    func delCircularCompleta(direccion:String, usuario_id:String, circular_id:String){
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
    
 func delCircular(direccion:String, usuario_id:String, circular_id:String){
     
    //Preguntar
    let dialogMessage = UIAlertController(title: "CHMD", message: "¿Deseas eliminar esta circular?", preferredStyle: .alert)
               
               // Create OK button with action handler
               let ok = UIAlertAction(title: "Sí", style: .default, handler: { (action) -> Void in
                
                
                let parameters: Parameters = ["usuario_id": usuario_id, "circular_id": circular_id]      //This will be your parameter
                    Alamofire.request(direccion, method: .post, parameters: parameters).responseJSON { response in
                        switch (response.result) {
                        case .success:
                            print(response)
                            //self.circulares.remove(at: self.indexEliminar)
                            //self.tableViewCirculares.reloadData()
                            self.circulares.removeAll()
                            self.leerCirculares()
                            
                            break
                        case .failure:
                            print(Error.self)
                        }
                    }
                
                
                
                })
    
    
    let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                self.leerCirculares()
               }
               
               //Add OK and Cancel button to dialog message
               dialogMessage.addAction(ok)
               dialogMessage.addAction(cancel)
               
               // Present dialog message to user
               self.present(dialogMessage, animated: true, completion: nil)
    
 }
    
    
    
    
    func obtenerRecuentoBadge(uri:String){
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
                  
                    guard let notificaciones = diccionario["notificaciones"] as? String else {
                        print("No se pudo obtener el codigo")
                        return
                    }
                    
                   
                   //Settear el badge
                    UIApplication.shared.applicationIconBadgeNumber = Int(notificaciones)!
                    
                      
                }
            }
                
        }
        
        
     
        
    }
    
    
    
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if(!(searchBar.text?.isEmpty)!){
            buscando=true
            print("Buscar")
            //Buscar en el titulo o en el contenido
            circulares = circulares.filter({$0.nombre.lowercased().contains(searchBar.text!.lowercased()) || $0.contenido.lowercased().contains(searchBar.text!.lowercased())})
            self.tableViewCirculares?.reloadData()
        }else{
            buscando=false
            view.endEditing(true)
            leerCirculares()
            self.tableViewCirculares?.reloadData()
        }
    }
    
    
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText:String) {
        if searchBar.text==nil || searchBar.text==""{
            buscando=false
            view.endEditing(true)
           let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
           guard let _url = URL(string: address) else { return };
            self.getDataFromURL(url: _url)
            
            let addressN=self.urlBase+self.metodoNotificaciones+"?usuario_id=\(self.idUsuario)"
                       guard let _urlN = URL(string: addressN) else { return };
            self.getDataFromURLNotificaciones(url:_urlN)
            
            
        }else{
            buscando=true
             print("Buscar")
            circulares = circulares.filter({$0.nombre.lowercased().contains(searchBar.text!.lowercased()) || $0.contenido.lowercased().contains(searchBar.text!.lowercased())})
            self.tableViewCirculares?.reloadData()
            
        }
    }
    
    
    
    @IBAction func unwindCirculares(segue:UIStoryboardSegue) {}
     

    
    
    @IBAction func habilitarSeleccion(_ sender: Any) {
        if(!editando){
            self.isEditing=true
            editando=true
            tableViewCirculares.reloadData()
            self.btnEditar.title="CANCELAR"
            
        }else{
            self.isEditing=false
            editando=false
            tableViewCirculares.reloadData()
            seleccion.removeAll()
            self.btnEditar.title="EDITAR"
            btnMarcarFavoritas.isHidden=true
            btnMarcarLeidas.isHidden=true
            btnMarcarNoLeidas.isHidden=true
            btnMarcarEliminadas.isHidden=true
            
            lblFavoritas.isHidden=true
                          lblNoLeidas.isHidden=true
                          lblLeidas.isHidden=true
                          lblEliminar.isHidden=true
        }
        
    }
    
    func compartir(message: String, link: String) {
          let date = Date()
          let msg = message
          let urlWhats = "whatsapp://send?text=\(msg+"\n"+link)"

          if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
              if let whatsappURL = NSURL(string: urlString) {
                  if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                      UIApplication.shared.openURL(whatsappURL as URL)
                  } else {
                      print("Por favor instala whatsapp")
                  }
              }
          }
      }
    
    
    
    
    
    
    
    
}
 
