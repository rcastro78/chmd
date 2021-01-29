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

        
        
       
        
        //Bitly.initialize("9bd1d4e87ce38e38044ff0c7c60c07c90483e2a4")
        
        
        if ConexionRed.isConnectedToNetwork() == true {
            GIDSignIn.sharedInstance().clientID = "465701420614-006480utbh9mvsubvmv398qrt0hbee1i.apps.googleusercontent.com"
                       GIDSignIn.sharedInstance().delegate = self

        }else{
            
        }
        
      
        
        
        
        /*NotificationCenter.currentNotificationCenter().delegate = self
        
        let authOptions: AuthorizationOptions = [.alert, .badge, .sound]
        NotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
    } else {
    let settings: UIUserNotificationSettings =
    UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
    application.registerUserNotificationSettings(settings)
    }
    
    application.registerForRemoteNotifications()*/
        
        //UIApplication.shared.registerForRemoteNotifications()
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
        
        
        
        UINavigationBar.appearance().barTintColor = UIColor(red: 9.0/255.0, green: 143.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        
        return true
    }
    
   
        
    /*func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
            
        }
    }
    
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                [weak self] granted, error in
                
                print("Permission granted: \(granted)")
                guard granted else { return }
                self?.getNotificationSettings()
        }
    }
    
    
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
        ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }*/
    
    
    
   func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        var statement:OpaquePointer?
        let aps = userInfo[AnyHashable("aps")] as? NSDictionary
        let alert = aps?["alert"] as? NSDictionary
        let body = alert![AnyHashable("body")] as? String
        let title = alert!["title"] as? String
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
            //Con esto capturamos los valores enviados en la notificacion
            //let idCircular = userInfo["id"] as! String
        
        let aps = userInfo[AnyHashable("aps")] as? NSDictionary
               let alert = aps?["alert"] as? NSDictionary
               let body = alert![AnyHashable("body")] as? String
               let title = alert!["title"] as? String
               let b = aps![AnyHashable("badge")] as? Int

              //Mostrar el badge
              UIApplication.shared.applicationIconBadgeNumber = b!
        
            debugPrint("Notificaciones: \(userInfo)")
            UserDefaults.standard.set(1, forKey: "viaNotif")
            UserDefaults.standard.set(0, forKey: "idCircularViaNotif")
            
      
          
        let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let circulares = mainStoryboard.instantiateViewController(withIdentifier: "ViewController") as! TodasCircularesViewController
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
        print("Hex Token: \(deviceTokenString)")
        print("Device Token: \(deviceToken)")
       print("Reduced Token: \(token1)")
        
       
        
        
       //Este es el token para utilizar en las notificaciones push
        UserDefaults.standard.set(deviceTokenString, forKey: "deviceToken")
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Fallo: \(error.localizedDescription)")
    }

    
    
    
}

