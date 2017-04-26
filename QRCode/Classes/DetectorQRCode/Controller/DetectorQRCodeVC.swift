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
        
        resultImageView.image =  QRCodeTool.detectorQRCode(sourceImage: sourceImageView.image!)
        
        // TODO: -给原图加边框, 文本框显示读取到的二维码内容

    }
}







