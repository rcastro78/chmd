import UIKit
import Alamofire
import SQLite3
class MenuCircularesTableViewController: UITableViewController {

    @IBOutlet weak var lblCorreo: UILabel!
    @IBOutlet weak var lblUsuario: UILabel!
    @IBOutlet weak var lblNumFamilia: UILabel!
    var urlFotos:String = "http://chmd.chmd.edu.mx:65083/CREDENCIALES/padres/"
    var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
    var cifrarMetodo:String="cifrar.php"
    var idUsuario:String=""
    var db: OpaquePointer?
    @IBOutlet weak var imgFotoPerfil: UIImageView!
    @IBOutlet var tableViewMenu: UITableView!
     var menu = [MenuCirculares]()
    override func viewDidLoad() {
        super.viewDidLoad()

          menu.append(MenuCirculares(id: 1, nombre: "Entrada", imagen:#imageLiteral(resourceName: "appmenu03")))
          menu.append(MenuCirculares(id: 2, nombre: "Favoritos", imagen:#imageLiteral(resourceName: "appmenu06")))
          menu.append(MenuCirculares(id: 3, nombre: "No leídos", imagen:#imageLiteral(resourceName: "appmenu05")))
          menu.append(MenuCirculares(id: 4, nombre: "Papelera", imagen:#imageLiteral(resourceName: "appmenu07")))
          menu.append(MenuCirculares(id: 5, nombre: "Notificaciones", imagen:#imageLiteral(resourceName: "campana")))
          menu.append(MenuCirculares(id: 6, nombre: "Menú principal", imagen:#imageLiteral(resourceName: "appmenu09")))
        
               var nombre = UserDefaults.standard.string(forKey: "nombreUsuario") ?? ""
                var email = UserDefaults.standard.string(forKey: "email") ?? ""
               var familia = UserDefaults.standard.string(forKey: "numeroUsuario") ?? ""
               idUsuario = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        lblUsuario.text=nombre
        lblNumFamilia.text=familia
        lblCorreo.text=email
         
        var fotoUrl = UserDefaults.standard.string(forKey: "fotoUrl") ?? ""
        print("FOTO: \(fotoUrl)")
        if(ConexionRed.isConnectedToNetwork()){
            
          
            let address=self.urlBase+self.cifrarMetodo+"?idUsuario=\(self.idUsuario)"
            guard let _url = URL(string: address) else { return };
            let imageURL = URL(string: fotoUrl.replacingOccurrences(of: " ", with: "%20"))!
          
            Alamofire.request(imageURL).responseJSON {
              response in

              let status = response.response?.statusCode
                print("FOTO: \(status)")
                if(status!>200){
                    
                    //let imageURL = URL(string: self.urlFotos+"sinfoto.png")!
                    //self.imgFotoPerfil.cargar(url:imageURL)
                    let imageURL = URL(string: self.urlFotos+"sinfoto.png")!
                    self.imgFotoPerfil.cargar(url: imageURL)
                    
                    
                }else{
                    let imageURL = URL(string: fotoUrl.replacingOccurrences(of: " ", with: "%20"))
                    self.imgFotoPerfil.cargar(url: imageURL!)
                    //let placeholderImageURL = URL(string: self.urlFotos+"sinfoto.png")!
                // self.imgFotoPerfil.cargar(url:placeholderImageURL)
                }

            }
         }else{
            
        }
        
       
        _ = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        
       
        
}
    
    @objc func refresh() {
        tableView.reloadData()
        print("Recargando...")
    }
    // MARK: - Table view data source
    func contarNotificaciones()->Int32{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT count(*)  FROM appNotificacionCHMD where leida=0"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
       return total
    }
    
    //funciones de recuento de las circulares
    func contarCirculares()->Int32{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT count(*)  FROM appCircularCHMD where leida=0"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
       return total
    }
    
    
    func contarCircularesFavs()->Int32{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT count(*)  FROM appCircularCHMD where leida=0 and favorita=1"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
       return total
    }
    
    
    func contarCircularesNoLeidas()->Int32{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT count(*) FROM appCircularCHMD where leida=0 and favorita=0"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
       return total
    }
    
    
    
    func contarCircularesEliminadas()->Int32{
        print("Leer desde la base de datos local")
        var total:Int32=0
        let fileUrl = try!
                   FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1.sqlite")
        
        if sqlite3_open(fileUrl.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel,adjunto
         */
        
           let consulta = "SELECT count(*) FROM appCircularCHMD where eliminada=1"
           var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, consulta, -1, &queryStatement, nil) == SQLITE_OK {
              while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                     let id = sqlite3_column_int(queryStatement, 0)
                total = id
             }
            
        }
        
       return total
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return menu.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           let valor = menu[indexPath.row]
           
        if (valor.id==1){
            performSegue(withIdentifier: "circularesSegue", sender: self)
        }
        if (valor.id==2){
            performSegue(withIdentifier: "favSegue", sender: self)
        }
        if (valor.id==3){
            performSegue(withIdentifier: "noLeidasSegue", sender: self)
        }
        if (valor.id==4){
            performSegue(withIdentifier: "eliminadasSegue", sender: self)
        }
        if (valor.id==5){
            performSegue(withIdentifier: "notificacionSegue", sender: self)
        }
        if (valor.id==6){
              self.performSegue(withIdentifier: "unwindToPrincipal", sender: self)
        }
        
        
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath)
           as! MenuCircularTableViewCell
           let m = menu[indexPath.row]
           cell.lblMenu.text?=m.nombre
           cell.imgMenu.image=m.imagen
           cell.lblConteo.layer.cornerRadius = 14
        
        print("total entrada: \(self.contarCirculares())")
        print("total fav: \(self.contarCircularesFavs())")
        
        if(m.id==1){
            if(self.contarCirculares()>10){
                cell.lblConteo.text="10+"
            }else{
                if(self.contarCirculares()>0){
                    cell.lblConteo.text="\(self.contarCirculares())"
                }else{
                    cell.lblConteo.text=""
                    cell.lblConteo.backgroundColor = .white
                }
            }
            
            
        }
        if(m.id==2){
            
            if(self.contarCircularesFavs()>10){
                cell.lblConteo.text="10+"
            }else{
                if(self.contarCircularesFavs()>0){
                    cell.lblConteo.text="\(self.contarCircularesFavs())"
                }else{
                    cell.lblConteo.text=""
                    cell.lblConteo.backgroundColor = .white
                }
            }
            
          
            
        }
        if(m.id==3){
            if(self.contarCircularesNoLeidas()>10){
                cell.lblConteo.text="10+"
            }else{
                if(self.contarCircularesNoLeidas()>0){
                    cell.lblConteo.text="\(self.contarCircularesNoLeidas())"
                }else{
                    cell.lblConteo.text=""
                    cell.lblConteo.backgroundColor = .white
                }
            }
            
           
        }
        
        
        if(m.id==4){
            if(self.contarCircularesEliminadas()>10){
                cell.lblConteo.text="10+"
            }else{
                if(self.contarCircularesEliminadas()>0){
                    cell.lblConteo.text="\(self.contarCircularesEliminadas())"
                    cell.lblConteo.backgroundColor = .red
                }else{
                    cell.lblConteo.text=""
                    cell.lblConteo.backgroundColor = .white
                }
            }
            
           
        }
        if(m.id==5){
            if(self.contarNotificaciones()>10){
                cell.lblConteo.text="10+"
            }else{
                if(self.contarNotificaciones()>0){
                    cell.lblConteo.text="\(self.contarNotificaciones())"
                }else{
                    cell.lblConteo.text=""
                    cell.lblConteo.backgroundColor = .white
                }
            }
           
            
        }
        if(m.id==6){
            cell.lblConteo.text=""
            cell.lblConteo.backgroundColor = .white
        }
        return cell
    }
    
    
    
    
    
    

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

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

}

