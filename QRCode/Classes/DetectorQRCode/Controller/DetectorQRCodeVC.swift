//
//  DetectorQRCodeVC.swift
//  QRCode
//
//  Created by Lenhulk on 2016/11/10.
//  Copyright © 2016年 Lenhulk. All rights reserved.
//

import UIKit

class DetectorQRCodeVC: UIViewController {
    @IBOutlet weak var sourceImageView: UIImageView!
    @IBOutlet weak var resultImageView: UIImageView!
    @IBAction func beginClick() {
        
        let context = CIContext()
        //创建二维码探测器
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh]) else {return}
        
        //探测图片特征
        guard let imageCI = CIImage(image: sourceImageView.image!) else { return }
        guard let features = detector.features(in: imageCI) as? [CIQRCodeFeature] else { return }
        
        //读取图片特征
        for feature in features{
            print(feature.messageString ?? "")
        }
        
        //给二维码绘制边框
        resultImageView.image = drawQRCodeBorder(features: features, sourceImage: sourceImageView.image!)
    }
}


extension DetectorQRCodeVC{
    /// 通过图片特征,将二维码框起来
    ///
    /// - Parameter feature: 图片特征
    /// - Returns: 新的图片
    func drawQRCodeBorder(features: [CIQRCodeFeature], sourceImage: UIImage) -> UIImage? {
        //0获取原始图片大小
        let sourceImageSize = sourceImage.size
        
        //1创建图形上下文
        UIGraphicsBeginImageContext(sourceImageSize)
        
        //2绘制原始图片
        sourceImage.draw(in: CGRect(x: 0, y: 0, width: sourceImageSize.width, height: sourceImageSize.height))
        
        //3遍历图片特征，获取frame，绘制边框
        for feature in features{
            let bounds = feature.bounds
            let newBounds = CGRect(x: bounds.origin.x, y: sourceImageSize.height - bounds.size.height - bounds.origin.y, width: bounds.size.width, height: bounds.size.height)  //bounds的原点在左下角，图形上下文的原点在左上角，修改坐标原点
            let path = UIBezierPath(rect: newBounds)
            path.lineWidth = 3
            UIColor.red.set()
            path.stroke()
        }
        //4取出绘制的图片
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        //5关闭上下文
        UIGraphicsEndImageContext()
        
        //6返回生成的图片
        return image
    }
    
    
}



