//
//  PeripheralViewController.swift
//  BluetoothSample
//
//  Created by joinhov on 15/12/29.
//  Copyright © 2015年 lance. All rights reserved.
//

import UIKit
import CoreBluetooth


/**
 * 外设与中心的数据通信 --- 这里的使用适合给蓝牙外设终端编程。给外设安装使用
 * 程序供外设使用
 * 使用peripheral编程的例子也有很多，比如像用一个ipad和一个iphone通讯，ipad可以认为是central，iphone端是peripheral,这种情况下适合本示例。
 */
class PeripheralViewController: UIViewController, UIAlertViewDelegate {
    
    @IBOutlet weak var textView:UITextView!;
    @IBOutlet weak var btSend:UIButton!;
    
    // 外设管理
    var peripheralManager:CBPeripheralManager!;
    // 传输特征
    var transferCharacteristic:CBMutableCharacteristic!;
    // 传输服务
    var transferService:CBMutableService!;
    
    var data:NSData!;// 发送的数据
    var sendOffset = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundTap = UITapGestureRecognizer(target: self, action: "backgroundTap");
        self.view.addGestureRecognizer(backgroundTap);
        
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil);
        
        switch CBPeripheralManager.authorizationStatus() {
        case .Authorized:
            break;
        case .Denied:
            UIAlertView(title: "蓝牙状态", message: "你的蓝牙处于未授权状态", delegate: self, cancelButtonTitle: "好", otherButtonTitles: "开启蓝牙").show();
            break;
        case .NotDetermined:
            break;
        case .Restricted:
            break;
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated);
        
        self.peripheralManager.stopAdvertising();
    }
    
    func backgroundTap() {
        self.textView.resignFirstResponder()
    }
    
    @IBAction func sendAction(sender:UIButton) {
        let sendStr = self.textView.text;
        
        if sendStr == nil {
            return;
        }
        
        //sender.enabled = false;
        self.btSend.setTitle("Sending...", forState: .Normal);
        
        self.peripheralManager.stopAdvertising();// 先停止广播
        
        self.data = nil;
        self.sendOffset = 0;
        
        var sendContent = [String:AnyObject]();
        sendContent["msg"] = sendStr!;
        // 不建议通过蓝牙传输图片数据 --- 效率不高
        // sendContent["image"] = UIImagePNGRepresentation(UIImage());
        // 组合数据
        self.data = try? NSPropertyListSerialization.dataWithPropertyList(sendContent, format: NSPropertyListFormat.BinaryFormat_v1_0, options: 0);
        
        // 执行广播 --- 这里千万注意CBUUID是一个数组,传递CBUUID没有编译错误，但是发不出消息
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[CBUUID(string: Bluetooth.TRANSFER_SERVICE_UUID)]]);
        
    }
    
    func resetSendButton() {
        self.btSend.setTitle("Send", forState: .Normal);
        self.btSend.enabled = true;
    }
    
    /// 发送数据出去
    func sendData() {// 此处的操作与指针有关
        let length = self.data.length;
        
        var size = Bluetooth.BUFFER_SIZE;
        
        while sendOffset < length {// 循环传递数据块
            if length - sendOffset < size {
                size = length - sendOffset;
            }
            
            // 构造数据块---传递地址，偏移量和数据长度
            let chunk = NSData(bytes: self.data.bytes + sendOffset, length: size);
            
            // 广播数据出去
            let didSend = self.peripheralManager.updateValue(chunk, forCharacteristic: self.transferCharacteristic, onSubscribedCentrals: nil);
            if didSend {
                print("data chunk sended, size: \(size), offset: \(sendOffset); totle: \(data.length)");
                self.sendOffset += size;
            }else{
                return;
            }
            
            NSLog("sending...", "");
        }
        
        if sendOffset == length && size == Bluetooth.BUFFER_SIZE {// 发送结束标志
            
            let didSend = self.peripheralManager.updateValue(Bluetooth.MSG_SUBFIX.dataUsingEncoding(NSUTF8StringEncoding)!, forCharacteristic: self.transferCharacteristic, onSubscribedCentrals: nil);
            
            if didSend {
                print("sended end");
                self.sendOffset = 0;
                self.resetSendButton();
            } else {
                print("sended end failed");
            }
        } else if sendOffset < Bluetooth.BUFFER_SIZE {
            print("sended finished.");
            self.sendOffset = 0;
            self.resetSendButton();
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        switch buttonIndex {
        case 0:
            NSLog("打开蓝牙", "");
            break;
        case 1:
            NSLog("好", "");
            break;
        default:
            break;
        }
    }
    
}

extension PeripheralViewController:CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        switch peripheral.state {
        case .Unknown:
            NSLog("蓝牙未知状态", "");
            return;
        case .Resetting:
            NSLog("蓝牙重置状态", "");
            return;
        case .Unsupported:// iOS设备都含有蓝牙
            break;
        case .Unauthorized:
            NSLog("蓝牙未授权使用", "");
            return;
        case .PoweredOn:
            NSLog("蓝牙可用状态", "");
            break;
        case .PoweredOff:
            NSLog("蓝牙处于关闭状态", "");
            return;
        }
        if peripheral.state != CBPeripheralManagerState.PoweredOn {
            return;
        }
        
        NSLog("PoweredOn", "");
        // 创建传输特征的UUID
        self.transferCharacteristic = CBMutableCharacteristic(type: CBUUID(string: Bluetooth.TRANSFER_CHARACTERISTIC_UUID), properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable);
        // 创建传输服务
        self.transferService = CBMutableService(type: CBUUID(string: Bluetooth.TRANSFER_SERVICE_UUID), primary: true);
        self.transferService.characteristics = [self.transferCharacteristic];
        
        // 添加传输服务
        self.peripheralManager.addService(self.transferService);
    }
    
    func peripheralManagerDidStartAdvertising(peripheral: CBPeripheralManager, error: NSError?) {
        if error != nil {
            NSLog("error: peripheralManagerDidStartAdvertising %@", error!.description);
            return;
        }
        
        NSLog("DidStartAdvertising：%@", "开始广播");
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        
    }
    
    /// 接收到订阅的特征
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        NSLog("Central subscribed to characteristic: %@", central.description);
        
        self.sendData();
    }
    
    /// 取消订阅
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        NSLog("Central unsubscribed from characteristic: %@", central.description);
        
    }
    
    /// ???
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        NSLog("peripheralManager Is Ready To Update Subscribers", "");
        
        self.sendData();
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveReadRequest request: CBATTRequest) {
        NSLog("didReceiveReadRequest: %@", request);
        
        let data = request.value;
        
        if data != nil {
            NSLog("receive read mesg: %@", String(data: data!, encoding: NSUTF8StringEncoding)!);
        }
        
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        NSLog("didReceiveWriteRequests: %@", requests);
        
        for request in requests {
            let data = request.value;
            
            if data != nil {
                NSLog("receive write mesg: %@", String(data: data!, encoding: NSUTF8StringEncoding)!);
            }
        }
        
    }
    
    
}






