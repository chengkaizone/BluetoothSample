//
//  UIStoryboardExtension.swift
//  VivaVideo
//
//  Created by lance on 15/8/20.
//  Copyright (c) 2015年 lancey. All rights reserved.
//

import UIKit

extension UIStoryboard {
    /**
    * 从故事板中初始化布局界面
    */
    class func initFromStoryboard(clazz:AnyClass!) -> UIViewController {
        let className = NSStringFromClass(clazz);
        var arr = className.componentsSeparatedByString(".");
        let identifier:String = arr[arr.count-1] as String;
        return UIStoryboard.initFromStoryboardWithIdentifier(identifier);
    }
    
    /// 通过controller类名返回controller实例
    class func initFromStoryboardWithIdentifier(clazzName:String) -> UIViewController {
        let story:UIStoryboard=UIStoryboard(name: "Main", bundle: NSBundle.mainBundle());
        return story.instantiateViewControllerWithIdentifier(clazzName) ;
    }
    
}