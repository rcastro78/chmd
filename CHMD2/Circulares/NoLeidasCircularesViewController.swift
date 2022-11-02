//
//  NoLeidasCircularesViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 4/11/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import Alamofire
import SQLite3
import Firebase

class NoLeidasCircularesViewController:  UIViewController,UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate,UIGestureRecognizerDelegate,UITableViewDataSourcePrefetching {
func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        print("prefetching row of \(indexPaths)")
    
    }
    var editando=false
    var indexEliminar:Int=0
     var refreshControl = UIRefreshControl()
    @IBOutlet weak var btnEditar: UIBarButtonItem!
    
   @IBOutlet var tableViewCirculares: UITableView!
   @IBOutlet weak var barBusqueda: UISearchBar!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    let searchController = UISearchController(searchResultsController: nil)
    @IBOutlet weak var btnMarcarLeidas: UIButton!
    @IBOutlet weak var btnMarcarFavoritas: UIButton!
    @IBOutlet weak var btnMarcarEliminadas: UIButton!
    
    @IBOutlet weak var lblEliminar: UILabel!
    @IBOutlet weak var lblFavoritas: UILabel!
    @IBOutlet weak var lblNoLeidas: UILabel!
    
    
    
    @IBAction func deseleccionar(_ sender: UIBarButtonItem) {
        if ConexionRed.isConnectedToNetwork() == true {
        circulares.removeAll()
            
            for s in seleccion{
                let indexPath = IndexPath(row:s, section:0)
                let cell = self.tableViewCirculares.dequeueReusableCell(withIdentifier: "celda", for: indexPath)
                          as! CircularTableViewCell
                
                if(cell.chkSeleccionar.isChecked == true){
                    cell.chkSeleccionar.isChecked=false
                }
            }
            
            
            seleccion.removeAll()
            circularesSeleccionadas.removeAll()
            
            
        let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
        guard let _url = URL(string: address) else { return };
        self.getDataFromURL(url: _url)
            
            btnMarcarLeidas.isHidden=true
            btnMarcarFavoritas.isHidden=true
            btnMarcarEliminadas.isHidden=true
            
            lblFavoritas.isHidden=true
            lblNoLeidas.isHidden=true
            lblEliminar.isHidden=true
            
        //tableViewCirculares.reloadData()
           }else{
                     var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                      alert.show()
           }
    }
    
    
    
    
    var buscando=false
    var circulares = [CircularCompleta]()
    var circularesFiltradas = [CircularCompleta]()
    var db: OpaquePointer?
    var idUsuario:String=""
    var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
    var metodoCirculares:String="getNotificaciones_iOS.php"
    var noleerMetodo:String="noleerCircular.php"
    var leerMetodo:String="leerCircular.php"
    var selecMultiple=false
    var circularesSeleccionadas = [Int]()
    var seleccion=[Int]()
    var indices=[Int]()
    var isSearchBarEmpty: Bool {
      return searchController.searchBar.text?.isEmpty ?? true
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(_:true)
         circulares.removeAll()
          self.leerCirculares()
          /*if ConexionRed.isConnectedToNetwork() == true {
          let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
           guard let _url = URL(string: address) else { return };
           self.getDataFromURL(url: _url)
            
          }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Se muestran las últimas circulares registradas", delegate: nil, cancelButtonTitle: "Aceptar")
             alert.show()
             self.leerCirculares()
         }*/
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
        btnMarcarLeidas.isHidden=true
        btnMarcarFavoritas.isHidden=true
        btnMarcarEliminadas.isHidden=true
        lblFavoritas.isHidden=true
        lblNoLeidas.isHidden=true
        lblEliminar.isHidden=true
        btnMarcarLeidas.addTarget(self,action: #selector(leer), for: .touchUpInside)
        btnMarcarFavoritas.addTarget(self,action: #selector(agregarFavoritos), for: .touchUpInside)
        btnMarcarEliminadas.addTarget(self,action: #selector(eliminar), for: .touchUpInside)
   
        if #available(iOS 13.0, *) {
                   self.isModalInPresentation=true
               }
        
        
        tableViewCirculares.prefetchDataSource = self
        //self.title="Circulares"
        selecMultiple=false
        circularesSeleccionadas.removeAll()
        
        idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = "revealToggle:"
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        
        self.tableViewCirculares.allowsMultipleSelection = true
        self.tableViewCirculares.allowsMultipleSelectionDuringEditing = true
        
     /*
        if ConexionRed.isConnectedToNetwork() == true {
            circulares.removeAll()
            self.obtenerCirculares(limit:50)
            
            //tableViewCirculares.reloadData()
            
             
        } else {
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Se muestran las últimas circulares registradas", delegate: nil, cancelButtonTitle: "Aceptar")
            alert.show()
            self.leerCirculares()
            
        }
        */
        
      //refreshControl.attributedTitle = NSAttributedString(string: "Suelta para refrescar")
      //refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
      //self.tableViewCirculares.addSubview(refreshControl)
        
        
       
        
    }
    //Función para mantener los botones flotando
    /*func scrollViewDidScroll(_ scrollView: UIScrollView) {
        btnFavs.frame.origin.y = 300 + scrollView.contentOffset.y
        btnNoLeer.frame.origin.y = 380 + scrollView.contentOffset.y
        btnEliminar.frame.origin.y = 460 + scrollView.contentOffset.y
        btnDeshacer.frame.origin.y = 540 + scrollView.contentOffset.y
    }*/
    

   
    @objc func refresh(_ sender: AnyObject) {
      circulares.removeAll()
        print("se ha refrescado...")
      if ConexionRed.isConnectedToNetwork() == true {
         let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
          guard let _url = URL(string: address) else { return };
          self.getDataFromURL(url: _url)
          //self.leerCirculares()
      }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        var valorInicial:Int=1
        var valorFinal:Int=5
        let ultimo = circulares.count - 1
        if indexPath.row == ultimo {
            //El método debe venir con top 15
            //del registro 1 al 15
            valorFinal = valorFinal+5
          let address=self.urlBase+self.metodoCirculares+"?usuario_id=\(self.idUsuario)"
          guard let _url = URL(string: address) else { return };
          self.getDataFromURL(url: _url)
            
            print("se pasó el último registro")
            }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
   
    

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return circulares.count
    
}
    
    
   
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath)
            as! CircularTableViewCell
        //let c = circulares[indexPath.row]
        //cell.lblEncabezado.text? = ""
        
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
            }
            
        cell.btnHacerFav.addTarget(self, action: #selector(toggleFavorita), for: .touchUpInside)
        
        cell.chkSeleccionar.addTarget(self, action: #selector(seleccionMultiple), for: .touchUpInside)
       
       
        
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if(c.fecha != nil)
            //if(df.date(from: c.fecha) != nil)
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
        
        /*if(c.adjunto==1){
            cell.imgAdjunto.isHidden=false
        }
        if(c.adjunto==0){
            cell.imgAdjunto.isHidden=true
        }*/
       
       
        if(editando){
                   let isEditing: Bool = self.isEditing
                   cell.chkSeleccionar.isHidden = !isEditing
               }else{
                   let isEditing: Bool = false
                   cell.chkSeleccionar.isChecked=false
                   cell.chkSeleccionar.isHidden = !isEditing
               }
            
        }
        
        return cell
        
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
        //let leeAction = self.contextualReadAction(forRowAtIndexPath: indexPath)
        //let noleeAction = self.contextualUnreadAction(forRowAtIndexPath: indexPath)
         let masAction = self.contextualMasAction(forRowAtIndexPath: indexPath)
        let swipeConfig = UISwipeActionsConfiguration(actions: [eliminaAction,masAction])
        return swipeConfig
    }
    
    /*
     self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                                  
     self.actualizaFavoritosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
     */
    
    
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
                                                                 self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                                            self.actualizaFavoritosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                                     self.circulares.removeAll()
                                                                    self.leerCirculares()
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
                                                
                                                
                                                
                                                let actionLeer = UIAlertAction(title: "Mover a leídas", style: .default) { (action:UIAlertAction) in
                                                    
                                                    if(ConexionRed.isConnectedToNetwork()){
                                                                                                          
                                                        //capturar la celda
                                                           let cell = self.tableViewCirculares.dequeueReusableCell(withIdentifier: "celda", for: indexPath) as! CircularTableViewCell
                                                               self.leerCircular(direccion: self.urlBase+self.leerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                        
                                                        self.actualizaLeidosCirculares(idCircular: Int(idCircular)!, idUsuario: Int(self.idUsuario)!)
                                                                                                     
                                                        self.circulares.removeAll()
                                                        self.leerCirculares()
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
                                             self.circulares.removeAll()
                                             self.leerCirculares()
                                              
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
    
    
    func contextualFavAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
   
        let circular = circulares[indexPath.row]
        let action = UIContextualAction(style: .normal,
                                        title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                            let idCircular:String = "\(circular.id)"
                                            if ConexionRed.isConnectedToNetwork() == true {
                                            self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: idCircular)
                                                self.circulares.remove(at: indexPath.row)
                                                self.tableViewCirculares.reloadData()
                                            }else{
                                            var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                                            alert.show()
                                        }
                                            
                                            
            
        }
        // 7
        action.image = UIImage(named: "fav32")
        action.backgroundColor = UIColor.orange
        
        return action
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
                                          self.circulares.remove(at: indexPath.row)
                                          self.tableViewCirculares.reloadData()
                                            
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
    
    
    
    func contextualUnreadAction(forRowAtIndexPath indexPath: IndexPath) -> UIContextualAction {
              // 1
              let circular = circulares[indexPath.row]
              // 2
              let action = UIContextualAction(style: .normal,
                                              title: "") { (contextAction: UIContextualAction, sourceView: UIView, completionHandler: (Bool) -> Void) in
                                                   let idCircular:String = "\(circular.id)"
                                               if ConexionRed.isConnectedToNetwork() == true {
                                               self.noleerCircular(direccion: self.urlBase+self.noleerMetodo, usuario_id: self.idUsuario, circular_id: idCircular)
                                                   self.viewDidLoad()
                                                   self.viewWillAppear(true)
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
    
    
        
    func borraCirculares(idCircular:Int,idUsuario:Int){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
            
            //La base de datos abrió correctamente
            var statement:OpaquePointer?
            
             //Vaciar la tabla
            
            
            let query = "UPDATE appCircularCHMD SET eliminada=1,leida=0,favorita=0 WHERE idCircular=? AND idUsuario=?"
            
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (revealViewController().frontViewPosition == FrontViewPosition.right){
             self.revealViewController()?.revealToggle(animated: true)
        }
        //Con esto se evita indexOutOfRangeException
              
                
        if(editando == false){
            if (indexPath.item >= 0 || indexPath.item < circulares.count) {
        guard let c = circulares[safe: indexPath.row] else{
            return
        }
        let cell = tableView.cellForRow(at: indexPath)
            cell?.selectionStyle = .none
            UserDefaults.standard.set(indexPath.row,forKey:"posicion")
            UserDefaults.standard.set(c.id,forKey:"id")
            UserDefaults.standard.set(c.nombre,forKey:"nombre")
            UserDefaults.standard.set(c.fecha,forKey:"fecha")
            UserDefaults.standard.set(c.contenido,forKey:"contenido")
            UserDefaults.standard.set(c.fechaIcs,forKey:"fechaIcs")
            UserDefaults.standard.set(c.horaInicialIcs,forKey:"horaInicialIcs")
            UserDefaults.standard.set(c.horaFinalIcs,forKey:"horaFinalIcs")
            UserDefaults.standard.set(c.nivel,forKey:"nivel")
            UserDefaults.standard.set(0, forKey: "viaNotif")
            UserDefaults.standard.set(3, forKey: "tipoCircular")
            UserDefaults.standard.set(1, forKey: "noLeido")
            UserDefaults.standard.set(0, forKey: "clickeado")
            performSegue(withIdentifier: "CircularNoLeidaSegue", sender:self)
            }
        }else{
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
                       FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
            
            if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
                print("error opening database")
            }
            
            /*
             idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
             */
            
               let consulta = "SELECT idCircular,nombre,textoCircular,leida,favorita,eliminada,fecha,fechaIcs,horaInicioIcs,horaFinIcs,nivel,especiales  FROM appCircularCHMD WHERE leida=0 AND eliminada=0 AND tipo=1  ORDER BY idCircular DESC"
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
                   
                   
                  var especiales:String="";
                  if  let es = sqlite3_column_text(queryStatement, 11) {
                      especiales = String(cString: es)
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
                              
                             }
                           var noLeida:Int = 0
                  
                  var nl:Int=0
                         
                          if(Int(leida) == 1){
                             imagen = UIImage.init(named: "circle_white")!
                              nl=0
                          }else{
                              imagen = UIImage.init(named: "circle")!
                              nl=1
                          }
                  
                  
                  
                  
                          
                   var fechaCircular="";
                   if let fecha = sqlite3_column_text(queryStatement, 6) {
                       fechaCircular = String(cString: fecha)
                      
                      } else {
                       print("name not found")
                   }
                    
                    
                    
                   
                    self.circulares.append(CircularCompleta(id:Int(id),imagen: imagen,encabezado: "",nombre: titulo,fecha: fechaCircular,estado: 0,contenido:cont.replacingOccurrences(of: "&#92", with: ""),adjunto:Int(adj),fechaIcs:fechaIcs,horaInicialIcs: hIniIcs,horaFinalIcs: hFinIcs, nivel:nivel,leido:Int(leida),favorita: Int(favorita),espec:especiales,noLeido:nl,grados: "",adm: "",grupos: "",rts: "",enviaTodos: ""))
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
    func limpiarCirculares(){
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
               
               if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
                   print("Error en la base de datos")
               }else{
                        var statement:OpaquePointer?
                let query = "DELETE FROM appCircular";
                if sqlite3_prepare(db,query,-1,&statement,nil) != SQLITE_OK {
                    print("Error")
                }
                if sqlite3_step(statement) == SQLITE_DONE {
                    print("Tabla borrada")
                }
                
                
        }
    }
    
    func borrarCirculares(){
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1c.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }else{
        let q = "DELETE FROM appCircularCHMD"
            var statement:OpaquePointer?
        if sqlite3_prepare(db,q,-1,&statement,nil) != SQLITE_OK {
            print("Error")
        }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                           print("Tabla borrada correctamente")
                       }else{
                           print("No se pudo borrar")
                       }
        
        }
        
    }
    
    
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
    
    
    
   
    
    
    func getDataFromURL(url: URL) {
        print("get data")
        print(url)
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
                    
                    var grupos:String?=""
                    if (obj["grupos"] == nil){
                        grupos=""
                    }else{
                        grupos=obj["grupos"] as? String
                    }
                    
                    var adm:String?=""
                    if (obj["adm"] == nil){
                        adm=""
                    }else{
                        adm=obj["adm"] as? String
                    }
                    
                    var rts:String?=""
                    if (obj["rts"] == nil){
                        rts=""
                    }else{
                        adm=obj["rts"] as? String
                    }
                    
                    
                    
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
                       if(Int(favorito)==0 && Int(leido)==0){
                        self.circulares.append(CircularCompleta(id:Int(id)!,imagen: imagen,encabezado: "",nombre: titulo,fecha: fecha,estado: 0,contenido:"",adjunto:adj,fechaIcs: fechaIcs,horaInicialIcs: horaInicioIcs,horaFinalIcs: horaFinIcs, nivel:nv ?? "",leido:0,favorita:Int(favorito)!,espec:esp!,noLeido:1,
                                                                grados: grados!,adm: adm!,grupos: grupos!,rts: rts!,enviaTodos: enviaTodos!))
                       }
                    
                   
                    
                    
                }
                OperationQueue.main.addOperation {
                    self.tableViewCirculares.reloadData();
                }
            }else{
                print(error.debugDescription)
                print(error?.localizedDescription)
            }
            
            
            }.resume()
        
        /*if self.refreshControl.isRefreshing {
          self.refreshControl.endRefreshing()
        }*/
    }
    
    
    
     @objc func seleccionMultiple(_ sender:UIButton){
        var superView = sender.superview
        
        while !(superView is UITableViewCell) {
            superView = superView?.superview
        }
        let cell = superView as! CircularTableViewCell
        if let indexpath = tableViewCirculares.indexPath(for: cell){
            if(cell.chkSeleccionar.isChecked){
                indices.append(indexpath.row)
                //footerView.isHidden=false;
                //let c = tableViewCirculares.cellForRow(at: indexpath) as! CircularTableViewCell
                btnMarcarLeidas.isHidden=false
                btnMarcarFavoritas.isHidden=false
                btnMarcarEliminadas.isHidden=false
                lblFavoritas.isHidden=false
                lblNoLeidas.isHidden=false
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
               let c = circulares[indexpath.row]
                //print("No Seleccionado: \(c.id)")
                let itemEliminar = c.id
                let selecEliminar = indexpath.row
                while circularesSeleccionadas.contains(itemEliminar) {
                    if let indice = circularesSeleccionadas.firstIndex(of: itemEliminar) {
                        let index = seleccion.firstIndex(of: selecEliminar) ?? 0
                        circularesSeleccionadas.remove(at: indice)
                        indices.remove(at: indice)
                        seleccion.remove(at: index)
                    }
                }
                
                if(circularesSeleccionadas.count<=0){
                      /*btnFavs.isHidden=true
                      btnNoLeer.isHidden=true
                      btnEliminar.isHidden=true
                      btnDeshacer.isHidden=true*/
                    btnMarcarLeidas.isHidden=true
                    btnMarcarFavoritas.isHidden=true
                    btnMarcarEliminadas.isHidden=true
                    lblFavoritas.isHidden=true
                    lblNoLeidas.isHidden=true
                    lblEliminar.isHidden=true
                    tableViewCirculares.allowsSelection = false
                }
                         
              
                
                //print("recuento: \(circularesSeleccionadas.count)")
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
          
                let c = circulares[indexpath.row]
                let idCircular = c.id
                if ConexionRed.isConnectedToNetwork() == true {
                    /*self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))*/
                    self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: String(idCircular))
                        //self.viewDidLoad()
                        //self.viewWillAppear(true)
                    
                    self.actualizaFavoritosCirculares(idCircular: Int(idCircular), idUsuario: Int(self.idUsuario)!)
                    self.circulares.removeAll()
                    self.leerCirculares()
                    
                    }else{
                    var alert = UIAlertView(title: "No está conectado a Internet", message: "Para ejecutar esta acción debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
                    alert.show()
                }
            
            
            }else{
            
        }
        
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
      
      @objc func deshacer(){
      
      }
      
    
    @objc func eliminar(){
            
              if ConexionRed.isConnectedToNetwork() == true {
                  //
                         for c in circularesSeleccionadas{
                           self.delCircularTodas(direccion: self.urlBase+"eliminarCircular.php", usuario_id: self.idUsuario, circular_id: "\(c)")
                          
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
    
   
    /*
     self.favCircular(direccion: self.urlBase+"favCircular.php", usuario_id: self.idUsuario, circular_id: "\(c)")
                self.actualizaFavoritosCirculares(idCircular: c, idUsuario: Int(self.idUsuario)!)
     */
    
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
    
    
    func noleerCircular(direccion:String, usuario_id:String, circular_id:String){
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
                               //Al eliminar una circular no leída, debe bajar el num. de notificaciones
                               UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                               self.tableViewCirculares.reloadData()
                               break
                           case .failure:
                               print(Error.self)
                           }
                       }
                   
                   
                   
                   })
       
       
       let cancel = UIAlertAction(title: "Cancelar", style: .cancel) { (action) -> Void in
                      
                  }
                  
                  //Add OK and Cancel button to dialog message
                  dialogMessage.addAction(ok)
                  dialogMessage.addAction(cancel)
                  
                  // Present dialog message to user
                  self.present(dialogMessage, animated: true, completion: nil)
       
    }
    
    
    
    
    
 func delCircularTodas(direccion:String, usuario_id:String, circular_id:String){
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
    
    
    
    
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if(!(searchBar.text?.isEmpty)!){
            buscando=true
            print("Buscar")
            circulares = circulares.filter({$0.nombre.lowercased().contains(searchBar.text!.lowercased()) || $0.contenido.lowercased().contains(searchBar.text!.lowercased())})
            self.tableViewCirculares?.reloadData()
        }else{
            buscando=false
            view.endEditing(true)
            leerCirculares()
            //self.tableViewCirculares?.reloadData()
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
            circulares = circulares.filter({$0.nombre.lowercased().contains(searchBar.text!.lowercased()) || $0.contenido.lowercased().contains(searchBar.text!.lowercased())})
            leerCirculares()
            //self.tableViewCirculares?.reloadData()
            
        }
    }
    
    
    
    @IBAction func unwindCirculares(segue:UIStoryboardSegue) {}
     

    @IBAction func editar(_ sender: UIBarButtonItem) {
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
                   btnMarcarLeidas.isHidden=true
                   btnMarcarFavoritas.isHidden=true
                   btnMarcarEliminadas.isHidden=true
            
                                 lblFavoritas.isHidden=true
                                 lblNoLeidas.isHidden=true
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
                       print("Por favor instale whatsapp")
                   }
               }
           }
       }
    
    
    @objc func reaccionar()
       {
           self.viewDidLoad()
           self.viewWillAppear(true)
       }
}
