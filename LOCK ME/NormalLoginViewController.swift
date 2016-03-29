//
//  LoginViewController.swift
//  LOCK ME
//
//  Created by 马家固 on 16/2/22.
//  Copyright © 2016年 马家固. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import MobileCoreServices

class NormalLoginViewController: UIViewController, IFlyISVDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var recorder : AVAudioRecorder!
    
    var fixCodeArray : [String]?  //固定密码数组
    var isvRec = IFlyISVRecognizer()
    let authID = tempUserName
    let ivppwdt : Int = 1 //声纹密码类型
    
    //CoreData对象
    var users = [NSManagedObject]()
    
    var alert: UIAlertController!
    
    @IBOutlet weak var longPressInfo: UILabel!
    @IBOutlet weak var voiceButton: UIButton!
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBAction func login(sender: UIButton) {
        //首先验证用户名与密码
        if(userName.text == nil || password.text == nil) {
            self.errorNotice("请输入完整信息", autoClear: true)
        }
        else{
            self.pleaseWait()
            let user = AVObject(className: "lockMeUser")
            //把输入的文本框的值，设置到对象中
            user["userName"] = userName.text
            user["password"] = password.text
            
            //查询用户名是否已注册
            let query1 = AVQuery(className: "lockMeUser")
            query1.whereKey("userName", equalTo: userName.text)
            
            //执行查询，是否有此用户名
            query1.getFirstObjectInBackgroundWithBlock({ (objects, e) -> Void in
                if objects != nil {
                    //检查密码是否正确
                    query1.findObjectsInBackgroundWithBlock({ (anyobjects:[AnyObject]!, e:NSError!) -> Void in
                        let queryData = anyobjects[0]["localData"] as! NSDictionary
                        let queryPass = queryData["password"] as! String
                        
                        if(self.password.text == queryPass){
                            //选择识别方式
                            self.chooseRecognitionMethod("身份认证", message: "请选择")
                        }
                        //密码不正确
                        else{
                            self.clearAllNotice()
                            let redoAction = UIAlertAction(title: "确认", style: UIAlertActionStyle.Cancel, handler: nil)
                            self.alert = UIAlertController(title: "认证失败", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                            self.alert.addAction(redoAction)
                            self.presentViewController(self.alert, animated: true, completion: nil)
                        }
                    })
                }
                else{
                    self.clearAllNotice()
                    self.errorNotice("无此用户名", autoClear: true)
                }
            })
        }
    }
    
    @IBAction func voiceLongPress(sender: AnyObject) {
        if(sender.state == UIGestureRecognizerState.Began) {
            self.recorder.record()
            isvRec.startListening()
        }
        if(sender.state == UIGestureRecognizerState.Ended) {
            self.recorder.stop()
            isvRec.stopListening()
            self.infoNotice("正在识别")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupRecorder()
        
        let waver : Waver = Waver(frame: CGRectMake(0,CGRectGetHeight(self.view.bounds)-50,CGRectGetWidth(self.view.bounds),43))
        let _weakRecorder = self.recorder
        
        waver.waverLevelCallback = { (waver : Waver!) in
            _weakRecorder.updateMeters()
            
            let normalizedValue : CGFloat = pow(10, CGFloat(_weakRecorder.averagePowerForChannel(0)/Float(40)))
            
            waver.level = normalizedValue
        }
        
        self.view.addSubview(waver)
        
        isvRec = IFlyISVRecognizer.sharedInstance()
        isvRec.delegate = self
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.userName.resignFirstResponder()
        self.password.resignFirstResponder()
    }
    
    func onResult(dic: [NSObject : AnyObject]!) {
        self.clearAllNotice()
        let dictionary = dic as NSDictionary
        if(dictionary["sst"]?.isEqualToString(VERIFY_SST) != nil) {
            if((dictionary[DCS]?.isEqualToString(SUCCESS)) != nil){
                self.successNotice("验证成功", autoClear: true)
                self.performSegueWithIdentifier("loginSuccess", sender: self)
            }
            else{
                self.errorNotice("验证失败", autoClear: true)
                self.chooseRecognitionMethod("认证失败", message: "请重新选择认证方式")
            }
        }
    }
    
    func onError(errorCode: IFlySpeechError!) {
        self.clearAllNotice()
        if(errorCode.errorCode() != 0) {
            self.errorNotice("错误码：\(errorCode.errorCode())", autoClear: true)
            self.chooseRecognitionMethod("认证失败", message: "请重新选择认证方式")
        }
    }
    
    func onRecognition() {
        print("正在认证中")
    }
    
    func onVolumeChanged(volume: Int32) {
        print(volume)
    }
    
    //选择身份认证方式
    func chooseRecognitionMethod(title: String, message: String) {
        let useFaceAction = UIAlertAction(title: "人脸识别", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            //是否支持相机
            if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self
                imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
                self.presentViewController(imagePickerController, animated: true, completion: nil)
            } else {
                self.errorNotice("不支持相机", autoClear: true)
            }
        })
        
        let useVoiceAction = UIAlertAction(title: "声纹识别", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
            
            self.readyVoiceRecognition()
        })
        self.alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
        self.alert.addAction(useFaceAction)
        self.alert.addAction(useVoiceAction)
        
        self.presentViewController(self.alert, animated: true, completion: nil)
    }
    
    //准备进行声纹识别
    func readyVoiceRecognition() {
        verifyFixedCode(VERIFY_SST)
        if(self.fixCodeArray != nil) {
            let ptString = self.fixCodeArray![0]
            defaultSetparam(self.userName.text!, pwdt: PWDT_FIXED_CODE, ptxt: ptString, sst: VERIFY_SST)
            print(ptString)
            
            self.successNotice("请朗读密码", autoClear: true)
            voiceButton.alpha = 1
            voiceButton.enabled = true
            longPressInfo.alpha = 1
        }
        else{
            self.errorNotice("获取密码失败", autoClear: true)
        }
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
    
    //验证固定密码
    func verifyFixedCode(sst: String) {
        if(sst != VERIFY_SST) {
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
    
    //Waver设置
    func setupRecorder() {
        let url : NSURL = NSURL(fileURLWithPath: "/dev/null")
        
        let settings : Dictionary = [AVSampleRateKey : 44100.0 , AVFormatIDKey : NSNumber(unsignedInt: kAudioFormatAppleLossless) , AVNumberOfChannelsKey : NSNumber(integer: 2) , AVEncoderAudioQualityKey : NSNumber(integer: AVAudioQuality.Min.rawValue)]
        
        do {
            self.recorder = try AVAudioRecorder(URL: url, settings: settings)
        } catch {
            print("recorder error")
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch {
            print("session error")
        }
        
        self.recorder.prepareToRecord()
        self.recorder.meteringEnabled = true
    }
    
    func scaleImage(image: UIImage) -> UIImage {
        //先获取图片的高和宽
        let width = image.size.width
        let height = image.size.height
        
        if(height < 450 && width < 450) {
            return image
        }
        else{
            //缩小的尺寸
            let size = CGSizeMake(width*(450/height), 450)
            UIGraphicsBeginImageContext(size)
            image.drawInRect(CGRectMake(0, 0, size.width, size.height))
            let scaledImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return scaledImage
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var img = info[UIImagePickerControllerOriginalImage] as! UIImage
        img = self.scaleImage(img)
        
        //进行人脸识别
        picker.dismissViewControllerAnimated(true) { () -> Void in
            self.pleaseWait()
            
            let faceId = getFace_id(img)
            if(verifyFace(faceId, personName: self.userName.text!)) {
                self.clearAllNotice()
                self.successNotice("认证成功", autoClear: true)
                //认证成功
                self.performSegueWithIdentifier("loginSuccess", sender: self)
            } else {
                self.clearAllNotice()
                self.chooseRecognitionMethod("认证失败", message: "请重新选择认证方式")
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        //设置录音按钮
        voiceButton.setBackgroundImage(UIImage(named: "unSelectMicro"), forState: UIControlState.Normal)
        voiceButton.setBackgroundImage(UIImage(named: "SelectMicro"), forState: UIControlState.Highlighted)
        voiceButton.alpha = 0
        voiceButton.enabled = false
        longPressInfo.alpha = 0
        
        let manager : AFNetworkReachabilityManager = AFNetworkReachabilityManager.sharedManager()
        manager.startMonitoring()
        manager.setReachabilityStatusChangeBlock { (AFNetworkReachabilityStatus) -> Void in
            if(AFNetworkReachabilityStatus.rawValue == -1 || AFNetworkReachabilityStatus.rawValue == 0){
                self.clearAllNotice()
                self.errorNotice("网络未连接", autoClear: true)
                networkConnect = false
            }
            else{
                print("网络连接")
                networkConnect = true
            }
        }
    }
}
