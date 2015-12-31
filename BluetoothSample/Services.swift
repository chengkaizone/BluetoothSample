//
//  Services.swift
//  BluetoothSample
//
//  Created by joinhov on 15/12/29.
//  Copyright © 2015年 lance. All rights reserved.
//

import Foundation

struct Bluetooth {
    
    /**
     * 用于查找我们关心的服务 --- UUID都是自由设定，蓝牙的UUID也可以自由设定 --- 如果中心设备和外围设备都是手机的话，app都是同一个所以可以自己设定
     */
    //let TRANSFER_SERVICE_UUID:String = "FB694B90-F49E-4597-8306-171BBA78F846"
    static let TRANSFER_SERVICE_UUID:String = "E20A39F4-73F5-4BC4-A12F-17D1AD07A961"
    
    /**
     * 用于传输数据的特征 --- 这个特征可以自由设定，对于读取数据的方式主要取决于特征的 properties 属性
     * 主要有两种，直接读取和订阅
     */
     //let TRANSFER_CHARACTERISTIC_UUID:String = "EB6727C4-F184-497A-A656-76B0CDAC633A"
    static let TRANSFER_CHARACTERISTIC_UUID:String = "08590F7E-DB05-467E-8757-72F6FAEB13D4"
    
    /// 缓冲大小
    static let BUFFER_SIZE = 128
    
    /// 协议消息的前后缀，用于判断消息首尾
    static let MSG_SUBFIX = "!~fw~!"
    
}
