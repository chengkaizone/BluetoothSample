//
//  ViewController.swift
//  BluetoothSample
//
//  Created by joinhov on 15/12/28.
//  Copyright © 2015年 lance. All rights reserved.
//

import UIKit
import CoreBluetooth


/**
 * 中心设备与外围设备的数据通信 --- 这里的使用适合给手机设备编程。给手机类的中心使用
 */
class CentralViewController: UIViewController {
    
    @IBOutlet weak var textView:UITextView!;
    
    var centralManager:CBCentralManager!;
    // 关心的外设
    var discoveredPeripheral:CBPeripheral!;
    
    var data:NSMutableData!;// 接收到的数据
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backgroundTap = UITapGestureRecognizer(target: self, action: "backgroundTap")
        self.view.addGestureRecognizer(backgroundTap)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil);
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        self.centralManager.stopScan();
        print("Scanning Stopped");
        if self.discoveredPeripheral != nil {// 断开外设
            self.centralManager.cancelPeripheralConnection(self.discoveredPeripheral);
        }

    }
    
    func backgroundTap() {
        self.textView.resignFirstResponder()
        
    }
    
    @IBAction func resetAction() {
        
        self.textView.text = "";
        self.cleanup();
        self.startScan();
    }
    
    // 开始浏览
    func startScan() {
        
        let serviceUUID = CBUUID(string: Bluetooth.TRANSFER_SERVICE_UUID);// 浏览能提供指定服务的外围设备
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true];
        
        self.centralManager.scanForPeripheralsWithServices([serviceUUID], options: options);
        
        print("Scanning started");
    }
    
    //
    func cleanup() {
        if self.discoveredPeripheral == nil {
            return;
        }
        
        if self.discoveredPeripheral.state == .Disconnected {
            return;
        }
        
        if self.discoveredPeripheral.services != nil {
            
            for service in self.discoveredPeripheral.services! {
                
                //if service.UUID.isEqual(CBUUID(string: TRANSFER_SERVICE_UUID)) {
                if service.characteristics != nil {
                    
                    for characteristic in service.characteristics! {
                        if characteristic.UUID.isEqual(CBUUID(string: Bluetooth.TRANSFER_CHARACTERISTIC_UUID)) {
                            if characteristic.isNotifying {// 如果处于订阅中，取消订阅
                                self.discoveredPeripheral.setNotifyValue(false, forCharacteristic: characteristic);
                            }
                            //break;
                        }
                    }
                }
                //break;
                //}
                
            }
            
            // 断开蓝牙连接
            self.centralManager.cancelPeripheralConnection(self.discoveredPeripheral);
        }
    }
    
}

extension CentralViewController:CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        if central.state != CBCentralManagerState.PoweredOn {
            return;
        }
        
        NSLog("PoweredOn", "");
        
        self.startScan();
    }
    
    /// 发现外设
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        // 这个信号是否过滤掉似乎不重要
        //        if RSSI.integerValue < -35 || RSSI.integerValue > -15 {
        //            return;
        //        }
        NSLog("didDiscoverPeripheral: %@   %@", peripheral, RSSI);
        
        //if self.discoveredPeripheral != peripheral {
        
        
            self.centralManager.connectPeripheral(peripheral, options: nil);
        
            self.discoveredPeripheral = peripheral;
            self.data = NSMutableData();
        //}
    }
    
    /// 连接成功！
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        NSLog("didConnectPeripheral:%@ stop scanning", peripheral);
        
        self.centralManager.stopScan();
        
        peripheral.delegate = self;
        
        peripheral.discoverServices([CBUUID(string: Bluetooth.TRANSFER_SERVICE_UUID)]);
    }
    
    // 连接失败
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("didFailToConnectPeripheral:%@", peripheral);
        
        if error != nil {
            NSLog("error: %@", error!.description);
        }
        
        self.cleanup();
    }
    
    // 断开连接
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        NSLog("didDisconnectPeripheral: %@", peripheral);
        
        self.discoveredPeripheral = nil;
    }
    
}

extension CentralViewController:CBPeripheralDelegate {
    
    /// step 1 发现外设服务
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        NSLog("didDiscoverServices: %@", peripheral);
        
        if error != nil {
            NSLog("error didDiscoverServices:%@", error!.description);
            self.cleanup();
            return;
        }
        
        if peripheral.services == nil {
            return;
        }
        
        for service in peripheral.services! {// 发现自定义特征
            peripheral.discoverCharacteristics([CBUUID(string: Bluetooth.TRANSFER_CHARACTERISTIC_UUID)], forService: service);
        }
        
    }
    
    /// step 2 发现指定蓝牙服务的特征
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        NSLog("didDiscoverCharacteristicsForService: %@", peripheral);
        
        if error != nil {
            NSLog("error didDiscoverCharacteristicsForService: %@", error!.description);
            self.cleanup();
            return;
        }
        
        if service.characteristics == nil {
            return;
        }
        
        for characteristic in service.characteristics! {
            
            if characteristic.UUID.isEqual(CBUUID(string: Bluetooth.TRANSFER_CHARACTERISTIC_UUID)) {/// 开始监听
                peripheral.setNotifyValue(true, forCharacteristic: characteristic);
            }
        }
    }
    
    /// step 3 通知取消订阅，执行断开
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        NSLog("didUpdateNotificationStateForCharacteristic: %@", peripheral);
        
        if error != nil {
            NSLog("error didUpdateNotificationStateForCharacteristic:%@", error!.description);
        }
        
        if characteristic.UUID.isEqual(CBUUID(string: Bluetooth.TRANSFER_CHARACTERISTIC_UUID)) == false {
            return;
        }
        
        if characteristic.isNotifying {
            NSLog("Notification began on %@", characteristic);
        }else{// 通知断开
            NSLog("Notification stoped on %@  Disconnecting", characteristic);
            self.centralManager.cancelPeripheralConnection(peripheral);
        }
        
    }
    
    /// step 4 当有数据返回时回调该函数 --- 在这里读取数据
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        NSLog("didUpdateValueForCharacteristic: %@", peripheral);
        
        if error != nil {
            NSLog("error didUpdateValueForCharacteristic:%@", error!.description);
            return;
        }
        
        if characteristic.value == nil {
            return;
        }
        
        let data = characteristic.value!;
        
        if data.length == Bluetooth.BUFFER_SIZE {// 等于这个长度代表数据没有接收完
            self.data.appendData(data);
            print("data \(data.length) appending!");
            
            return;
        }
        
        let str = NSString(data: data, encoding: NSUTF8StringEncoding);
        
        if str != Bluetooth.MSG_SUBFIX {
            self.data.appendData(data);
        }else if self.data.length == 0 {
            peripheral.setNotifyValue(false, forCharacteristic: characteristic);
            return;
        }
        
        print("data \(self.data.length) end.");
        
        do {
            
            let object = try NSPropertyListSerialization.propertyListWithData(self.data, options: NSPropertyListReadOptions.Immutable, format: nil);
            let results = object as? [String:AnyObject];// 我们协议只传字符串可以提高效率
            
            if results != nil {// 取出协议传输的数据
                let msg = results!["msg"] as? String;
                // 实际上是可以传递图片数据的，但是效率慢
                // let data = results!["image"] as? NSData;
                NSLog("接收到的数据: %@", msg!);
                self.textView.text = msg;
            }
            
            peripheral.setNotifyValue(false, forCharacteristic: characteristic);
            
            self.cleanup();
        }catch let error as NSError {
            NSLog("error: %@", error.description);
        }
    }

}


