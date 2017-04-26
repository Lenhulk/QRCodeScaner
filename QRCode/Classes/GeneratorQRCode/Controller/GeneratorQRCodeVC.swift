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
        
        //2生成二维码
        qrcodeImageV.image = QRCodeTool.generatorQRCode(contentStr: contentStr, bigImageViewWH: qrcodeImageV.bounds.size.width, smallImage: UIImage.init(named: "erha")!, smallImageSize: 60)
    }
    
    //TODO: -保存图片到相册
}
