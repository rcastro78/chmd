//
//  CircularesLeidasTableViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/26/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import Alamofire
class CircularesLeidasTableViewController: UITableViewController {

    @IBOutlet var tableCirculares: UITableView!
     var circulares = [Circular]()
    override func viewDidLoad() {
        super.viewDidLoad()
        let idUsuario:String = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        circulares.removeAll()
        

        if(ConexionRed.isConnectedToNetwork()){
            let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/getCircularesLeidas.php?usuario_id=\(idUsuario)"
              obtenerCirculares(uri:address)
        }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Se muestran las últimas circulares registradas", delegate: nil, cancelButtonTitle: "Aceptar")
                       alert.show()
        }
        
       
    
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return circulares.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "celda", for: indexPath)
            as! CircularLeidaTableViewCell
        let c = circulares[indexPath.row]
         //cell.lblEncabezado.text? = "Circular No. \(c.id)"
               cell.lblEncabezado.text? = ""
        cell.lblTitulo.text? = c.nombre
        cell.lblFecha.text? = c.fecha

        return cell

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
                        
                        
                        self.circulares.append(Circular(id:Int(id)!,encabezado: "",nombre: titulo,fecha: fecha,contenido:""))
                        
                        
                    }
                    
                    self.tableCirculares.reloadData()
                }
                
                
        }
                
        }
    
    
    
    

    func getDataFromURL(url: URL) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                if(!(datos.isEmpty ?? false)){
                    for index in 0...((datos).count ?? 0) - 1
                    {
                        let obj = datos[index] as! [String : AnyObject]
                        let id = obj["id"] as! String
                        let titulo = obj["titulo"] as! String
                        let fecha = obj["updated_at"] as! String
                        
                        
                        self.circulares.append(Circular(id:Int(id)!,encabezado: "",nombre: titulo,fecha: fecha,contenido:""))
                        
                    }
                }
                
                OperationQueue.main.addOperation {
                    self.tableCirculares.reloadData()
                }
            }
            
            }.resume()
        
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let c = circulares[indexPath.row]
        
        UserDefaults.standard.set(c.id,forKey:"id")
        UserDefaults.standard.set(c.nombre,forKey:"nombre")
        UserDefaults.standard.set(0, forKey: "viaNotif")
        performSegue(withIdentifier: "LcircularSegue", sender:self)
        
    }
    
}
