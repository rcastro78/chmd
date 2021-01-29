//
//  MiMaguenViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 7/6/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import WebKit
class MiMaguenViewController: UIViewController,WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
         
        if(ConexionRed.isConnectedToNetwork()){
            let url=URL(string: "https://www.chmd.edu.mx/pruebascd/icloud/")
            let req = URLRequest(url: url!)
            webView.load(req)
        }else{
            var alert = UIAlertView(title: "No está conectado a Internet", message: "Para acceder al sitio debes tener una conexión activa a la red", delegate: nil, cancelButtonTitle: "Aceptar")
            alert.show()
        }
        
            

        
        
        
    }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "Version/8.0.2 Safari/600.2.5"
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
