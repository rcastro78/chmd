//
//  MenuCircularTableViewCell.swift
//  CHMD2
//
//  Created by Rafael David Castro Luna on 4/7/20.
//  Copyright © 2020 Rafael David Castro Luna. All rights reserved.
//

import UIKit

class MenuCircularTableViewCell: UITableViewCell {

    @IBOutlet weak var imgMenu: UIImageView!
    @IBOutlet weak var lblMenu: UILabel!
    @IBOutlet weak var lblConteo: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
