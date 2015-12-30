//
//  MainViewController.swift
//  BluetoothSample
//
//  Created by joinhov on 15/12/28.
//  Copyright © 2015年 lance. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet var btCentral:UIButton!;
    @IBOutlet var btPeripheral:UIButton!;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // self.navigationController?.navigationBarHidden = true;
        
        self.btCentral.sizeToFit();
        self.btPeripheral.sizeToFit();
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func entryCentralAction(sender: AnyObject) {
        
        let control = UIStoryboard.initFromStoryboard(CentralViewController.classForCoder());
        self.navigationController?.pushViewController(control, animated: true);
    }
    
    @IBAction func entryPeripheralAction(sender: AnyObject) {
        
        let control = UIStoryboard.initFromStoryboard(PeripheralViewController.classForCoder());
        self.navigationController?.pushViewController(control, animated: true);
    }
}
