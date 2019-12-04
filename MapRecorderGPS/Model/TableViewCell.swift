//
//  TableViewCell.swift
//  MapRecorderGPS
//
//  Created by Wolf on 04/12/2019.
//  Copyright © 2019 WolfMobileApp. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    //views
    
    @IBOutlet weak var viewDay: UILabel!
    
    @IBOutlet weak var viewDate: UILabel!
    
    @IBOutlet weak var viewTime: UILabel!
    
    @IBOutlet weak var viewDist: UILabel!
    
    @IBOutlet weak var viewSpeed: UILabel!
    
    
    
    // button open Map
    @IBAction func buttonOpenMap(_ sender: UIButton) {
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
