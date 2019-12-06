//
//  ViewControllerInfo.swift
//  MapRecorderGPS
//
//  Created by Wolf on 05/12/2019.
//  Copyright © 2019 WolfMobileApp. All rights reserved.
//

import UIKit

class ViewControllerSettings: UIViewController {
    
    // views
    @IBOutlet weak var viewUnits: UISegmentedControl!
    
    // user defaults
    let defaults = UserDefaults.standard
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ustawienie segmented control w zależności od userDefaults
        if defaults.bool(forKey: C.keyToSwitchUnitsOnOff) {
            viewUnits.selectedSegmentIndex = 1
        } else {
            viewUnits.selectedSegmentIndex = 0
        }
    }
    
    //button to set Units
    @IBAction func buttonUnits(_ sender: UISegmentedControl) {
        
        switch viewUnits.selectedSegmentIndex {
        case 0:
            defaults.set(false, forKey: C.keyToSwitchUnitsOnOff)
        case 1:
            defaults.set(true, forKey: C.keyToSwitchUnitsOnOff)
        default:
            print("Error segmented Selected")
        }
    }
}
