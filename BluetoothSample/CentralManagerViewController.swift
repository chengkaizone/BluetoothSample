//
//  ViewController.swift
//  BluetoothSample
//
//  Created by joinhov on 15/12/28.
//  Copyright © 2015年 lance. All rights reserved.
//

import UIKit
import CoreBluetooth

class CentralManagerViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager:CBCentralManager!;
    var discoveredPeripheral:CBPeripheral!;
    
    var textView:UITextView!;
    
    var receiveData:NSMutableData?;// 接收到的数据

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.centralManager = CBCentralManager();
        self.centralManager.delegate = self;
        
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        self.centralManager.stopScan();
        
        NSLog("停止浏览", "");
    }

    /// CBCentralManagerDelegate
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        if central.state != CBCentralManagerState.PoweredOn {
            return;
        }
        
        self.centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true]);
        
        NSLog("开始浏览", "");
    }
    
    func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
        
    }
    
    /// 发现外设
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        NSLog("发现: %@   %@", peripheral.name as String!, RSSI);
        
        if self.discoveredPeripheral != peripheral {
            self.discoveredPeripheral = peripheral;
            
            NSLog("Connecting to peripheral: %@", peripheral);// 开始执行连接
            self.centralManager.connectPeripheral(peripheral, options: nil);
        }
    }
    
    /// 连接成功！
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        NSLog("Connected!", "");
        
        self.centralManager.stopScan();
        
        self.receiveData?.length = 0;
        
        peripheral.delegate = self;
        
        peripheral.discoverServices([CBUUID(string: TRANSFER_SERVICE_UUID)]);
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("连接失败！", "");
        
        self.cleanup();
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("didDisconnectPeripheral: %@", peripheral.name!);
        self.discoveredPeripheral = nil;
        
        self.centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true]);
    }
    
    func cleanup() {
        NSLog("cleanup!", "");
        
        if self.discoveredPeripheral.services != nil {
            
            for service in self.discoveredPeripheral.services! {
                
                if service.characteristics != nil {
                    for characteristic in service.characteristics! {
                        if characteristic.UUID == CBUUID(string: TRANSFER_SERVICE_UUID) {
                            if characteristic.isNotifying {
                                self.discoveredPeripheral.setNotifyValue(false, forCharacteristic: characteristic);
                            }
                        }
                    }
                }
            }
        }
        
        self.centralManager.cancelPeripheralConnection(self.discoveredPeripheral);
    }
    
    /// CBPeripheralDelegate
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        NSLog("didDiscoverServices: %@", peripheral.name!);
        
        if error != nil || peripheral.services == nil {
            self.cleanup();
            return;
        }
        
        for service in peripheral.services! {// 发现自定义特征
            peripheral.discoverCharacteristics([CBUUID(string: TRANSFER_CHARACTERISTIC_UUID)], forService: service);
        }
        
        // other
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        NSLog("didDiscoverCharacteristicsForService: %@", peripheral.name!);
        
        if error != nil || service.characteristics == nil {
            self.cleanup();
            return;
        }
        
        for characteristic in service.characteristics! {
            
            if characteristic.UUID == CBUUID(string: TRANSFER_CHARACTERISTIC_UUID) {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic);
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        NSLog("didUpdateValueForCharacteristic: %@", peripheral.name!);
        if discoveredPeripheral?.services != nil {
            
            for service in self.discoveredPeripheral.services! {
                if service.characteristics != nil {
                    for characteristic in service.characteristics! {
                        if characteristic.UUID == CBUUID(string: TRANSFER_CHARACTERISTIC_UUID) {
                            if characteristic.isNotifying {
                                self.discoveredPeripheral.setNotifyValue(false, forCharacteristic: characteristic);
                            }
                        }
                    }
                }
                
            }
        }
        
        self.centralManager.cancelPeripheralConnection(self.discoveredPeripheral);
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        NSLog("didUpdateNotificationStateForCharacteristic: %@", peripheral.name!);
        
        if characteristic.UUID != CBUUID(string: TRANSFER_CHARACTERISTIC_UUID) {
            
            return;
        }
        
        if characteristic.isNotifying {
            NSLog("Notification began on %@", characteristic);
        }else{// 取消外设连接
            self.centralManager.cancelPeripheralConnection(peripheral);
        }
        
    }

}

