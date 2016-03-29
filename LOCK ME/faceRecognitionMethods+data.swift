//
//  faceRecognitionMethods.swift
//  LOCK ME
//
//  Created by 马家固 on 16/2/22.
//  Copyright © 2016年 马家固. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//定义iflyMSC框架所需的宏
//pragma mark result_dic key
let SUC_KEY = "suc"
let RGN_KEY = "rgn"

//pwdt type
let TRAIN_SST = "train"
let VERIFY_SST = "verify"
let DCS = "dcs"
let SUCCESS = "success"
let FAIL = "fail"

let KEY_PTXT = "ptxt"
let KEY_RGN = "rgn"
let KEY_TSD = "tsd"
let KEY_SUB = "sub"
let KEY_PWDT = "pwdt"
let KEY_TAIL = "vad_speech_tail"
let KEY_AUTHID = "auth_id"
let KEY_SST = "sst"
let KEY_KEYTIMEOUT = "key_speech_timeout"
let KEY_VADTIMEOUT = "vad_timeout"

let DEL = "del"
let QUERY = "que"

let PWDT_FIXED_CODE = 1 //固定密码

let FIXED_CODE_VERIFY_TAG = 3
let FIXED_CODE_TRAIN_TAG = 2
let FIXED_CODE_QUERY_TAG = 4
let FIXED_CODE_DEL_TAG = 5

var codeArray : [String]?  //保存固定密码的数组

var networkConnect = false  //保存网络是否连接

//注册时暂时存储的用户信息
var tempUserName = ""
var tempPassword = ""

//获取总代理
let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
let managedObjectContents = appDelegate.managedObjectContext
let fetchRequestUser = NSFetchRequest(entityName: "User")
let fetchRequestImages = NSFetchRequest(entityName: "Images")
let fetchRequestNotes = NSFetchRequest(entityName: "Notes")

//获得face_id
func getFace_id(image: UIImage) -> String {
    let imageData : NSData = UIImageJPEGRepresentation(image, 100)!
    let result = FaceppAPI.detection().detectWithURL(nil, orImageData: imageData)
    
    if(result.success){
        let face_id = result.content["face"]?[0]["face_id"]
        if(face_id == nil) {
            return "Don't detect face"
        }
        else{
            return face_id as! String
        }
    }
    return "network error"
}

//创建对应的人物
func createPerson(personName : String ,tag: String, face_id : [String], groupName : [String]) -> Bool {
    let result = FaceppAPI.person().createWithPersonName(personName, andFaceId: face_id, andTag: tag, andGroupId: nil, orGroupName: groupName)
    
    if(result.success){
        let addFace = result.content["added_face"]
        let errorCode = result.content["error_code"]
        
        if(errorCode != nil) {
            return false
        }
        else{
            if(addFace != nil){
                if((addFace as! Int) > 0){
                    return true
                }
            }
            return false
        }
    }
    return false
}

//训练人脸识别
func train_verify(personName: String) -> Bool {
    let result = FaceppAPI.train().trainAsynchronouslyWithId(nil, orName: personName, andType: FaceppTrainVerify)
    
    if(result.success) {
        let session_id = result.content["session_id"] as! String
        
        return getSession_idInfo(session_id)
    }
    else {
        return false
    }
}

//获取Session_id的信息
func getSession_idInfo(session_id: String) -> Bool {
    let result = FaceppAPI.info().getSessionWithSessionId(session_id)
    
    if(result.success){
        let status = result.content["status"] as! String
        if(status == "SUCC") {
            return true
        }
        else if (status == "FAILED") {
            return false
        }
        else if(status == "INQUEUE") {
            //暂停2秒执行
            NSThread.sleepForTimeInterval(2)
            return getSession_idInfo(session_id)
        }
    }
    return false
}

//进行人脸识别
func verifyFace(faceId: String, personName: String) -> Bool {
    let result = FaceppAPI.recognition().verifyWithFaceId(faceId, andPersonId: nil, orPersonName: personName, async: false)
    
    if(result.success){
        let isSamePerson = result.content["is_same_person"]
        if(isSamePerson == nil) {
            return false
        }
        else{
            if((isSamePerson as! String) == "true"){
                return true
            }
            return false
        }
    }
    else{
        return false
    }
}