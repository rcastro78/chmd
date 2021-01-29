//
//  ValidarCuentaViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 4/11/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit

import Alamofire
import Firebase
import Network
import GoogleSignIn

class ValidarCuentaViewController: UIViewController {

  var email:String=""
     var so:String=""
     var deviceToken = ""
     let v = UIView()
     @IBOutlet weak var lblMensaje: UILabel!
    @IBOutlet weak var btnContinuar:UIButton!
     override func viewDidLoad() {
         super.viewDidLoad()
         email = UserDefaults.standard.string(forKey: "email") ?? ""
         
        //let timer = Timer.scheduledTimer(timeInterval: 0.4, target: self, selector: #selector(self.reaccionar), userInfo: nil, repeats: false)
        
        
  }
    
    func finish(){
    var navigationArray = self.navigationController?.viewControllers //To get all UIViewController stack as Array
    navigationArray!.remove(at: (navigationArray?.count)! - 2) // To remove previous UIViewController
    self.navigationController?.viewControllers = navigationArray!
    }
     
     override func viewDidAppear(_ animated: Bool) {
     print(email)
             
     if(ConexionRed.isConnectedToNetwork()){
         let address="https://www.chmd.edu.mx/WebAdminCirculares/ws/validarEmail.php?correo=\(self.email)"
         let _url = URL(string: address)!
        
        print("Estado: \(validarEmail(url: _url))")
        
         if(validarEmail(url: _url)==1){
                
        }
        
     }else{
        
        }
        
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
        
        return valida
        
    }
    
    
    
    
}
