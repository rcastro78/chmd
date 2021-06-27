//
//  PDFViewController.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 6/26/21.
//  Copyright © 2021 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class PDFViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let strURL=UserDefaults.standard.string(forKey:"docUrl") ?? ""
        let docUrl=URL(string:strURL)!
        
        if UIPrintInteractionController.canPrint(docUrl) {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = docUrl.lastPathComponent
                            printInfo.outputType = .general
                            let printController = UIPrintInteractionController.shared
                            printController.printInfo = printInfo
                            printController.showsNumberOfCopies = false
                            printController.printingItem = docUrl
                            printController.present(animated: true, completionHandler: nil)
        }
        
        
        // Do any additional setup after loading the view.
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
