//
//  ScanQRCodeVC.swift
//  QRCode
//
//  Created by Lenhulk on 2016/11/10.
//  Copyright © 2016年 Lenhulk. All rights reserved.
//

import UIKit
import AVFoundation

class ScanQRCodeVC: UIViewController {
    @IBOutlet weak var scanImageView: UIImageView!
    @IBOutlet weak var toTopConstraint: NSLayoutConstraint!
    
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
            
            //限定扫描区域(内部会以坐标原点在右上角设置，rectOfInterest的取值范围为0-1)
            let x = self.scanImageView.frame.origin.x / self.view.bounds.width
            let y = self.scanImageView.frame.origin.y / self.view.bounds.height
            let w = self.scanImageView.bounds.width / self.view.bounds.width
            let h = self.scanImageView.bounds.height / self.view.bounds.height
            output.rectOfInterest = CGRect(x: x, y: y, width: w, height: h)
        }
        
        return session
    }()
    
    ///创建预览图层（显示摄像头内容）
    fileprivate lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let previewLayer = AVCaptureVideoPreviewLayer(session: self.session) else {return nil}
        previewLayer.frame = self.view.bounds
        self.view.layer.insertSublayer(previewLayer, at:0)
        return previewLayer
    }()
    
    /// 实现扫描动画效果
    private func beginAnimating() {
        toTopConstraint.constant = -scanImageView.bounds.height
        view.layoutIfNeeded()
        UIView.animate(withDuration: 2, animations: {
            self.toTopConstraint.constant = self.scanImageView.bounds.height
            UIView.setAnimationRepeatCount(MAXFLOAT)
            self.view.layoutIfNeeded()
        })
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        beginAnimating()
        beginScaning()
    }
}


///扫描功能
extension ScanQRCodeVC{
    fileprivate func beginScaning() {
        //1判断会话和预览图层是否有值
        if session == nil || previewLayer == nil{
            return
        }
        //2判断是否正在扫描(防止重复点击创建会话)
        if session!.isRunning {
            return
        }
        //3开始扫描
        session!.startRunning()
    }
}


/// AVCaptureMetadataOutputObjectsDelegate
extension ScanQRCodeVC: AVCaptureMetadataOutputObjectsDelegate{
    
    /// 当扫描到结果就会来到该方法
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        //移除边框(当扫描结束后，系统会再调用一次这个方法，这个时候数组metadataObjects是空的)
        removeQRCodeBorder()
        guard let results = metadataObjects as? [AVMetadataMachineReadableCodeObject] else { return }
        for result in results{
            print(result.stringValue, result.corners)   //TODO: -二维码内容和四个角的坐标
            drawQRCodeBorder(result: result)
        }
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
















