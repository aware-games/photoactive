//
//  AppDelegate.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 01/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
		for notification in application.scheduledLocalNotifications! {
			let n = notification 
			let info = n.userInfo as! [String : AnyObject]
			if let endDateTimeStamp = info[END_DATE] as? NSNumber {
				let endDate = NSDate(timeIntervalSince1970: endDateTimeStamp.doubleValue / 1000)
				endDate.addDays(1)
				let now = NSDate()
				if now.isGreaterThanDate(endDate) {
					application.cancelLocalNotification(n)
				}
			}
		}

		let takePhotoAction = UIMutableUserNotificationAction()
		takePhotoAction.identifier = "TAKE_PHOTO_ACTION"
		takePhotoAction.title = "OK"
		takePhotoAction.activationMode = .Foreground
		takePhotoAction.authenticationRequired = true
		takePhotoAction.destructive = false

		let postponeAction = UIMutableUserNotificationAction()
		postponeAction.identifier = "POSTPONE_ACTION"
		postponeAction.title = "Postpone"
		postponeAction.activationMode = .Foreground
		postponeAction.authenticationRequired = true
		postponeAction.destructive = false

		let reminderCategory = UIMutableUserNotificationCategory()
		reminderCategory.identifier = "REMINDER_CATEGORY"
		reminderCategory.setActions([takePhotoAction, postponeAction], forContext: .Default)

		application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [.Alert, .Sound], categories: Set([reminderCategory])))
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//		NSNotificationCenter.defaultCenter().postNotificationName("", object: self)
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

	func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
//		NSNotificationCenter.defaultCenter().postNotificationName("", object: self)
	}

	func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
		switch identifier! {
			case "TAKE_PHOTO_ACTION":
				let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
				let initialViewController = mainStoryboard.instantiateViewControllerWithIdentifier("MainMenu") as! MainMenuViewController
				window? = UIWindow(frame: UIScreen.mainScreen().bounds)
				window?.rootViewController = initialViewController
				window?.makeKeyAndVisible()
			case "POSTPONE_ACTION":
				let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
				let initialViewController = mainStoryboard.instantiateViewControllerWithIdentifier("PostponeAlarm") as! PostponeAlarmViewController
				initialViewController.alarmText = notification.alertBody
				window? = UIWindow(frame: UIScreen.mainScreen().bounds)
				window?.rootViewController = initialViewController
				window?.makeKeyAndVisible()
			default:
				NSLog("Warning: Unexpected notification action identifier: \(identifier!)")
		}
	}

}

let P_FILE = "p"
let SC_FILE = "sc"
let IAS_FILE = "ias"
let ALARM_FILE = "alarm"

//let APP_DIRS = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true)
let APP_DIRS = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .AllDomainsMask)
let DOCUMENTS_DIR = APP_DIRS[0]

let NO_ERROR = -1
let PHOTO_LIBRARY_NOT_AVAILABLE = 1
let INITIAL_START_UP = 2
let INVALID_PROJECT_ID = 3
let NOT_AUTHENTICATED = 4

let OK = 200

let PROJECT_ID = "projectID"
let ALARM = "alarm"
let ACTIVE = "active"
let TIMES = "times"
let TEXT = "text"
let REPEAT_DAILY = "repeatDaily"
let START_DATE = "startDate"
let END_DATE = "endDate"
let ALARM_TEXT = "alarmText"
let ID = "id"
let IS_FINISHED = "isFinished"
let PIC_ENC = "picEnc"
let TIMESTAMP = "timeStamp"
let TS_FORMAT = "yyyy-MM-dd HH:mm:ss"
let IASURVEY_ID = "iasurveyID"
let ANSWER = "answer"
let PICTURE_NAME = "pictureName"
let IN_APP_SURVEYS = "inAppSurveys"
let QUESTION_TEXT = "questionText"
let SLIDER_MAX_TEXT = "sliderMaxText"
let SLIDER_MIN_TEXT = "sliderMinText"
let SLIDER_MAX = "sliderMax"
let SLIDER_MIN = "sliderMin"
let USERNAME = "username"
let PASSWORD = "password"
let EMPTY = ""
let SEMI_COLON = ";"
let EQUALS_SIGN = "="

let JSON_MIME_TYPE = "application/json"
let CONTENT_TYPE = "Content-Type"
let POST_METHOD = "POST"
let GET_COOKIES_HEADER = "Set-Cookie"
let SET_COOKIES_HEADER = "Cookie"
let NINJA_COOKIE_NAME = "NINJA_SESSION"

let SERVER_URL = NSBundle.mainBundle().infoDictionary?["SERVER_URL"] as! String
let PROJECT_REG_URL = SERVER_URL + "/api/check-project.json"
let CHECK_SESSION_URL = SERVER_URL + "/api/check-valid-session.json"
let GET_IN_APP_SURVEYS_URL = SERVER_URL + "/api/in-app-surveys.json"
let GET_SURVEY_ALARMS_URL = SERVER_URL + "/api/survey-alarms.json"
let IS_FINISHED_URL = SERVER_URL + "/api/is-finished"
let SUBMIT_APP_ANSWER_URL = SERVER_URL + "/api/submit-app-answer.json"
let SUBMIT_PIC_URL = SERVER_URL + "/api/submit-app-picture.json"
let USER_REG_URL = SERVER_URL + "/api/register.json"
let USER_AUTH_URL = SERVER_URL + "/login.json"
