//
//  CredencialViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 10/15/19.
//  Copyright © 2019 Rafael David Castro Luna. All rights reserved.
//

import UIKit
import Alamofire
import RijndaelSwift
import SDWebImage

class CredencialViewController: UIViewController {

    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var imgFotoPadre: UIImageView!
    
    @IBOutlet weak var lblNombre: UILabel!
    @IBOutlet weak var lblResponsable: UILabel!
    @IBOutlet weak var lblVigencia: UILabel!
    @IBOutlet weak var qrImage: UIImageView!
    @IBOutlet weak var imgFirma: UIImageView!
    @IBOutlet weak var lblFamilia: UILabel!
    
    var urlFotos:String = "http://chmd.chmd.edu.mx:65083/CREDENCIALES/padres/"
    var urlFirma:String = "https://www.chmd.edu.mx/imagenesapp/img/firma.jpg"
    var urlNuevaFoto:String = "https://www.chmd.edu.mx/WebAdminCirculares/ws/credenciales/"
    var activityIndicator = UIActivityIndicatorView()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progress.visibility = UIView.Visibility.invisible
        
        
        self.activityIndicator = UIActivityIndicatorView(style: .gray)
            self.activityIndicator.frame = CGRect(x: 0, y: 0, width: 46, height: 46)
            self.activityIndicator.hidesWhenStopped = true

            view.addSubview(self.activityIndicator)
        
        self.activityIndicator.startAnimating()
      
        var nombre = UserDefaults.standard.string(forKey: "nombreUsuario") ?? ""
        var responsable = UserDefaults.standard.string(forKey: "responsable") ?? ""
        var familia = UserDefaults.standard.string(forKey: "familia") ?? ""
        var vigencia = UserDefaults.standard.string(forKey: "vigencia") ?? ""
        var fotoUrl = UserDefaults.standard.string(forKey: "fotoUrl") ?? ""
        var cifrado = UserDefaults.standard.string(forKey: "cifrado") ?? ""
        var nfamilia = UserDefaults.standard.string(forKey: "numeroUsuario") ?? "0"
        
        let idUsuario:String = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        lblNombre.text=nombre.lowercased().capitalized
        lblFamilia.text = "Familia: \(nfamilia)"
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
            //self.imgFotoPadre.cargar(url: imageURL!)
            //self.imgFotoPadre.transform = CGAffineTransform(rotationAngle: .pi / 2)
            
            let escala = UIScreen.main.scale
            
            let tamMiniatura = SDImageResizingTransformer(size: CGSize(width: 160, height: 160), scaleMode: .fill)
            self.qrImage.image = imagen
            let firmaURL = URL(string:self.urlFirma)
            //self.imgFirma.cargar(url:firmaURL!)
            //self.imgFotoPadre.sd_imageIndicator = SDWebImageActivityIndicator.gray
            //self.imgFotoPadre.sd_setImage(with: imageURL!, placeholderImage: nil,context: [.imageTransformer : tamMiniatura])
            
            self.imgFotoPadre.cargar(url: imageURL!)
            
            
            SDWebImageManager.shared.loadImage(
                    with:firmaURL,
                    options: .highPriority,
                    progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
                        self.imgFirma.image = image
                  }
            
            
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
                        //self.imgFotoPadre.cargar(url: imageURL)
                        self.qrImage.image = imagen
                        
                        
                        //self.qrImage.image = imagen
                        UserDefaults.standard.set(self.urlFotos+"sinfoto.png", forKey: "urlfotoQR")
                        let firmaURL = URL(string:self.urlFirma)
                        
                        self.imgFotoPadre.cargar(url: imageURL)
                        
                        
                        SDWebImageManager.shared.loadImage(
                                with:firmaURL,
                                options: .highPriority,
                                progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
                                    self.imgFirma.image = image
                              }
                        
                       
                        
                    }else{
                        //Revisar si tiene una nueva foto, si la tiene debe sustituirla
                        let imagen = self.generarQR(from: cifrado)
                        let imageURL = URL(string: fotoUrl.replacingOccurrences(of: " ", with: "%20"))
                        print("foto: \(fotoUrl)")
                        let placeholderImageURL = URL(string: self.urlFotos+"sinfoto.png")!
                        //self.imgFotoPadre.cargar(url: imageURL!)
                        
                        let escala = UIScreen.main.scale
                        let tamMiniatura = SDImageResizingTransformer(size: CGSize(width: 160, height: 160), scaleMode: .fill)
                        
                        self.imgFotoPadre.sd_imageIndicator = SDWebImageActivityIndicator.gray
                        
                        
                        self.qrImage.image = imagen
                        let firmaURL = URL(string:self.urlFirma)
                        self.imgFotoPadre.cargar(url: imageURL!)
                        
                        
                        SDWebImageManager.shared.loadImage(
                                with:firmaURL,
                                options: .highPriority,
                                progress: nil) { (image, data, error, cacheType, isFinished, imageUrl) in
                                    self.imgFirma.image = image
                              }
                        
                        
                        
                    }

                }
             }else{
                let imagen = self.generarQR(from: fotoUrl)
                self.qrImage.image = imagen
            }
            
         
            
          }
        }
        
       
    }
    
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        ImagePickerManager().pickImage(self){ image in
            self.imgFotoPadre.image = image
            self.imgFotoPadre.transform = CGAffineTransform(rotationAngle: .pi*2)
            }
    }
    
    
    //Esta funcion redimensiona la imagen para que no se suba una foto gigante a
    //limitar su ancho máximo a 240 px
    @IBAction func uploadPicture(_ sender: UIBarButtonItem) {
        var width = self.imgFotoPadre.image!.size.width
        if(width>240){
            width = 240
        }
        var image = self.imgFotoPadre.image!.resized(withPercentage: 0.25)!.resized(toWidth: width)!
        progress.visibility = UIView.Visibility.visible
        //self.showToast(message:"Cambiando tu foto, espera por favor", font: UIFont(name:"GothamRounded-Bold",size:12.0)!)
        let idUsuario:String = UserDefaults.standard.string(forKey: "idUsuario") ?? "0"
        subirImagenServer(userId: idUsuario, img: image.fixImageOrientation()!)
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
                //self.progress.visibility = UIView.Visibility.invisible
                //self.showToast(message:"Foto de credencial actualizada correctamente", font: UIFont(name:"GothamRounded-Bold",size:12.0)!)
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
    
    

  

   


