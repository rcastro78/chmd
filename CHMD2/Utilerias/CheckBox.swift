//
//  CheckBox.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 3/28/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit


class CheckBox: UIButton {
    // Images
    let checkedImage = UIImage(named: "check_lleno")! as UIImage
    let uncheckedImage = UIImage(named: "check_vacio")! as UIImage

    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }

    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }

    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
