//
//  UIImageExt.swift
//  XJShapedButton
//
//  Created by 万旭杰 on 16/6/21.
//  Copyright © 2016年 万旭杰. All rights reserved.
//

import UIKit
import Foundation
import CoreGraphics

extension UIImage {
    
    //MARK: Get Image Info
    /**
     get color at the position  获取单个点的像素颜色
     
     - parameter pos: pos
     
     - returns: UIColor
     */
    func colorAtPoint(pos: CGPoint) -> UIColor? {
        if !CGRectContainsPoint(CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height), pos) {
            return nil
        }
        
        // Retrieving a pixel alpha value for a UIImage :
        // http://stackoverflow.com/questions/25146557/how-do-i-get-the-color-of-a-pixel-in-a-uiimage-with-swift
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    
    /**
     know self is Opaque or not   判断单个点的透明度
     
     - parameter pos: pos
     
     - returns: bool
     */
    func hasAlpha(pos: CGPoint) -> Bool {
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4 // The image is png
        
        let alpha = data[pixelInfo + 3]     // I need only this info
        
        if alpha > 0 {
            return true
        }
        else {
            return false
        }
    }
    
    /**
     the most Color  获取UIImage里主颜色
     
     - returns: UIColor
     */
    func mostColor() -> UIColor? {
        let bitmapInfo: UInt32 = CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue
        //第一步 先把图片缩小 加快计算速度. 但越小结果误差可能越大 (50x50)
        let thumbSize = CGSizeMake(10,10)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGBitmapContextCreate(nil, Int(thumbSize.width), Int(thumbSize.height), 8, Int(thumbSize.width) * 4, colorSpace, bitmapInfo)
        let drawRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height)
        CGContextDrawImage(context, drawRect, self.CGImage)
        
        //第二步 取每个点的像素值
        let data = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(context))
        if data == nil {
            return nil
        }
        
        let cls = NSCountedSet(capacity: Int(thumbSize.width * thumbSize.height))
        for i in 0..<Int(thumbSize.width) {
            for j in 0..<Int(thumbSize.height) {
                let offset = 4 * (i * j)
                let red = (data)[offset]
                let green = (data)[offset + 1]
                let blue = (data)[offset + 2]
                let alpha = (data)[offset + 3]
                let clr = [Int(red), Int(green), Int(blue), Int(alpha)]
                cls.addObject(clr)
            }
        }
        //第三步 找到出现次数最多的那个颜色
        let enumerator = cls.objectEnumerator()
        var MacColor: [Int]?
        var MaxCount: Int = 0
        var curColor: [Int]? = enumerator.nextObject() as? [Int]
        while (curColor != nil) {
            let tempCount: Int = cls.countForObject(curColor!)
            if tempCount < MaxCount {
                curColor = enumerator.nextObject() as? [Int]
                continue
            }
            MaxCount = tempCount
            MacColor = curColor
            curColor = enumerator.nextObject() as? [Int]
        }
        return UIColor(red: CGFloat(MacColor![0]) / 255.0, green: CGFloat(MacColor![1]) / 255.0, blue: CGFloat(MacColor![2]) / 255.0, alpha: CGFloat(MacColor![3]) / 255.0)
    }
    
    /**
     get piexl data
     
     - parameter context: CGContext
     
     - returns: UnsafeMutablePointer
     */
    func getDataForBitmapContext(context:CGContext) -> UnsafeMutablePointer<UInt8> {
        let piexlData = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(context))
        return piexlData
    }
    
    /**
     zoom Image 缩小图片
     
     - returns: UIImage
     */
    
    func zoomImageWithScale(scale: Int) -> UIImage? {
        let bitmapInfo: UInt32 = CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue
        let thumbSize = CGSizeMake(self.size.width / CGFloat(scale),self.size.height / CGFloat(scale))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGBitmapContextCreate(nil, Int(thumbSize.width), Int(thumbSize.height), 8, Int(thumbSize.width) * 4, colorSpace, bitmapInfo)
        let drawRect = CGRectMake(0, 0, thumbSize.width, thumbSize.height)
        CGContextDrawImage(context, drawRect, self.CGImage)
        
        if let CGImage = CGBitmapContextCreateImage(context) {
            return UIImage(CGImage: CGImage)
        } else {
            return nil
        }
    }
    
    
    /**
     know it is nil or zero or not
     
     - returns: bool
     */
    func isNil() -> Bool {
        if CGSizeEqualToSize(CGSize.zero, self.size) {
            return true
        }
        return false
    }
    
    //MARK: DrawImage
    /**
     draw pure colour image  画纯色的Image
     
     - parameter color: color
     - parameter frame: frame
     
     - returns: UIImage
     */
    func drawImageWithColor(color: UIColor, size: CGSize) -> UIImage {
        let size = size
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height))
        let endImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return endImage
    }
    
    /**
     draw Radius 给图片画角
     
     - parameter radius: radius
     - parameter size:   size
     
     - returns: UIImage
     */
    func drawRectWithRadius(radius: CGFloat, size: CGSize) -> UIImage {
        let size = size
        let rect = CGRectMake(0, 0, size.width, size.height)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .AllCorners, cornerRadii: CGSizeMake(radius, radius))
        CGContextAddPath(context, path.CGPath)
        CGContextClip(context)
        self.drawInRect(rect)
        CGContextDrawPath(context, .FillStroke)
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }
    
    /**
     draw pure colour image with corner
     
     - parameter color:  color
     - parameter radius: radius
     - parameter size:   size
     
     - returns: UIImage
     */
    func drawImageWithColorRadius(color: UIColor, radius: CGFloat, size: CGSize) -> UIImage {
        let size = size
        let rect = CGRectMake(0, 0, size.width, size.height)
        
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .AllCorners, cornerRadii: CGSizeMake(radius, radius))
        CGContextAddPath(context, path.CGPath)
        CGContextClip(context)
        CGContextDrawPath(context, .FillStroke)
        CGContextSetFillColorWithColor(context, color.CGColor)      // Fill Color
        CGContextFillRect(context, rect)
        
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }
}
