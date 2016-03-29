//
//  regVoiceViewController.swift
//  LOCK ME
//
//  Created by 马家固 on 16/2/26.
//  Copyright © 2016年 马家固. All rights reserved.
//

import UIKit

class regVoiceViewController: UIViewController, IFlyISVDelegate {
    
    var fixCodeArray : [String]?  //固定密码数组
    var isvRec = IFlyISVRecognizer()
    let authID = tempUserName
    let ivppwdt : Int = 1 //声纹密码类型
    var isStart = true   //判断是否正在录音

    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var voiceImage: UIImageView!
    @IBOutlet weak var resultTitle: UILabel!
    @IBOutlet weak var speechButton: UIButton!
    @IBAction func startOrStop(sender: UIButton) {
        if(isStart) {
            speechButton.setTitle("停止录音", forState: UIControlState.Normal)
            isStart = !isStart
            isvRec.startListening()
        }
        else{
            speechButton.setTitle("开始录音", forState: UIControlState.Normal)
            isStart = !isStart
            isvRec.stopListening()
        }
    }
    
    func onResult(dic: [NSObject : AnyObject]!) {
        let dictionary = dic as NSDictionary
        if(dictionary["sst"]?.isEqualToString("train") != nil) {
            let suc = dictionary.objectForKey("suc") as! NSNumber
            let rgn = dictionary.objectForKey("rgn") as! NSNumber
            print("RGN value:\(rgn.intValue)")
            
            self.resultTitle.text = "\(suc.intValue)"
            
            if(suc.intValue >= rgn.intValue) {
                var alert : UIAlertController!
                let redoAction = UIAlertAction(title: "确认", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    
                    self.isvRec.cancel()
                    if(self.registerUser(tempUserName, password: tempPassword)) {
                        self.clearAllNotice()
                        self.performSegueWithIdentifier("regSuccess", sender: self)
                    }
                    else{
                        self.clearAllNotice()
                        self.errorNotice("注册失败", autoClear: true)
                    }
                })
                
                alert = UIAlertController(title: "训练模型成功", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(redoAction)
                
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    //错误处理
    func onError(errorCode: IFlySpeechError!) {
        if(errorCode.errorCode() != 0) {
            self.resultTitle.text = "错误码：\(errorCode.errorCode())"
        }
    }
    
    //正在识别
    func onRecognition() {
        print("正在识别")
    }
    
    //音量发生变化
    func onVolumeChanged(volume: Int32) {
        self.voiceImageChangeWithVolume(Int(volume))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isvRec = IFlyISVRecognizer.sharedInstance()
        isvRec.delegate = self
        
        if(self.codeLabel.text == "获取密码失败") {
            showAlert("获取密码失败", setMessage: "请检查网络设置")
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    //显示提示
    func showAlert(setTitle:String, setMessage: String) {
        
        var alert : UIAlertController!
        let redoAction = UIAlertAction(title: "确认", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert = UIAlertController(title: setTitle, message: setMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(redoAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //下载密码
    func downloadPassword(pwdtParam: Int32) -> [AnyObject]! {
        if(pwdtParam != 1 && pwdtParam != 3){
            print("参数错误")
            return nil
            
        }
        let tmpArray = isvRec.getPasswordList(pwdtParam)
        if(tmpArray == nil){
            print("请求数据有误")
            return nil
        }
        return tmpArray
    }
    
    //训练或者验证固定密码
    func trainFixedCode(sst: String) {
        if(sst != VERIFY_SST && sst != TRAIN_SST) {
            print("sst 参数错误")
        }
        let a : Int32 = 1
        fixCodeArray = self.downloadPassword(a) as! [String]?
        
        if(fixCodeArray == nil){
            print("获取密码失败")
            return
        }
        else {
            if(fixCodeArray != nil){
                print(fixCodeArray)
            }
        }
    }
    
    //设置参数
    func defaultSetparam(auth_id: String,pwdt: Int,ptxt: String,sst: String) {
        isvRec.setParameter("ivp", forKey: KEY_SUB)
        isvRec.setParameter("\(pwdt)", forKey: KEY_PWDT)
        isvRec.setParameter("50", forKey: KEY_TSD)
        isvRec.setParameter("3000", forKey: KEY_VADTIMEOUT)
        isvRec.setParameter("700", forKey: KEY_TAIL)
        isvRec.setParameter(ptxt, forKey: KEY_PTXT)
        isvRec.setParameter(auth_id, forKey: KEY_AUTHID)
        isvRec.setParameter(sst, forKey: KEY_SST)
        isvRec.setParameter("180000", forKey: KEY_KEYTIMEOUT)
        if(pwdt == PWDT_FIXED_CODE) {
            isvRec.setParameter("5", forKey: KEY_RGN)
        } else {
            isvRec.setParameter("1", forKey: KEY_RGN)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.codeLabel.text = "等待，正在获取密码"
        self.voiceImage.image = UIImage(named: "recordNormal")
        
        trainFixedCode(TRAIN_SST)
        if(self.fixCodeArray != nil) {
            let ptString = self.fixCodeArray![0]
            defaultSetparam(authID, pwdt: PWDT_FIXED_CODE, ptxt: ptString, sst: TRAIN_SST)
            self.codeLabel.text = ptString
        }
        else{
            self.codeLabel.text = "获取密码失败"
        }
    }
    
    //刷新识别图案
    func voiceImageChangeWithVolume(volume: Int) {
        let index : Int = (volume+1)/8
        if(index == 0) {
            self.freshImgwithName("record1")
        }else if(index == 1) {
            self.freshImgwithName("record2")
        }else if(index == 2) {
            self.freshImgwithName("record3")
        }else if(index == 3) {
            self.freshImgwithName("record4")
        }
    }
    
    //刷新图案方法
    func freshImgwithName(name: String) {
        self.voiceImage.image = UIImage(named: name)
    }
    
    //声纹识别成功，为当前用户注册
    func registerUser(userName: String, password: String) -> Bool {
        self.pleaseWait()
        
        self.navigationController?.title = "正在注册"
        
        let user = AVObject(className: "lockMeUser")
        user["userName"] = userName
        user["password"] = password
        
        user.saveInBackgroundWithBlock { (succeed, e) -> Void in
            return succeed
        }
        return false
    }
}
