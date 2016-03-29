//
//  regFaceViewController.swift
//  LOCK ME
//
//  Created by 马家固 on 16/2/26.
//  Copyright © 2016年 马家固. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import AssetsLibrary

class regFaceViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var willUploadImage = UIImage()
    
    @IBOutlet weak var showImage: UIImageView!
    @IBOutlet weak var promptInfo: UILabel!
    @IBOutlet weak var photoSelecteButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    //选取照片
    @IBAction func photoSelect(sender: UIButton) {
        //提示栏
        var sheet : UIAlertController
        
        var sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        sheet = UIAlertController(title: "选择照片", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let photoLibrary = UIAlertAction(title: "从相册选择", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            imagePickerController.sourceType = sourceType
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        }
        let camera = UIAlertAction(title: "拍照", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            sourceType = UIImagePickerControllerSourceType.Camera
            imagePickerController.sourceType = sourceType
            self.presentViewController(imagePickerController, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "退出", style: UIAlertActionStyle.Cancel, handler: nil)
        
        //是否支持使用照相机
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)){
            sheet.addAction(photoLibrary)
            sheet.addAction(camera)
            sheet.addAction(cancel)
        }
        else{
            sheet.addAction(photoLibrary)
            sheet.addAction(cancel)
        }
        
        self.presentViewController(sheet, animated: true, completion: nil)
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
        var img = info[UIImagePickerControllerEditedImage] as! UIImage
        img = self.scaleImage(img)
        willUploadImage = img
        //显示照片，并隐藏提示文字与选择照片按钮
        self.promptInfo.alpha = 0
        self.photoSelecteButton.enabled = false
        self.photoSelecteButton.alpha = 0
        
        self.showImage.alpha = 1
        self.showImage.image = img
        self.okButton.alpha = 1
        self.okButton.enabled = true
        self.redoButton.alpha = 1
        self.redoButton.enabled = true
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //上传照片
    @IBAction func uploadImage(sender: UIButton) {
        self.okButton.enabled = false
        self.redoButton.enabled = false
        
        //获取face_id
        let faceID = getFace_id(willUploadImage)
        
        //判断是否获取成功
        if(faceID == "network error"){
            showErrorAlert("网络或服务器出错", setMessage: "")
        }
        else if(faceID == "Don't detect face"){
            showErrorAlert("出错", setMessage: "未检测到人脸，请换一张照片")
        }
        else{
            //在Face++中创建用户
            let createSuccess = createPerson(tempUserName, tag: "", face_id: [faceID], groupName: ["test"])
            if(createSuccess == false){
                showErrorAlert("网络或服务器出错", setMessage: "")
            }
            //创建成功
            else{
                let trainSuccess = train_verify(tempUserName)
                if(trainSuccess == false){
                    showErrorAlert("出错", setMessage: "网络或服务器出错")
                }
                else{
                    self.successNotice("注册人脸成功", autoClear: true)
                    
                    self.okButton.enabled = true
                    self.redoButton.enabled = true
                    self.performSegueWithIdentifier("toRegisterVoice", sender: self)
                }
            }
        }
    }
    
    //重新选择照片
    @IBAction func redo(sender: UIButton) {
        self.promptInfo.alpha = 1
        self.promptInfo.text = "请重新选择照片！"
        self.photoSelecteButton.alpha = 1
        self.photoSelecteButton.enabled = true
        
        self.showImage.alpha = 0
        self.okButton.alpha = 0
        self.okButton.enabled = false
        self.redoButton.alpha = 0
        self.redoButton.enabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //显示错误提示
    func showErrorAlert(setTitle:String, setMessage: String) {
        self.okButton.enabled = true
        self.redoButton.enabled = true
        
        var alert : UIAlertController!
        let redoAction = UIAlertAction(title: "确认", style: UIAlertActionStyle.Cancel, handler: nil)
        
        alert = UIAlertController(title: setTitle, message: setMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(redoAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func viewWillAppear(animated: Bool) {
        self.showImage.alpha = 0
        self.okButton.alpha = 0
        self.okButton.enabled = false
        self.redoButton.alpha = 0
        self.redoButton.enabled = false
        
        self.promptInfo.text = "本应用登录需要运用到人脸识别，请选择照片，以进行下一步"
        self.promptInfo.alpha = 1
        self.photoSelecteButton.alpha = 1
        self.photoSelecteButton.enabled = true
    }
}
