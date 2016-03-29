//
//  RegisterViewController.swift
//  LOCK ME
//
//  Created by 马家固 on 16/2/22.
//  Copyright © 2016年 马家固. All rights reserved.
//

import UIKit
import CoreData

class RegisterViewController: UIViewController {
    
    var saveUsers = [NSManagedObject]()
    var alert : UIAlertController!

    @IBOutlet weak var inputName: UITextField!
    @IBOutlet weak var inputPassword: UITextField!
    
    @IBAction func toVerifyPass(sender: UIButton) {
        
        
        if(inputName.text == nil || inputPassword.text == nil) {
            self.errorNotice("请输入完整", autoClear: true)
        }
        //判断userName与password是否符合规范
        let nameCount = inputName.text?.characters.count
        let firstCharVaild = isWordLetter(inputName.text?.characters.first)
        if(firstCharVaild != true || nameCount < 6 || nameCount > 15){
            let redoAction = UIAlertAction(title: "确认", style: UIAlertActionStyle.Cancel, handler: nil)
            if(firstCharVaild != true && 6 <= nameCount && nameCount <= 15){
                alert = UIAlertController(title: "用户名不符合规范", message: "首字母需为字母", preferredStyle: UIAlertControllerStyle.Alert)
            }
            else if(firstCharVaild == true) {
                alert = UIAlertController(title: "用户名不符合规范", message: "长度不符合", preferredStyle: UIAlertControllerStyle.Alert)
            }
            alert.addAction(redoAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else if(inputName.text?.characters.count < 10) {
            self.errorNotice("密码过短", autoClear: true)
        }
        else {
            self.pleaseWait()
            let name = inputName.text! as String
            let password = inputPassword.text! as String
            
            //首先查找是否有同名的情况
            let user = AVObject(className: "lockMeUser")
            user["userName"] = name
            user["password"] = password
            
            let query = AVQuery(className: "lockMeUser")
            query.whereKey("userName", equalTo: name)
            
            query.getFirstObjectInBackgroundWithBlock({ (object, e) -> Void in
                //该用户名已存在
                if(object != nil){
                    self.clearAllNotice()
                    self.errorNotice("用户名存在", autoClear: true)
                }
                else{
                    self.clearAllNotice()
                    tempUserName = name
                    tempPassword = password
                    
                    print(e)
                    
                    self.successNotice("信息可用", autoClear: true)
                    self.performSegueWithIdentifier("toVerifyPassword", sender: self)
                }
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        inputName.text = tempUserName
        inputPassword.text = tempPassword
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.backgroundColor = UIColor.blackColor()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isWordLetter(word: Character?) -> Bool {
        if(word != nil) {
            if(word <= "z" && word >=  "a"){
                return true
            }
            else if(word <= "Z" && word >= "A"){
                return true
            }
        }
        return false
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.inputName.resignFirstResponder()
        self.inputPassword.resignFirstResponder()
    }
}
