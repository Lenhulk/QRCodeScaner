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
        //2判断是否正在扫描(防止重复创建)
        if session!.isRunning {
            return
        }
        //3开始扫描
        session!.startRunning()
    }
}


/// AVCaptureMetadataOutputObjectsDelegate
extension ScanQRCodeVC: AVCaptureMetadataOutputObjectsDelegate{
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        print("扫描到了")
    }
}
















