//
//  PeripheralViewController.swift
//  BluetoothSample
//
//  Created by joinhov on 15/12/29.
//  Copyright © 2015年 lance. All rights reserved.
//

import UIKit
import CoreBluetooth

/// 外设服务控制
class PeripheralViewController: UIViewController, CBPeripheralManagerDelegate {
    
    var textView:UITextView!;
    // 外设管理
    var peripheralManager:CBPeripheralManager!;
    // 特征
    var transferCharacteristic:CBMutableCharacteristic!;
    var dataToSend:NSData?;
    var sendDataIndex:Int = 0; // 发送数据包的位置
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.peripheralManager = CBPeripheralManager();
        self.peripheralManager.delegate = self;
        
        /// 关联关心的服务ID
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:CBUUID(string: TRANSFER_SERVICE_UUID)]);
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.peripheralManager.stopAdvertising();
        
        super.viewWillDisappear(animated);
    }
    
    func sendData(data:NSData?) {
        NSLog("send data!", "");
        if data == nil {
            return;
        }
        
        var didSend = self.peripheralManager.updateValue("EOM".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: self.transferCharacteristic, onSubscribedCentrals: nil);
        if didSend { // 判断消息是否发送结束
            return;
        }
        
        if self.sendDataIndex >= data!.length {// 没有数据
            return;
        }
        
        didSend = true;
        while(didSend) {
            // 计算发送的数量
            var amountToSend = data!.length - self.sendDataIndex;
            
            // 最大不能超过 20字节
            if amountToSend > NOTIFY_MTU {
                amountToSend = NOTIFY_MTU;
            }
            
            // 复制我们想要的数据
            let chunk:NSData = NSData(bytes: data!.bytes + self.sendDataIndex, length: amountToSend);
            didSend = self.peripheralManager.updateValue(chunk, forCharacteristic: self.transferCharacteristic, onSubscribedCentrals: nil);
            
            if didSend == false {
                return;
            }
            
            let sendString = String(data: chunk, encoding: NSUTF8StringEncoding);
            if sendString != nil {
                NSLog("send: %@", sendString!);
            }
            
            // 正在发送,更新index
            self.sendDataIndex += amountToSend;
            
            if self.sendDataIndex >= data!.length {
                
                // 是否发送结束
                let eomSend = self.peripheralManager.updateValue("EOM".dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: self.transferCharacteristic, onSubscribedCentrals: nil);
                
                if eomSend {
                    NSLog("发送结束", "");
                }
                
                return;
            }
            
        }
        
    }
    
    /// CBPeripheralManagerDelegate 
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state != CBPeripheralManagerState.PoweredOn {
            return;
        }
        
        // 创建传输特征的UUID
        self.transferCharacteristic = CBMutableCharacteristic(type: CBUUID(string: TRANSFER_CHARACTERISTIC_UUID), properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable);
        // 创建传输服务
        let transferService = CBMutableService(type: CBUUID(string: TRANSFER_SERVICE_UUID), primary: true);
        
        // 添加传输服务
        self.peripheralManager.addService(transferService);
    }
    
    /// 接收到订阅的特征
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        
        let str = self.textView.text;
        if str == nil {
            return;
        }
        
        // 转换成发送数据
        self.dataToSend = str!.dataUsingEncoding(NSUTF8StringEncoding);
        self.sendDataIndex = 0;
        
        self.sendData(self.dataToSend);
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        
        self.sendData(self.dataToSend);
    }
    

}
