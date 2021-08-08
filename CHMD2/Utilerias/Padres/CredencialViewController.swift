//
//  CredencialViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 10/15/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import Alamofire
//import CryptoSwift
import RijndaelSwift
class CredencialViewController: UIViewController {

    @IBOutlet weak var imgFotoPadre: UIImageView!
    
    @IBOutlet weak var lblNombre: UILabel!
    @IBOutlet weak var lblResponsable: UILabel!
    @IBOutlet weak var lblVigencia: UILabel!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var imgFirma: UIImageView!
    
    var urlFotos:String = "http://chmd.chmd.edu.mx:65083/CREDENCIALES/padres/"
    var urlFirma:String = "https://www.chmd.edu.mx/imagenesapp/img/firma.jpg"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var nombre = UserDefaults.standard.string(forKey: "nombreUsuario") ?? ""
        var responsable = UserDefaults.standard.string(forKey: "responsable") ?? ""
        var familia = UserDefaults.standard.string(forKey: "familia") ?? ""
        var vigencia = UserDefaults.standard.string(forKey: "vigencia") ?? ""
        var fotoUrl = UserDefaults.standard.string(forKey: "fotoUrl") ?? ""
        var cifrado = UserDefaults.standard.string(forKey: "cifrado") ?? ""
       
        lblNombre.text=nombre.lowercased().capitalized
        lblResponsable.text=responsable
        lblVigencia.text = "Vigente hasta: \(vigencia)"
         
        if(ConexionRed.isConnectedToNetwork()){
            let imageURL = URL(string: fotoUrl.replacingOccurrences(of: " ", with: "%20"))!
              Alamofire.request(imageURL).responseJSON {
              response in

              let status = response.response?.statusCode
                if(status!>200){
                    let imagen = self.generarQR(from: cifrado)
                    let imageURL = URL(string: self.urlFotos+"sinfoto.png")!
                    self.imgFotoPadre.cargar(url: imageURL)
                    self.qrImage.image = imagen
                    UserDefaults.standard.set(self.urlFotos+"sinfoto.png", forKey: "urlfotoQR")
                    let firmaURL = URL(string:self.urlFirma)
                    self.imgFirma.cargar(url:firmaURL!)
                }else{
                    let imagen = self.generarQR(from: cifrado)
                    let imageURL = URL(string: fotoUrl.replacingOccurrences(of: " ", with: "%20"))
                    print("foto: \(fotoUrl)")
                    let placeholderImageURL = URL(string: self.urlFotos+"sinfoto.png")!
                    self.imgFotoPadre.cargar(url: imageURL!)
                    self.qrImage.image = imagen
                    let firmaURL = URL(string:self.urlFirma)
                    self.imgFirma.cargar(url:firmaURL!)
                }

            }
         }else{
            let imagen = self.generarQR(from: fotoUrl)
            self.qrImage.image = imagen
        }
        
        
        
         /*if(ConexionRed.isConnectedToNetwork()){
            let imageURL = URL(string: fotoUrl)!
              Alamofire.request(imageURL).responseJSON {
              response in

              let status = response.response?.statusCode
                if(status!>200){
                    let imagen = self.generarQR(from: self.urlFotos+"sinfoto.png")
                    let imageURL = URL(string: self.urlFotos+"sinfoto.png")!
                    self.imgFotoPadre.sd_setImage(with: imageURL)
                    self.qrImage.image = imagen
                    UserDefaults.standard.set(self.urlFotos+"sinfoto.png", forKey: "urlfotoQR")
                }else{
                    let imagen = self.generarQR(from: fotoUrl)
                    let imageURL = URL(string: fotoUrl)!
                    let placeholderImageURL = URL(string: self.urlFotos+"sinfoto.png")!
                    self.imgFotoPadre.sd_setImage(with: imageURL,placeholderImage:UIImage.init(named: "sinfoto.png"))
                    self.qrImage.image = imagen
                }

            }
         }else{
            let imagen = self.generarQR(from: fotoUrl)
            self.qrImage.image = imagen
        }*/
        
        
       
       
    }
    
    
   
    
    func generarQR(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }

        return nil
    }
    
    
    
  

   

}
