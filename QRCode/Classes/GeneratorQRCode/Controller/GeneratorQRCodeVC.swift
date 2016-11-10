//
//  GeneratorQRCodeVC.swift
//  QRCode
//
//  Created by Lenhulk on 2016/11/10.
//  Copyright © 2016年 Lenhulk. All rights reserved.
//

import UIKit

class GeneratorQRCodeVC: UIViewController {

    @IBOutlet weak var contentTV: UITextView!
    @IBOutlet weak var qrcodeImageV: UIImageView!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //1获取文本框输入内容
        let contentStr = contentTV.text!
        if contentStr.characters.count == 0 { return }
        
        //2生成一个二维码滤镜(不同的字符串生成不同的滤镜)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return }
        filter.setDefaults()    // 恢复滤镜设置（因为其他滤镜会记录默认设置）
        
        //3设置二维码内容（设置的方式：KVC，设置的内容类型：NSData）
        let data = contentStr.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        // 纠错率key : inputCorrectionLevel value : L: 7% M(默认): 15% Q: 25% H: 30%
        filter.setValue("H", forKeyPath: "inputCorrectionLevel")
        
        //4从二维码滤镜中获取生成的二维码(CIImage类型)
        guard let outputImage = filter.outputImage else { return }
        
        //5展示二维码图片
//        let imageUI = UIImage(ciImage: outputImage)
        guard let imageUI = createClearImage(image: outputImage, size: qrcodeImageV.frame.width) else { return }
        
        //6设置二维码(在二维码转为清晰后设置)
        guard let colorFilter = CIFilter(name: "CIFalseColor") else { return }
        colorFilter.setDefaults()
        let imageCI = CIImage(image: imageUI)
        colorFilter.setValue(imageCI, forKeyPath: "inputImage") //图片
        colorFilter.setValue(CIColor(color: UIColor.black), forKeyPath: "inputColor0")   //二维码颜色
        colorFilter.setValue(CIColor(color: UIColor.white), forKeyPath: "inputColor1")  //背景颜色
        guard let colorOutputImageCI = colorFilter.outputImage else { return }
        
        //普通二维码
//        qrcodeImageV.image = UIImage(ciImage: colorOutputImageCI)
        
        //自定义二维码
        let colorOutputImageUI = UIImage(ciImage: colorOutputImageCI)
        qrcodeImageV.image = createCustomImage(bigImage: colorOutputImageUI, smallImage: UIImage.init(named: "erha")!, smallImageWH: 60)
    }
}

extension GeneratorQRCodeVC {
    
    ///创建自定义清晰二维码
    fileprivate func createCustomImage(bigImage: UIImage, smallImage: UIImage, smallImageWH: CGFloat) -> UIImage? {
        //获取大图片尺寸
        let bigImageSize = bigImage.size
        //创建图形上下文
        UIGraphicsBeginImageContext(bigImageSize)
        //绘制大小图片
        bigImage.draw(in: CGRect(x: 0, y: 0, width: bigImageSize.width, height: bigImageSize.height))
        smallImage.draw(in: CGRect(x: (bigImageSize.width - smallImageWH)*0.5, y: (bigImageSize.height - smallImageWH)*0.5, width: smallImageWH, height: smallImageWH))
        //从上下文取出图片
        let outImage = UIGraphicsGetImageFromCurrentImageContext()
        //关闭上下文
        UIGraphicsEndImageContext()
        return outImage
    }
    
    
    /// 将模糊的二维码图片转为清晰的
    /// - parameter image: 模糊的二维码图片
    /// - parameter size: 需要生成的二维码尺寸
    /// - returns: 清晰的二维码图片
    fileprivate func createClearImage(image: CIImage, size: CGFloat) -> UIImage? {
        let extent = image.extent.integral
        let scale = min(size / extent.width, size / extent.height)
        let width = extent.width * scale
        let height = extent.height * scale
        let cs = CGColorSpaceCreateDeviceGray() //创建灰度颜色通道
        let bitmapRef = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: 0)
        let context = CIContext(options: nil)
        let bitmapImage = context.createCGImage(image, from: extent)
        bitmapRef!.interpolationQuality = .none
        bitmapRef?.scaleBy(x: scale, y: scale)
        bitmapRef?.draw(bitmapImage!, in: extent)
        guard let scaledImage = bitmapRef?.makeImage() else { return nil }
        return UIImage(cgImage: scaledImage)
    }

}
