//
//  ViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 01/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit
import Photos

class MainMenuViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
	var imagePicker: UIImagePickerController = UIImagePickerController()
	let photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
	var loadIndicator: UIActivityIndicatorView?
	var pictureName: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		loadIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
		loadIndicator!.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadIndicator!.center = self.view.center
		loadIndicator!.backgroundColor = UIColor.darkGrayColor()
		loadIndicator!.layer.cornerRadius = 10
		self.view.addSubview(loadIndicator!)
		loadIndicator!.bringSubviewToFront(self.view)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "onScreenRotation", name: UIDeviceOrientationDidChangeNotification, object: nil)

		getInAppSurveys()
		getSurveyAlarms()
		checkIfFinished()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func onScreenRotation() {
		loadIndicator!.center = self.view.center
	}

	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if segue.identifier == "SurveySegue" {
			let destController = segue.destinationViewController as? SurveyViewController
			destController?.pictureName = self.pictureName
			loadIndicator!.stopAnimating()
		}
	}

	// MARK: - Misc

	func displayAlert(msg: String) {
		displayAlert(msg, withClosure: nil)
	}

	func displayAlert(msg: String, withClosure block: (() -> Void)?) {
		var alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			if block != nil {
				block!()
			}
		}))
		presentViewController(alert, animated: true, completion: nil)
	}

	func displayNeutralDialog(msg: String) {
		var alert = UIAlertController(title: "Attention", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			exit(0)
		}))
		presentViewController(alert, animated: true, completion: nil)
	}

	func getInAppSurveys() {
		let json = JSON([PROJECT_ID: getProjectID()])
		let posting = AsyncServerPost(url: GET_IN_APP_SURVEYS_URL, json: json, cookie: getSessionCookie(),
			successHandler: { data, cookie in
				let path = DOCUMENTS_DIR.stringByAppendingPathComponent(IAS_FILE)
				var error: NSError?
				let success = data.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: nil)

				if !success {
					NSLog("Error: Failed to store in-app survey data. \(error)")
					NSOperationQueue.mainQueue().addOperationWithBlock({
						self.displayAlert("Could not save vital data to file.")
					})
				}
			},
			errorHandler: { errorCode, data in
				NSLog("Error: Failed to fetch in-app surveys JSON.")
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.displayAlert("Could not fetch in-app survey data.")
				})
		})
		posting.execute()
	}

	func getSurveyAlarms() {
		let json = JSON([PROJECT_ID: getProjectID()])
		let posting = AsyncServerPost(url: GET_SURVEY_ALARMS_URL, json: json, cookie: getSessionCookie(),
			successHandler: { data, cookie in
				let path = DOCUMENTS_DIR.stringByAppendingPathComponent(ALARM_FILE)
				var error: NSError?
				let success = data.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: &error)
				
				if !success {
					NSLog("Error: Failed to store survey alarm data. \(error)")
					NSOperationQueue.mainQueue().addOperationWithBlock({
						self.displayAlert("Could not save vital data to file.")
					})
				}

				if let dataFromString = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
					let result = JSON(data: dataFromString)
					if !result[ALARM].isEmpty {
						self.createAlarm(result[ALARM])
					}
				}
				else {
					NSLog("Error: Failed to create survey alarms. Not able to create NSData object from string.")
					NSOperationQueue.mainQueue().addOperationWithBlock({
						self.displayAlert("Failed to create reminder alarms.")
					})
				}
			},
			errorHandler: { errorCode, data in
				NSLog("Failed to fetch survey alarms.")
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.displayAlert("Could not fetch survey alarm data.")
				})
		})
		posting.execute()
	}

	func checkIfFinished() {
		let json = JSON([])
		let posting = AsyncServerPost(url: IS_FINISHED_URL, json: json, cookie: getSessionCookie(),
			successHandler: { data, cookie in
				if let dataFromString = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
					let result = JSON(data: dataFromString)
					let isFinished = result[IS_FINISHED].boolValue
					if isFinished {
						NSOperationQueue.mainQueue().addOperationWithBlock({
							self.displayNeutralDialog("You have already finished participating in this project. Thanks for sharing your time and input.")
						})
					}
				}
			},
			errorHandler: { errorCode, data in
				// Don't do anything
		})
		posting.execute()
	}

	func getProjectID() -> String {
		let path = DOCUMENTS_DIR.stringByAppendingPathComponent(P_FILE)
		let projectID = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
		if projectID != nil {
			return projectID!
		}
		else {
			return EMPTY
		}
	}

	func getSessionCookie() -> String {
		let path = DOCUMENTS_DIR.stringByAppendingPathComponent(SC_FILE)
		let cookie = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
		if cookie != nil {
			return cookie!
		}
		else {
			return EMPTY
		}
	}

	func createAlarm(data: JSON) {
		// Don't create alarm if not active
		if !data[ACTIVE].boolValue {
			return
		}

		// Get data
		let timesData = data[TIMES]
		let length = timesData.count
		if length == 0 {
			return
		}

		let alarmText = data[TEXT].stringValue
		let repeatDaily = data[REPEAT_DAILY].boolValue
		let startDate = NSDate(timeIntervalSince1970: data[START_DATE].doubleValue / 1000)
		let endDateTimeStamp = data[END_DATE].numberValue
		let endDate = NSDate(timeIntervalSince1970: endDateTimeStamp.doubleValue / 1000)

		let calendar = NSCalendar.currentCalendar()
		let startComp = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: startDate)
		let startYear = startComp.year
		let startMonth = startComp.month
		let startDay = startComp.day

		// Iterate over alarm times to create alarms
		for var i = 0; i < length; i++ {
			let time = NSDate(timeIntervalSince1970: timesData[i].doubleValue / 1000)
			let cal = NSCalendar.currentCalendar()
			let com = cal.components(.CalendarUnitHour | .CalendarUnitMinute, fromDate: time)
			let timeHour = com.hour - 2 // FIXME
			let timeMin = com.minute

			// Set the alarm to start at provided time (approximate)
			let alarmCal = NSCalendar.currentCalendar()
			var alarmCom = alarmCal.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond | .CalendarUnitNanosecond, fromDate: NSDate())
			alarmCom.year = startYear
			alarmCom.month = startMonth
			alarmCom.day = startDay
			alarmCom.hour = timeHour
			alarmCom.minute = timeMin
			alarmCom.second = 0
			alarmCom.nanosecond = 0
			var alarmTime = alarmCal.dateFromComponents(alarmCom)!

			// Create reference time to check if alarm time has already passed
			let now = NSDate()

			// If alarm is set to repeat, move start date to today or tomorrow, depending on whether today's alarm has passed or not
			if repeatDaily && alarmTime.isLessThanDate(now) {
				alarmCom = alarmCal.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond | .CalendarUnitNanosecond, fromDate: NSDate())
				alarmCom.hour = timeHour
				alarmCom.minute = timeMin
				alarmCom.second = 0
				alarmCom.nanosecond = 0
				alarmTime = alarmCal.dateFromComponents(alarmCom)!
				if alarmTime.isLessThanDate(now) {
					alarmCom.year = startYear
					alarmCom.month = startMonth
					alarmCom.day = startDay
					alarmTime.addDays(1)
					alarmTime = alarmCal.dateFromComponents(alarmCom)!
				}
			}

			// Don't set alarm if already passed
			if !repeatDaily && alarmTime.isLessThanDate(now) {
				return
			}

			endDate.addDays(1)
			if now.isLessThanDate(endDate) {
				let notification = UILocalNotification()
				notification.alertBody = alarmText.isEmpty ? "Please take a photo" : alarmText
				notification.alertAction = "open"
				notification.fireDate = alarmTime
				notification.soundName = UILocalNotificationDefaultSoundName
				notification.userInfo = [ID: i, END_DATE: endDateTimeStamp, REPEAT_DAILY: repeatDaily]
				notification.category = "REMINDER_CATEGORY"
				if repeatDaily {
					notification.repeatInterval = .CalendarUnitDay
				}
				UIApplication.sharedApplication().scheduleLocalNotification(notification)
			}
		}
	}

	// MARK - Take photo

	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {

		let image: AnyObject? = info[UIImagePickerControllerOriginalImage]
		let metaData = info[UIImagePickerControllerMediaMetadata] as! [NSObject : AnyObject]
		
		if var img = image as? UIImage {
			let fetch = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.AlbumRegular, options: nil)
			if fetch != nil {
				if let album = fetch.firstObject as? PHAssetCollection {
					addNewAssetWithImage(img, toAlbum: album)
				}
			}
		}

		imagePicker.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func imagePickerControllerDidCancel(picker: UIImagePickerController) {
		picker.dismissViewControllerAnimated(true, completion: nil)
	}

	/*
	Creating an asset and adding to an album.
	
	:param: image		Image to store.
	:param: toAlbum		Album in which to store the image.
	*/
	func addNewAssetWithImage(image: UIImage, toAlbum album: PHAssetCollection) {
		photoLibrary.performChanges( {
			// Show indicator
			NSOperationQueue.mainQueue().addOperationWithBlock({
				self.loadIndicator!.startAnimating()
			})

			// Rotate image
			let img = self.fixOrientation(image)

			// Request creating an asset from the image
			let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(img)

			// Request editing the album
			let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album)

			// Get a placeholder for the new asset and add it to the album editing request
			let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
			albumChangeRequest.addAssets([assetPlaceholder])
			self.pictureName = assetPlaceholder.localIdentifier
			},
			completionHandler: { success, error in
				if success {
					NSOperationQueue.mainQueue().addOperationWithBlock({
						self.performSegueWithIdentifier("SurveySegue", sender: self)
					})
				}
				else {
					NSOperationQueue.mainQueue().addOperationWithBlock({
						NSLog("Error: Failed to save photo to album. %@", error.localizedDescription)
						self.displayAlert("Could not save photo to album, please try again.")
						self.loadIndicator!.stopAnimating()
					})
				}
		})
	}

	func fixOrientation(image: UIImage) -> UIImage {
		if image.imageOrientation == UIImageOrientation.Left
			|| image.imageOrientation == UIImageOrientation.LeftMirrored {
				return image.imageRotatedByDegrees(270, flip: false, resize: true)
		}
		else if image.imageOrientation == UIImageOrientation.Right
			|| image.imageOrientation == UIImageOrientation.RightMirrored {
				return image.imageRotatedByDegrees(90, flip: false, resize: true)
		}
		else if image.imageOrientation == UIImageOrientation.Down
			|| image.imageOrientation == UIImageOrientation.DownMirrored {
				return image.imageRotatedByDegrees(180, flip: false, resize: false)
		}
		else {
			// Don't rotate
			return image
		}
	}

	@IBAction func takePhoto(sender: UIButton) {
		if UIImagePickerController.isSourceTypeAvailable(.Camera) {
			imagePicker.delegate = self
			imagePicker.sourceType = .Camera
			
			presentViewController(imagePicker, animated: true, completion: nil)
		}
		else {
			NSLog("Error: Could not open camera, not available.")
			NSOperationQueue.mainQueue().addOperationWithBlock({
				self.displayAlert("Could not open camera.")
			})
		}
	}
}