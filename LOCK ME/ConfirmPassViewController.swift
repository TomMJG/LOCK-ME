//
//  ConfirmPassViewController.swift
//  LOCK ME
//
//  Created by 马家固 on 16/2/25.
//  Copyright © 2016年 马家固. All rights reserved.
//

import UIKit

class ConfirmPassViewController: UIViewController {

    @IBOutlet weak var password: UITextField!
    @IBAction func okButton(sender: UIButton) {
        if(password.text != nil){
            if((password.text! as String) == tempPassword){
                self.performSegueWithIdentifier("toFaceRecognition", sender: self)
            }
            else{
                self.errorNotice("密码错误", autoClear: true)
            }
        }
        else{
            self.errorNotice("输入为空", autoClear: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        self.password.text = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.password.resignFirstResponder()
    }
}
