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

    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var imgFotoPadre: UIImageView!
    
    @IBOutlet weak var lblNombre: UILabel!
    @IBOutlet weak var lblResponsable: UILabel!
    @IBOutlet weak var lblVigencia: UILabel!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var imgFirma: UIImageView!
    
    var urlFotos:String = "http://chmd.chmd.edu.mx:65083/CREDENCIALES/padres/"
    var urlFirma:String = "https://www.chmd.edu.mx/imagenesapp/img/firma.jpg"
    var urlNuevaFoto:String = "https://www.chmd.edu.mx/WebAdminCirculares/ws/credenciales/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progress.visibility = UIView.Visibility.invisible
        var nombre = UserDefaults.standard.string(forKey: "nombreUsuario") ?? ""
        var responsable = UserDefaults.standard.string(forKey: "responsable") ?? ""
        var familia = UserDefaults.standard.string(forKey: "familia") ?? ""
        var vigencia = UserDefaults.standard.string(forKey: "vigencia") ?? ""
        var fotoUrl = UserDefaults.standard.string(forKey: "fotoUrl") ?? ""
        var cifrado = UserDefaults.standard.string(forKey: "cifrado") ?? ""
        let idUsuario:String = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        lblNombre.text=nombre.lowercased().capitalized
        lblResponsable.text=responsable
        lblVigencia.text = "Vigente hasta: \(vigencia)"
        let nuevaFoto:String = urlNuevaFoto+idUsuario+".jpg"
        
        let imageURL2 = URL(string: nuevaFoto.replacingOccurrences(of: " ", with: "%20"))!
        //Revisar si ha cambiado su foto
        Alamofire.request(imageURL2).responseJSON {
        response in

        let status = response.response?.statusCode
          print("status: \(status)")
          if(status==200){
            //Tiene nueva foto
            
            let imagen = self.generarQR(from: cifrado)
            let imageURL = URL(string: nuevaFoto.replacingOccurrences(of: " ", with: "%20"))
            print("foto: \(nuevaFoto)")
            self.imgFotoPadre.cargar(url: imageURL!)
            self.qrImage.image = imagen
            let firmaURL = URL(string:self.urlFirma)
            self.imgFirma.cargar(url:firmaURL!)
            
          }else{
            //Ver si tiene foto en carnet
            
            if(ConexionRed.isConnectedToNetwork()){
                let imageURL = URL(string: fotoUrl.replacingOccurrences(of: " ", with: "%20"))!
                  Alamofire.request(imageURL).responseJSON {
                  response in

                  let status = response.response?.statusCode
                    print("status: \(status)")
                    if(status!>200){
                        let imagen = self.generarQR(from: cifrado)
                        let imageURL = URL(string: self.urlFotos+"sinfoto.png")!
                        self.imgFotoPadre.cargar(url: imageURL)
                        self.qrImage.image = imagen
                        UserDefaults.standard.set(self.urlFotos+"sinfoto.png", forKey: "urlfotoQR")
                        let firmaURL = URL(string:self.urlFirma)
                        self.imgFirma.cargar(url:firmaURL!)
                    }else{
                        //Revisar si tiene una nueva foto, si la tiene debe sustituirla
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
            
            //carnet
          }
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
    
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        ImagePickerManager().pickImage(self){ image in
            self.imgFotoPadre.image = image
            }
    }
    
    @IBAction func uploadPicture(_ sender: UIBarButtonItem) {
        var image = self.imgFotoPadre.image
        progress.visibility = UIView.Visibility.visible
        self.showToast(message:"Cambiando tu foto, espera por favor", font: UIFont(name:"GothamRounded-Bold",size:12.0)!)
        let idUsuario:String = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        subirImagenServer(userId: idUsuario, img: image!)
    }
    
    func subirImagenServer(userId:String,img:UIImage){
        let filename = userId + ".jpg"
        let boundary = UUID().uuidString
        let fieldName = "usuario_id"
        let fieldValue = userId
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        var urlRequest = URLRequest(url: URL(string: "https://www.chmd.edu.mx/WebAdminCirculares/ws/actualizaFoto.php")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var data = Data()
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(fieldValue)".data(using: .utf8)!)
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(img.pngData()!)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
            
            
            
            
            if(error != nil){
                print("\(error!.localizedDescription)")
            }
            
            guard let responseData = responseData else {
                print("no response data")
                return
            }
            
            if let responseString = String(data: responseData, encoding: .utf8) {
                self.progress.visibility = UIView.Visibility.invisible
                self.showToast(message:"Foto de credencial actualizada correctamente", font: UIFont(name:"GothamRounded-Bold",size:12.0)!)
                print("uploaded to: \(responseString)")
            }
        }).resume()
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
    
    

  

   


