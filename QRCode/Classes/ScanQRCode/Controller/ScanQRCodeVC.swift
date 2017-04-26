//
//  ScanQRCodeVC.swift
//  QRCode
//
//  Created by Lenhulk on 2016/11/10.
//  Copyright © 2016年 Lenhulk. All rights reserved.
//

import UIKit


class ScanQRCodeVC: UIViewController {
    
    @IBOutlet weak var scanImageView: UIImageView!
    @IBOutlet weak var toTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var scanView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //设置弹框
        SVProgressHUD.setDefaultStyle(SVProgressHUDStyle.dark)
        SVProgressHUD.setOffsetFromCenter(UIOffsetMake(0, 250))
        SVProgressHUD.showInfo(withStatus: "点击屏幕开始扫描!")
        //设置手电
        let sw = UISwitch()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sw)
        sw.addTarget(self, action: #selector(swChange), for: .valueChanged)
    }
    
    //打开手电
    func swChange(sw: UISwitch) {
        QRCodeTool.turnLight(isOn: sw.isOn)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        beginAnimating()
        beginScaning()
    }
    
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
    
    
}

///扫描功能
extension ScanQRCodeVC{
    fileprivate func beginScaning() {
        QRCodeTool.shareInstance.scanQRCode(scanView: scanView, preView: view, resultBlock:{ (resultStr: String) -> () in
            SVProgressHUD.showInfo(withStatus: "扫描到了:\(resultStr)")
            
        })

    }
}


















