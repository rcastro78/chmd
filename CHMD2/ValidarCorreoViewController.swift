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
    @IBOutlet weak var lblMensaje: UILabel!
    @IBOutlet weak var btnContinuar: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        email = UserDefaults.standard.string(forKey: "email") ?? ""
        let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/validarEmail.php?correo=\(self.email)"
        let _url = URL(string: address)!
        validarEmail(url: _url)
        btnContinuar.isHidden=false
        
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
                       UserDefaults.standard.set(existe, forKey: "valida")
               
                    
               }
               
               }.resume()
             
           //if (valida==1){
           //TODO: Cuando pase a produccion
          
           
           return valida
           
       }
       
    
    
    override func viewDidAppear(_ animated: Bool) {
        print(email)
        let existe:String = UserDefaults.standard.string(forKey: "valida") ?? "0"
        let manzana:Int = UserDefaults.standard.integer(forKey: "manzana") ?? 0
        let valida = Int(existe) ?? 0
        if(valida==0){
            self.lblMensaje.text="La cuenta no es válida"
            self.btnContinuar.setTitle("Salir", for: .normal)
          
        }
        if(valida==1 || manzana==1){
            self.lblMensaje.text="La cuenta es válida"
            //self.btnContinuar.setTitle("Continuar", for: .normal)
            //self.btnContinuar.visiblity(gone: true, dimension: 0)
            performSegue(withIdentifier: "validarSegue", sender: self)
        }
        
        
        
       /* if(ConexionRed.isConnectedToNetwork()){
            let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/validarEmail.php?correo=\(self.email)"
            let _url = URL(string: address)!
            if(validarEmail(url: _url)==1){
                 print("Cuenta valida!")
                self.lblMensaje.text="Cuenta de correo validada..."
                return
            }else{
                self.lblMensaje.text="La cuenta de correo no es válida"
                btnContinuar.isHidden=true
                    let dialogMessage = UIAlertController(title: "CHMD", message: "Esta cuenta de correo no está registrada en nuestra base de datos.", preferredStyle: .alert)
                                                    
                                                    // Create OK button with action handler
                                                    let ok = UIAlertAction(title: "Aceptar", style: .default, handler: { (action) -> Void in
                                                        //Forzar la eliminación de la cuenta utilizada
                                                       GIDSignIn.sharedInstance()?.signOut()
                                                       UserDefaults.standard.set("",forKey: "appleId")
                                                       UserDefaults.standard.set(0,forKey: "autenticado")
                                                       UserDefaults.standard.set(0,forKey: "cuentaValida")
                                                       UserDefaults.standard.set("", forKey: "nombre")
                                                       UserDefaults.standard.set("", forKey: "email")
                                                       //Retornar al login
                                                       //self.performSegue(withIdentifier: "unwindSegueToVC1", sender: self)
                                                       
                                                    })
                                                    
                                                    //Add OK and Cancel button to dialog message
                                                    dialogMessage.addAction(ok)
                                                  
                                                    
                                                    // Present dialog message to user
                                                    self.present(dialogMessage, animated: true, completion: nil)
 
                }
            
        }else{
            var existe:String = UserDefaults.standard.string(forKey: "valida") ?? "0"
            let valida = Int(existe) ?? 0
            if(valida==1){
                self.btnContinuar.isHidden=false
            }else{
                self.btnContinuar.isHidden=true
            }
                
           
            
        }
        
            
  */
    }
        
     
    @IBAction func continuar(_ sender: UIButton) {
        performSegue(withIdentifier: "validarSegue", sender: self)
        
    }
    
    
   
    
    
    
    

}
