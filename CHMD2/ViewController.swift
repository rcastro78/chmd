//
//  ViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/6/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//
import UIKit
import AVKit
import AVFoundation
import GoogleSignIn
import SQLite3
import AuthenticationServices


extension UIImageView {
    func cargar(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}



extension Date {

    static func -(recent: Date, previous: Date) -> (month: Int?, day: Int?, hour: Int?, minute: Int?, second: Int?) {
        let day = Calendar.current.dateComponents([.day], from: previous, to: recent).day
        let month = Calendar.current.dateComponents([.month], from: previous, to: recent).month
        let hour = Calendar.current.dateComponents([.hour], from: previous, to: recent).hour
        let minute = Calendar.current.dateComponents([.minute], from: previous, to: recent).minute
        let second = Calendar.current.dateComponents([.second], from: previous, to: recent).second

        return (month: month, day: day, hour: hour, minute: minute, second: second)
    }

}


extension ViewController: ASAuthorizationControllerDelegate {
     // ASAuthorizationControllerDelegate function for authorization failed
    @available(iOS 13.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print(error.localizedDescription)
        }


        // Authorization Succeeded
        @available(iOS 13.0, *)
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Get user data with Apple ID credentitial
                let userId = appleIDCredential.user
                let userFirstName = appleIDCredential.fullName?.givenName
                let userLastName = appleIDCredential.fullName?.familyName
                let userEmail = appleIDCredential.email
                print("User ID: \(userId)")
                print("User First Name: \(userFirstName ?? "")")
                print("User Last Name: \(userLastName ?? "")")
                print("User Email: \(userEmail ?? "")")
                
                
                let appleId = appleIDCredential.user
                let appleUserFirstName = appleIDCredential.fullName?.givenName
                _ = appleIDCredential.fullName?.familyName
                _ = appleIDCredential.email
                
                if(appleIDCredential.email! != nil){
                    UserDefaults.standard.set(appleUserFirstName!, forKey: "nombre")
                    UserDefaults.standard.set(appleId, forKey: "appleId")
                    UserDefaults.standard.set(appleIDCredential.email!, forKey: "email")
                    UserDefaults.standard.set(1,forKey: "autenticado")
                    UserDefaults.standard.set(1,forKey: "cuentaValida")
                    UserDefaults.standard.set(1,forKey: "manzana")
                    performSegue(withIdentifier: "inicioSegue", sender: self)
                }else{
                    var alert = UIAlertView(title: "Aviso", message: "Debes compartir tu dirección de correo para que podamos validar tu cuenta en nuestro sistema", delegate: nil, cancelButtonTitle: "Aceptar")
                               alert.show()
                        
                }
                //Revisar que el correo exista en el server del colegio
               
                
                
                
                
                
                // Write your code here
            } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
                // Get user data using an existing iCloud Keychain credential
                let appleUsername = passwordCredential.user
                let applePassword = passwordCredential.password
                // Write your code here
            }
        }
   
    
    
    
    
    
    
    
       // ASAuthorizationControllerDelegate function for successful authorization
  
    /*@available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
  
    if #available(iOS 13.0, *) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Create an account as per your requirement
            
            let appleId = appleIDCredential.user
            let appleUserFirstName = appleIDCredential.fullName?.givenName
            _ = appleIDCredential.fullName?.familyName
            _ = appleIDCredential.email
            
            //Revisar que el correo exista en el server del colegio
            UserDefaults.standard.set(appleUserFirstName!, forKey: "nombre")
            UserDefaults.standard.set(appleId, forKey: "appleId")
            UserDefaults.standard.set(appleIDCredential.email!, forKey: "email")
            UserDefaults.standard.set(1,forKey: "autenticado")
            UserDefaults.standard.set(1,forKey: "cuentaValida")
            UserDefaults.standard.set(1,forKey: "manzana")
            performSegue(withIdentifier: "inicioSegue", sender: self)
            
            
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            
            _ = passwordCredential.user
            _ = passwordCredential.password
            
            //Write your code
           
        }
    } else {
        // Fallback on earlier versions
    }
   }*/
}

extension ViewController:
ASAuthorizationControllerPresentationContextProviding {

    //For present window
    
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showToast(message : String, font: UIFont) {

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
    
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {  // for swift 4.2 syntax just use ===> mode: UIView.ContentMode
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}


class ViewController: UIViewController,GIDSignInUIDelegate,GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print(error)
        }
        else {
           performSegue(withIdentifier: "verificarSegue", sender: self)
        }
    }
    
    var avPlayer:AVPlayer!
    var avPlayerLayer:AVPlayerLayer!
    var paused:Bool = false
    var db: OpaquePointer?
    
    @IBOutlet weak var btnAppleLogin: UIButton!
    @IBOutlet weak var signInButton: GIDSignInButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.btnAppleLogin.isHidden=false
        }else{
          self.btnAppleLogin.isHidden=true
        }
        
        
         if ConexionRed.isConnectedToNetwork() == true {
             GIDSignIn.sharedInstance().uiDelegate = self
         }else{
            let cuentaValida:Int = UserDefaults.standard.integer(forKey: "valida")
            if(cuentaValida==1){
                print("Valida")
                self.performSegue(withIdentifier: "validarSinInternetSegue", sender: self)
            }else{
                
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
        
        /*NotificationCenter.default.addObserver(self,
                                               selector: Selector("playerItemDidReachEnd:"),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: avPlayer.currentItem)*/
        
        //Crear el archivo para la base de datos cuando
        //no haya conexión a internet
        
        //Sección para la base de datos
        let fileUrl = try!
            FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("chmd_db1b.sqlite")
        
        if(sqlite3_open(fileUrl.path, &db) != SQLITE_OK){
            print("Error en la base de datos")
        }
        
        /*
         idCircular,idUsuario,nombre,textoCircular,no_leida,leida,favorita,compartida,eliminada,created_at,fechaIcs,horaInicioIcs,horaFinIcs,nivel
         */
        
        let crearTablaCirculares = "CREATE TABLE IF NOT EXISTS appCircularCHMD(idCircular INTEGER, idUsuario INTEGER, nombre TEXT, textoCircular TEXT, no_leida INTEGER, leida INTEGER, favorita INTEGER, compartida INTEGER, eliminada INTEGER, created_at TEXT,fechaIcs TEXT, horaInicioIcs TEXT, horaFinIcs TEXT, nivel TEXT, adjunto INT,updated_at TEXT, especiales TEXT, tipo INTEGER)"
        if sqlite3_exec(db, crearTablaCirculares, nil, nil, nil) != SQLITE_OK {
            print("Error creando la tabla de las circulares")
        }else{
           print("creada la tabla de las circulares")
        }
        
        let crearTablaNotificaciones="CREATE TABLE IF NOT EXISTS appNotificacionCHMD(idCircular INTEGER, idUsuario INTEGER, nombre TEXT, textoCircular TEXT, no_leida INTEGER, leida INTEGER, favorita INTEGER, compartida INTEGER, eliminada INTEGER, created_at TEXT,fechaIcs TEXT, horaInicioIcs TEXT, horaFinIcs TEXT, nivel TEXT, adjunto INT,updated_at TEXT)"
        if sqlite3_exec(db, crearTablaNotificaciones, nil, nil, nil) != SQLITE_OK {
            print("Error creando la tabla de las notificaciones")
        }else{
           print("creada la tabla de las notificaciones")
        }
        
         //self.setupSOAppleSignIn()
        self.appleCustomLoginButton()
       
    }
    
    
    @IBAction func googleSignIn(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!){
        if (error != nil){
            let nombre:String = user.profile.givenName
            let email:String = user.profile.email
            
            print(nombre)
            print(email)
            UserDefaults.standard.set(1,forKey: "autenticado")
            UserDefaults.standard.set(nombre, forKey: "nombre")
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set(0,forKey: "manzana")
            
           
        }
    }
    
    
    func signIn(signIn: GIDSignIn!,
                presentViewController viewController: UIViewController!) {
        self.present(viewController, animated: true, completion: nil)
    
    }
    
    // Dismiss the "Sign in with Google" view
    func signIn(signIn: GIDSignIn!,
                dismissViewController viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
        UserDefaults.standard.set(1,forKey:"cuentaValida")
         
        
    }
    
    
    //funciones de Apple 08/08/2021
    @objc func actionHandleAppleSignin() {
            if #available(iOS 14.0, *) {
                let appleIDProvider = ASAuthorizationAppleIDProvider()
                let request = appleIDProvider.createRequest()
                request.requestedScopes = [.fullName, .email]
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                authorizationController.delegate = self
                authorizationController.presentationContextProvider = self
                authorizationController.performRequests()
            }
        }
    
   
    
    
    
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        let p: AVPlayerItem = notification.object as! AVPlayerItem
        p.seek(to: CMTime.zero)
    }
    
   
    
    //Esta función es para el redirect automático
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avPlayer.play()
        paused = false
        
        let cuentaValida:Int = UserDefaults.standard.integer(forKey: "cuentaValida")
        if(cuentaValida==1){
            print("Valida")
            
             if ConexionRed.isConnectedToNetwork() == true {
                
                performSegue(withIdentifier: "inicioSegue", sender: self)
             }else{
                performSegue(withIdentifier: "validarSinInternetSegue", sender: self)
            }
            
            
            //self.performSegue(withIdentifier: "validarSinInternetSegue", sender: self)
        }else{
            print("Cuenta No Valida")
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        avPlayer.pause()
        paused = true
}
    
    
    @IBAction func unwindToVC1(segue:UIStoryboardSegue) {
        
    }
    
    
    @IBAction func appleLogin(_ sender: UIButton) {
        if #available(iOS 14.0, *){
            //Esta función maneja el login via Apple
            actionHandleAppleSignin()
            
            
        }else{
            let alert = UIAlertController(title: "CHMD", message: "Esta opción sólo está disponible a partir de iOS 13", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cerrar", style: .cancel, handler: nil))

            self.present(alert, animated: true)
            
        }
        
    }
    
    

    
    func appleCustomLoginButton() {
    if #available(iOS 14.0, *) {
            let customAppleLoginBtn = UIButton()
            customAppleLoginBtn.layer.cornerRadius = 80.0
            customAppleLoginBtn.layer.borderWidth = 0.0
            customAppleLoginBtn.backgroundColor = UIColor.white
           
            customAppleLoginBtn.setTitleColor(UIColor.black, for: .normal)
            customAppleLoginBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            customAppleLoginBtn.setImage(UIImage(named: "boton_apple"), for: .normal)
            customAppleLoginBtn.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
            customAppleLoginBtn.addTarget(self, action: #selector(actionHandleAppleSignin), for: .touchUpInside)
            customAppleLoginBtn.frame = CGRect(x: 140, y: 700, width: 96, height: 96)
           
        }
        
    }
    
    
    func setupSOAppleSignIn() {
        if #available(iOS 14.0, *) {
                    let btnAuthorization = ASAuthorizationAppleIDButton()
                    btnAuthorization.frame = CGRect(x: 180, y: 20, width: 200, height: 40)
                    btnAuthorization.center = self.view.center
                    btnAuthorization.addTarget(self, action: #selector(actionHandleAppleSignin), for: .touchUpInside)
                    self.view.addSubview(btnAuthorization)
        } else {
            // Fallback on earlier versions
        }
          
    }
    
    func getCredentialState() {
        if #available(iOS 14.0, *) {
           let appleIDProvider = ASAuthorizationAppleIDProvider()
           appleIDProvider.getCredentialState(forUserID: "USER_ID") { (credentialState, error) in
               switch credentialState {
               case .authorized:
                   // Credential is valid
                   // Continiue to show 'User's Profile' Screen
                   break
               case .revoked:
                   // Credential is revoked.
                   // Show 'Sign In' Screen
                   break
               case .notFound:
                   // Credential not found.
                   // Show 'Sign In' Screen
                   break
               default:
                   break
               }
           }
            
        }
       }

    
    
    //Se ocupara solo para iOS
    func validarEmail(url:URL)->Int{
        var valida:Int=0
        //self.lblMensaje.text="Validando cuenta de correo"
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            if let datos = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [[String:Any]] {
                
                let obj = datos[0] as [String : AnyObject]
                    let existe = obj["existe"] as! String
                    print("existe: "+existe)
                    valida = Int(existe) ?? 0
                    print("valida: \(valida)")
                    UserDefaults.standard.set(existe, forKey: "valida")
                if(valida==1){
                    self.performSegue(withIdentifier:"inicio2Segue",sender:nil)
                }
                 
            }
            
            }.resume()
        
        return valida
        
    }
    
    
    
}
