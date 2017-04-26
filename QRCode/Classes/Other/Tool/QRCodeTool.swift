//
//  QRCodeTool.swift
//  QRCode
//
//  Created by Lenhulk on 2016/11/13.
//  Copyright © 2016年 Lenhulk. All rights reserved.
//

import UIKit
import AVFoundation

class QRCodeTool: NSObject {
// MARK: - 生成二维码
    /// -----生成二维码方法
    ///
    /// - Parameters:
    ///   - contentStr: 需要生成二维码的内容
    ///   - bigImageViewWH: 生成的二维码宽高
    ///   - smallImage: 要作为头像的图片
    ///   - smallImageSize: 头像图片的宽高
    /// - Returns: 返回自定义的UIImage图片
    class func generatorQRCode(contentStr: String, bigImageViewWH: CGFloat, smallImage: UIImage, smallImageSize: CGFloat) -> UIImage? {
        
        //2生成一个二维码滤镜(不同的字符串生成不同的滤镜)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setDefaults()    // 恢复滤镜设置（因为其他滤镜会记录默认设置）
        
        //3设置二维码内容（设置的方式：KVC，设置的内容类型：NSData）
        let data = contentStr.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        // 纠错率key : inputCorrectionLevel value : L: 7% M(默认): 15% Q: 25% H: 30%
        filter.setValue("H", forKeyPath: "inputCorrectionLevel")
        
        //4从二维码滤镜中获取生成的二维码(CIImage类型)
        guard let outputImage = filter.outputImage else { return nil }
        
        //5展示二维码图片
        //        let imageUI = UIImage(ciImage: outputImage)
        guard let imageUI = createClearImage(image: outputImage, size: bigImageViewWH) else { return nil }
        
        //6设置二维码(在二维码转为清晰后设置)
        guard let colorFilter = CIFilter(name: "CIFalseColor") else { return nil }
        colorFilter.setDefaults()
        let imageCI = CIImage(image: imageUI)
        colorFilter.setValue(imageCI, forKeyPath: "inputImage") //图片
        colorFilter.setValue(CIColor(color: UIColor.black), forKeyPath: "inputColor0")   //二维码颜色
        colorFilter.setValue(CIColor(color: UIColor.white), forKeyPath: "inputColor1")  //背景颜色
        guard let colorOutputImageCI = colorFilter.outputImage else { return nil }
        
        //普通二维码
        //        qrcodeImageV.image = UIImage(ciImage: colorOutputImageCI)
        
        //自定义二维码
        let colorOutputImageUI = UIImage(ciImage: colorOutputImageCI)
        return createCustomImage(bigImage: colorOutputImageUI, smallImage: smallImage, smallImageWH: smallImageSize)
    }
    
// MARK: - 识别二维码
    /// -----识别二维码方法
    ///
    /// - Parameter sourceImage: 要识别的图片
    /// - Returns: 返回已识别的图片
    class func detectorQRCode(sourceImage: UIImage) -> UIImage? {
        //创建上下文
        let context = CIContext()
        
        //创建二维码探测器
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh]) else { return nil}
        
        //探测图片特征
        guard let imageCI = CIImage(image: sourceImage) else { return nil }
        guard let features = detector.features(in: imageCI) as? [CIQRCodeFeature] else { return nil}
        
        //读取图片特征
        for feature in features{ print(feature.messageString ?? "") }
        
        //绘制二维码边框
        return drawQRCodeBorder(features: features, sourceImage: sourceImage)
    }
    
// MARK: - 扫描二维码
    /// -----扫描二维码方法
    
    static let shareInstance = QRCodeTool()
    
    ///懒加载创建会话并且添加输入输出对象(优化)
    fileprivate lazy var session: AVCaptureSession? = {
        //1获取摄像头设备
        guard let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return nil }
        
        //2将摄像头设为输入对象
        var input : AVCaptureDeviceInput?
        do{
            input = try AVCaptureDeviceInput(device: captureDevice)
        } catch{
            print(error)
            return nil
        }
        
        //3创建输出对象
        let output = AVCaptureMetadataOutput()
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        //4创建捕捉会话
        let session = AVCaptureSession()
        
        //5添加输入对象和输出对象到会话中
        if session.canAddInput(input!) && session.canAddOutput(output){
            session.addInput(input!)
            session.addOutput(output)
            
            //必须在添加了输出对象之后制定扫描的码制类型
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
        }
        
        return session
    }()
    
    ///创建预览图层（显示摄像头内容）
    fileprivate lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: self.session) else {return nil}
        return previewLayer
    }()
    
    //定义闭包
    typealias ScanResultBlock = (_ resultString: String) -> ()
    var scanResultBlock: ScanResultBlock?
    
    /// 扫描二维码方法
    ///
    /// - Parameters:
    ///   - scanView: 扫描窗口
    ///   - preView: 预览图层
    ///   - resultBlock: 返回结果
    func scanQRCode(scanView: UIView, preView: UIView, resultBlock: @escaping ScanResultBlock) -> () {
        
        //0记录block
        self.scanResultBlock = resultBlock
        
        //1判断会话和预览图层是否有值
        if session == nil || previewLayer == nil{
            return
        }
        
        if let subLayers = preView.layer.sublayers {
            let isHavePreviewLayer = subLayers.contains(previewLayer!)
            if !isHavePreviewLayer{
                preView.layer.insertSublayer(previewLayer!, at:0)
                previewLayer?.frame = preView.bounds
            }
            
            guard let output = session!.outputs.first as? AVCaptureMetadataOutput else { return }
            //限定扫描区域(内部会以坐标原点在右上角设置，rectOfInterest的取值范围为0-1)
            let x = scanView.frame.origin.x / preView.bounds.width
            let y = scanView.frame.origin.y / preView.bounds.height
            let w = scanView.bounds.width / preView.bounds.width
            let h = scanView.bounds.height / preView.bounds.height
            output.rectOfInterest = CGRect(x: x, y: y, width: w, height: h)
        }
        
        //2判断是否正在扫描(防止重复点击创建会话)
        if session!.isRunning {
            return
        }
        
        //3开始扫描
        session!.startRunning()
    }
    
    ///-----控制手电筒方法
    class func turnLight(isOn: Bool){
        //1 获取摄像头
        guard let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return }
        
        //2 获取设备的控制权
        do{
            try captureDevice.lockForConfiguration()
        } catch{
            print(error)
            return
        }
        if isOn {  // 打开手电筒
            captureDevice.torchMode = .on
        } else {  // 关闭手电筒
            captureDevice.torchMode = .off
        }
        //3 释放设备的控制权
        captureDevice.unlockForConfiguration()
    }
    
}


/// AVCaptureMetadataOutputObjectsDelegate
extension QRCodeTool: AVCaptureMetadataOutputObjectsDelegate{
    
    /// 当扫描到结果就会来到该方法
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        //移除边框(当扫描结束后，系统会再调用一次这个方法，这个时候数组metadataObjects是空的)
        removeQRCodeBorder()
        
        //只扫描一个结果
        guard let result = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        scanResultBlock!(result.stringValue)
        
        //扫描多个结果
//        guard let result = metadataObjects as? [AVMetadataMachineReadableCodeObject] else { return }
//        for result in results{
            //            print(result.stringValue, result.corners)   //TODO: -二维码内容和四个角的坐标
//            drawQRCodeBorder(result: result)
//            SVProgressHUD.showInfo(withStatus: "扫描到了:\(result.stringValue)")
//        }
    }
    
    
    /// 绘制二维码边框
    private func drawQRCodeBorder(result: AVMetadataMachineReadableCodeObject){
        
        //result.corners是数据坐标，必须用预览图层将坐标转为上下文坐标???
        guard let resultObj = previewLayer?.transformedMetadataObject(for: result) as? AVMetadataMachineReadableCodeObject else { return }
        
        //绘制边框
        let path = UIBezierPath()
        var index = 0
        for corner in resultObj.corners{
            let dictCF = corner as! CFDictionary
            let point = CGPoint(dictionaryRepresentation: dictCF)!
            //开始绘制
            if index == 0{
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            index = index + 1
        }
        //关闭路径
        path.close()
        
        //创建形状图层
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = 3
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        previewLayer?.addSublayer(shapeLayer)
    }
    
    
    /// 移除边框
    private func removeQRCodeBorder() {
        if let layers = previewLayer?.sublayers {
            for layer in layers{
                let shapeLayer = layer as? CAShapeLayer
                if shapeLayer != nil {
                    shapeLayer?.removeFromSuperlayer()
                }
            }
        }
    }
}

//识别二维码
extension QRCodeTool{
    /// 通过图片特征,将二维码框起来
    ///
    /// - Parameter feature: 图片特征
    /// - Returns: 新的图片
    fileprivate class func drawQRCodeBorder(features: [CIQRCodeFeature], sourceImage: UIImage) -> UIImage? {
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

//生成二维码
extension QRCodeTool {
    
    /// 创建自定义清晰二维码
    ///
    /// - Parameters:
    ///   - bigImage: 原始的二维码图片
    ///   - smallImage: 头像的小图片
    ///   - smallImageWH: 小图片宽高
    /// - Returns: 生成的自定义的清晰二维码图片
    fileprivate class func createCustomImage(bigImage: UIImage, smallImage: UIImage, smallImageWH: CGFloat) -> UIImage? {
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
    fileprivate class func createClearImage(image: CIImage, size: CGFloat) -> UIImage? {
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
