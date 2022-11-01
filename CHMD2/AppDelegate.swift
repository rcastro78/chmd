//
//  AppDelegate.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/6/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase
import  UserNotifications
import Network
import BitlySDK
import FirebaseInstanceID
import FirebaseMessaging
import SQLite3

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,MessagingDelegate,GIDSignInDelegate,UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var metodo_circular:String="getCircularId.php"
    
    var urlBase:String="https://www.chmd.edu.mx/WebAdminCirculares/ws/"
    var metodoCircularNotificada:String="getCircularId_iOS.php"
    var idUsuario:String=""
    var db: OpaquePointer?
    
    func registerForPushNotifications() {
      UNUserNotificationCenter.current() // 1
        .requestAuthorization(options: [.alert, .sound, .badge]) {
          granted, error in
          print("Permission granted: \(granted)")
            self.registerForPushNotifications()
      }
    }
    

   func getNotificationSettings() {
      UNUserNotificationCenter.current().getNotificationSettings { settings in
        print("Notification settings: \(settings)")
        guard settings.authorizationStatus == .authorized else { return }
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
        
      }
    }
    
    
    func applicationDidBecomeActive(application: UIApplication) {
         
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
       
        
         var statement:OpaquePointer?
        let sqlRecuento1 = "select count(*) from appNotificacion"
          if sqlite3_prepare(self.db, sqlRecuento1, -1, &statement, nil) == SQLITE_OK{
                while(sqlite3_step(statement) == SQLITE_ROW){
                     let count = sqlite3_column_int(statement, 0)
                     print("Notificaciones: \(count)")
                }

          }else{
            print("Notificaciones: -1")
        }

        
        
        if ConexionRed.isConnectedToNetwork() == true {
            GIDSignIn.sharedInstance().clientID = "465701420614-006480utbh9mvsubvmv398qrt0hbee1i.apps.googleusercontent.com"
                       GIDSignIn.sharedInstance().delegate = self

        }else{
            
        }
        
        UserDefaults.standard.setValue(0, forKey: "notificado")
        
        
    
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
          let settings: UIUserNotificationSettings =
          UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        
        
        
        /*UINavigationBar.appearance().barTintColor = UIColor(red: 9.0/255.0, green: 143.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]*/
        if #available(iOS 13.0, *) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        appearance.backgroundColor = UIColor(red: 9.0/255.0, green: 143.0/255.0, blue: 207.0/255.0, alpha: 1.0)
    
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().standardAppearance = appearance;
        UINavigationBar.appearance().scrollEdgeAppearance = UINavigationBar.appearance().standardAppearance
        
            
        }else{
            UINavigationBar.appearance().barTintColor = UIColor(red: 9.0/255.0, green: 143.0/255.0, blue: 207.0/255.0, alpha: 1.0)
            UINavigationBar.appearance().tintColor = UIColor.white
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        }
        
        
        
        
        return true
    }
    
  
    
func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
        let url = userActivity.webpageURL,
        let host = url.host else {
            return false
    }

    let isDynamicLinkHandled =
        DynamicLinks.dynamicLinks().handleUniversalLink(url) { [self] dynamicLink, error in

            guard error == nil,
                let dynamicLink = dynamicLink,
                let urlString = dynamicLink.url?.absoluteString else {
                    return
            }
            let idCircularViaNotif = urlString.components(separatedBy:"=")[1]
   
            UserDefaults.standard.set(1, forKey: "viaNotif")
            UserDefaults.standard.set(idCircularViaNotif, forKey: "idCircularViaNotif")
            
            
            //Hacer el insert a la base de esta circular
            let address=self.urlBase+self.metodoCircularNotificada+"?circular_id=\(idCircularViaNotif)"
            guard let _url = URL(string: address) else { return };
            getDataFromURL(url: _url){[weak self] success, int in
                guard let strongSelf = self, success else { return }
                //Todos los cambios en la UI se hacen dentro del DispatchQueue
                DispatchQueue.main.async{
                    let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let circulares = mainStoryboard.instantiateViewController(withIdentifier: "CircularDetalleNotificacionViewController") as! CircularDetalleNotificacionViewController
                    strongSelf.window?.rootViewController = circulares
                }
               
            }
            /*let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let circulares = mainStoryboard.instantiateViewController(withIdentifier: "CircularDetalleViewController") as! CircularDetalleViewController
                    self.window?.rootViewController = circulares*/
            
            
        }
    return isDynamicLinkHandled
}
    
   func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var statement:OpaquePointer?
    let aps = userInfo[AnyHashable("aps")] as? NSDictionary
        //let alert = aps?["alert"] as? NSDictionary
        let body = aps![AnyHashable("body")] as? String
        let title = aps!["title"] as? String
        let b = aps![AnyHashable("badge")] as? Int

       //Setear el badge si la app está abierta
    UIApplication.shared.applicationIconBadgeNumber = (b ?? 1)
            
       
        let state = application.applicationState
    
        switch state {
            case .background:
            print("Background")
            
          
            
        case .active:
            print("activa")
              
        case .inactive:
          print("Inactiva")
           
        @unknown default:
            print("default")
        }
        
       
        
    debugPrint("Notificaciones: \(userInfo)")
    
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            print("Se dio click a la notificacion")
            let request = response.notification.request
            let userInfo = request.content.userInfo

        
                let aps = userInfo[AnyHashable("aps")] as? NSDictionary
                let body = userInfo[("body")] as? String
                let idCircular = userInfo[("idCircular")] as? String
                let tituloNotif = userInfo[("tituloNotif")] as? String
                let contenidoNotif = userInfo[("contenidoNotif")] as? String
                let nivelNotif = userInfo[("nivelNotif")] as? String
                let fechaNotif = userInfo[("fechaNotif")] as? String
                let b = aps![AnyHashable("badge")] as? Int
             
        debugPrint("cuerpo: \(body!)")
        debugPrint("cuerpo: \(idCircular!)")
        debugPrint("cuerpo: \(b!)")
        UIApplication.shared.applicationIconBadgeNumber = b!
        
            debugPrint("userInfo: \(userInfo)")
            UserDefaults.standard.set(1, forKey: "viaNotif")
            UserDefaults.standard.set(idCircular, forKey: "idCircularViaNotif")
            UserDefaults.standard.set(tituloNotif, forKey: "tituloNotif")
            UserDefaults.standard.set(contenidoNotif, forKey: "contenidoNotif")
            UserDefaults.standard.set(nivelNotif, forKey: "nivelNotif")
            UserDefaults.standard.set(fechaNotif, forKey: "fechaNotif")
        
           //Insertar la circular que viene con este id
            
        
      
          
        let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let circulares = mainStoryboard.instantiateViewController(withIdentifier: "CircularDetalleNotificacionViewController") as! CircularDetalleNotificacionViewController
                self.window?.rootViewController = circulares

        
        
            completionHandler()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL?,
                                                 sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            print("ERROR \(error.localizedDescription)")
        } else {
            // Perform any operations on signed in user here.
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            print("TOKEN \(idToken)")
            let picURL = user.profile.imageURL(withDimension: 120) 
            
            UserDefaults.standard.set(userId,forKey:"userId")
            UserDefaults.standard.set(idToken,forKey:"idToken")
            UserDefaults.standard.set(fullName,forKey:"fullName")
            UserDefaults.standard.set(givenName,forKey:"givenName")
            UserDefaults.standard.set(familyName,forKey:"familyName")
            UserDefaults.standard.set(email,forKey:"email")
            UserDefaults.standard.set(picURL,forKey:"picURL")
            UserDefaults.standard.set(1,forKey:"cuentaValida")
            //Aquí se hará el redirect, trabaja en conjunto a la función
            //viewDidAppear del ViewController.
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let destinationViewController = storyboard.instantiateViewController(withIdentifier: "ViewController")
                as! ViewController
            let navigationController = self.window?.rootViewController as! UIViewController
            navigationController.showDetailViewController(destinationViewController, sender: Any?.self)
            
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!,
              withError error: Error!) {
       UserDefaults.standard.set(0,forKey: "autenticado")
       UserDefaults.standard.set(0,forKey: "cuentaValida")
       UserDefaults.standard.set("", forKey: "nombre")
       UserDefaults.standard.set("", forKey: "email")
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
         //application.applicationIconBadgeNumber = 0
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func application(
      _ application: UIApplication,
      didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
      let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
      let token = tokenParts.joined()
        let deviceTokenString = deviceToken.hexString
        let token1 = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
      
        
       //Este es el token para utilizar en las notificaciones push
        UserDefaults.standard.set(deviceTokenString, forKey: "deviceToken")
        print("token: \(deviceTokenString)")
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fallo: \(error.localizedDescription)")
    }

    
    
    /*
     
     
     key=AAAAbG33vkY:APA91bH5Ts7zah-Ho9TxVKcLztA2ZWKpGO-bcn0_2h4yDdLvuanTBLd-hylbLkJ6uX_7qFUSwenkp4OqW133vZc8cVcdqfY8ZgwbgbCfXKg8_VxJFYz-g_BDPDv7JyPaot4v1gI83DpA
     
     {
     "to" : "cpPQrxT9sEm5oWH-clujs6:APA91bHM2vl2IhdHoHksJnkOFN2aDQwewWFAdaHUJbzdiTdtJDMcmeFBeprfWc3rVkCVsfp64gF0drlkp309o4dJBcqt5Qrd6A9Xu4kr67c9_FFOOzX7g0Hse4v7iIko-vRClmamOODW",

     "notification" : {

         "body" : "Tienes una nueva circular sin leer!",
         "idCircular":"810",
         "content_available" : true,
         "priority" : "high",
         "viaNotificacion":"1",
         "badge":"5",
         "click_action": "ValidarPadreActivity"

     },

     "data" : {
     "body" : "Nueva circular: Tienes una nueva circular sin leer!",

     "idCircular":"810",
     "content_available" : true,
     "priority" : "high",
     "click_action": "CircularNotificacionActivity",
     "viaNotificacion":"1"
     }


     }
     
     */
    
    
    func guardarNotificaciones(idCircular:Int,idUsuario:Int,nombre:String, textoCircular:String,no_leida:Int, leida:Int,favorita:Int,compartida:Int,eliminada:Int,fecha:String,fechaIcs:String,horaInicioIcs:String,horaFinIcs:String,nivel:String,adjunto:Int,especiales:String){
        
        
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
            
            
            self.idUsuario = "\(idUsuario)"
            
            if sqlite3_bind_int(statement,2,Int32(idUsuario)) != SQLITE_OK {
              
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
        
        
        //UserDefaults.standard.set(self.notifNoLeidas, forKey: "totalNotif")
    
        
    }
    
    
    func getDataFromURL(url: URL,completion: @escaping (Bool, Int?) -> Void) {
        print("Leer desde el servidor....")
        print(url)
       
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
                        self.guardarNotificaciones(idCircular: Int(id)!, idUsuario: Int(self.idUsuario)!, nombre: titulo, textoCircular: str, no_leida: noLeida, leida: Int(leido)!, favorita: Int(favorito)!, compartida: 0, eliminada: Int(eliminada)!,fecha: fecha,fechaIcs: fechaIcs,horaInicioIcs: horaInicioIcs,horaFinIcs: horaFinIcs,nivel: nv ?? "",adjunto:adj,especiales: para)
                         
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
            
           
        
        
             
    }
    
}

