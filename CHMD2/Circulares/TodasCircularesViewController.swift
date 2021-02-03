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
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    var refreshControl = UIRefreshControl()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(_:true)
         circulares.removeAll()
        descarga = UserDefaults.standard.integer(forKey: "descarga")
         if ConexionRed.isConnectedToNetwork() == true {
            let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
             guard let _url = URL(string: address) else { return };
            
            let addressN=self.urlBase+self.metodoNotificaciones+"?usuario_id=\(self.idUsuario)"
            guard let _urlN = URL(string: addressN) else { return };
            
            //La primera vez, va a descargar, las siguientes siempre leer desde la base local
            if(descarga==1){
                self.getDataFromURL(url: _url)
                self.getDataFromURLNotificaciones(url:_urlN)
            }else{
              self.leerCirculares()
            }
                
           
         }else{
           self.leerCirculares()
        }
       
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        circulares.removeAll()
       
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
        //self.title="Circulares"
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
            
        } else {
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Se muestran las últimas circulares registradas", delegate: nil, cancelButtonTitle: "Aceptar")
            alert.show()
            
            //print("Leer desde la base")
            self.leerCirculares()
            
        }
        
        
      refreshControl.attributedTitle = NSAttributedString(string: "Suelta para refrescar")
      refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
      self.tableViewCirculares.addSubview(refreshControl)
       
        
    }
  
    @objc func refresh(_ sender: AnyObject) {
      circulares.removeAll()
        print("se ha refrescado...")
      if ConexionRed.isConnectedToNetwork() == true {
         let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
          guard let _url = URL(string: address) else { return };
          self.getDataFromURL(url: _url)
        //Actualizar las notificaciones
        let addressN=self.urlBase+self.metodoNotificaciones+"?usuario_id=\(self.idUsuario)"
                   guard let _urlN = URL(string: addressN) else { return };
        self.getDataFromURLNotificaciones(url:_urlN)
        self.leerCirculares()
       }
    }

   
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        var valorInicial:Int=1
        var valorFinal:Int=5
        let ultimo = circulares.count - 1
        if indexPath.row == ultimo {
            valorFinal = valorFinal+5
            let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
           guard let _url = URL(string: address) else { return };
           self.getDataFromURL(url: _url)
            print("se pasó el último registro")
            }
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
        
        if (indexPath.item >= 0 || indexPath.item < circulares.count) {
        guard let c = circulares[safe: indexPath.row] else{
            return cell
        }
              cell.lblTitulo.text? = c.nombre
              cell.lblPara.text?="Para: \(c.espec)"
            
            
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
            
             
             
              if(c.fecha != "")
              {
                               let dateFormatter = DateFormatter()
                               dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                               dateFormatter.locale = Locale(identifier: "es_ES_POSIX")
                               let date1 = dateFormatter.date(from: c.fecha)
                               
                               let intervalo = Date() - date1!
                               let diferenciaDias:Int = intervalo.day!
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
              }
                   
             cell.imgCircular.image = c.imagen
             
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
                                                                                                     
                                                      
                                                      
                                                           //let timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)
                                                                      //Modificar la imagen de la celda
                                                                       cell.imgCircular.image = UIImage(named:"circle")
                                                           
                                                          /* self.tableViewCirculares.reloadRows(at: [indexPath], with: .fade)
                                                           
                                                           let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)*/
                                                           //Modificar la imagen de la celda
                                                        
                                                                    //self.tableViewCirculares.reloadData()
                                                        
                                                       
                                                            
                                                       // }
                                                        
                                                        
                                                        
                                                               /*self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                        let timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)
                                                                   //Modificar la imagen de la celda
                                                                    cell.imgCircular.image = UIImage(named:"circle")*/
                                                        
                                                        
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
                                                           self.compartir(message: "Comparto la circular del colegio", link: "\(shortLink!)")
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
    
    
    
    /*func contextualFavAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
   
        let circular = circulares[indexPath.row]
        let action = UIContextualAction(style: .normal,
                                        title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                            let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                            self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                                
                                                self.viewDidLoad()
                                                self.viewWillAppear(true)
                                                
                                                
                                            }else{
                                            var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                            alert.show()
                                        }
                                            
                                            
            
        }
        // 7
        action.image = UIImage(named: "fav32")
        action.backgroundColor = UIColor.orange
        
        return action
    }*/
    
    
    
    func contextualUnreadAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
           // 1
           let circular = circulares[indexPath.row]
           // 2
           let action = UIContextualAction(style: .normal,
                                           title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                                let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                            self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                //self.viewDidLoad()
                                                //self.viewWillAppear(true)
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
        // 2
        let action = UIContextualAction(style: .normal,
                                        title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                            let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                                //Al eliminar una no leída, debe bajar el num. de notificaciones
                                                if circular.noLeido==1 {
                                                     UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                                                }
                                                
                                                
                                            //Borrar en el servidor
                                            
                                            self.delCircular(direccion: self.urlBase+"eliminarCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                            self.borraCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                            
                                               
                                              
                                                
                                               /* let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
                                                                       guard let _url = URL(string: address) else { return };
                                                                       self.getDataFromURL(url: _url)
                                                
                                                
                                                self.indexEliminar=indexPath.row*/
                                                
                                                
                                                
                                        
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
            print("posicion \(indexPath.row)")
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
            UserDefaults.standard.set(c.favorita, forKey: "circFav")
            self.actualizaLeidosCirculares(idCircular: c.id, idUsuario: Int(self.idUsuario)!)
                                                           
            
            
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
        print("Leer desde la base de datos local")
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales  FROM appCircularCHMD"
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
                       
                        
                        if(Int(leida) == 1){
                           imagen = UIImage.init(named: "circle_white")!
                        }else{
                            imagen = UIImage.init(named: "circle")!
                        }
                
                        /*if(Int(favorita)==1){
                           imagen = UIImage.init(named: "circle_white")!
                        }*/
                        if(Int(favorita)==1 && Int(leida)==0){
                          imagen = UIImage.init(named: "circle")!
                        }
                        if(Int(favorita)==1 && Int(leida)==1){
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
                
                
                if(eliminada==0 ){
                    self.circulares.append(CircularCompleta(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,noLeido:noLeida,favorita: Int(favorita),espec:especiales))
                }
               
              }
            
            self.tableViewCirculares.reloadData()

             }
            else {
             print("SELECT statement could not be prepared")
           }

           sqlite3_finalize(queryStatement)
       }
   
    
    //Esta función se utiliza para limpiar
    //la base de datos cuando se abra al tener conexión a internet
    
    
    func delete() {
        
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
               
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
                      FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
                  
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
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
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
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
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
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
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
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
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
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
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
        
        //Abrir la base
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
           
            
            
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            
            let query = "INSERT INTO appCircularCHMD(idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
                print("Circular almacenada correctamente")
            }else{
                print("Circular no se pudo guardar")
            }
            
        }
        
    
        
    }
    
    func guardarNotificaciones(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int){
        
        //Abrir la base
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1a.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
           
            
            
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            
            let query = "INSERT INTO appNotificacionCHMD(idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)"
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
                print("Circular almacenada correctamente")
            }else{
                print("Circular no se pudo guardar")
            }
            
        }
        
    
        
    }
    
    func getDataFromURL(url: URL) {
        print("Leer desde el servidor....")
        print(url)
        circulares.removeAll()
        
        self.delete()
               
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            print(data)
            
            if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                print(datos.count)
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
                       
                       guard let fecha = obj["created_at"] as? String else {
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
                    
                    
                    var esp:String?=""
                    if (obj["espec"] == nil){
                        esp=""
                    }else{
                        esp=obj["espec"] as? String
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
                       
                       var noLeida:Int = 0
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
                       print("Contenido: "+str)
                    
                    
                    
                    
                    
                       if(Int(eliminada)!==0){
                        self.circulares.append(CircularCompleta(id:Int(id)!,imagen: imagen,encabezado: "",nombre: titulo,fecha: fecha,estado: 0,contenido:"",adjunto:adj,fechaIcs: fechaIcs,horaInicialIcs: horaInicioIcs,horaFinalIcs: horaFinIcs, nivel:nv ?? "",noLeido:noLeida,favorita:Int(favorito)!,espec:esp!))
                       }
                    
                   
                    print("hora _ics: \(horaInicioIcs)")
                    print("fecha _ics: \(fechaIcs)")
                    /*
                     guardarCirculares(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int)
                     */
                     self.guardarCirculares(idCircular: Int(id)!, idUsuario: Int(self.idUsuario)!, nombre: titulo, textoCircular: str, no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: 0, eliminada: Int(eliminada)!,fecha: fecha,fechaIcs: fechaIcs,horaInicioIcs: horaInicioIcs,horaFinIcs: horaFinIcs,nivel: nv ?? "",adjunto:adj,especiales: esp!)
                    
                    
                }
                OperationQueue.main.addOperation {
                    
                    self.tableViewCirculares.reloadData();
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
                       
                       guard let fecha = obj["created_at"] as? String else {
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
                       
                       var noLeida:Int = 0
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
                     
                    
                  
                    /*
                     guardarCirculares(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int)
                     */
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
    
    
    
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if(!(searchBar.text?.isEmpty)!){
            buscando=true
            print("Buscar")
            circulares = circulares.filter({$0.nombre.lowercased().contains(searchBar.text!.lowercased())})
            self.tableViewCirculares?.reloadData()
        }else{
            buscando=false
            view.endEditing(true)
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
            
            
            
            
        }else{
            buscando=true
             print("Buscar")
            circulares = circulares.filter({$0.nombre.lowercased().contains(searchBar.text!.lowercased())})
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
 
