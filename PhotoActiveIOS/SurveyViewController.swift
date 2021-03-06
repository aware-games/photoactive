//
//  SurveyViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 12/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit
import Photos

class SurveyViewController: UIViewController {
	var pictureName: String?
	var inAppSurveys: JSON = []
	var currentSurvey = 0
	var loadIndicator: UIActivityIndicatorView?

	@IBOutlet weak var midViewCollection: UIView!
	@IBOutlet weak var slider: UISlider!
	@IBOutlet weak var sliderLabel: UILabel!
	@IBOutlet weak var sliderImage: UIImageView!
	@IBOutlet weak var questionText: UILabel!
	@IBOutlet weak var sliderMaxText: UILabel!
	@IBOutlet weak var sliderMinText: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		loadIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
		loadIndicator!.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadIndicator!.center = self.view.center
		loadIndicator!.backgroundColor = UIColor.darkGrayColor()
		loadIndicator!.layer.cornerRadius = 10
		self.view.addSubview(loadIndicator!)
		loadIndicator!.bringSubviewToFront(self.view)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SurveyViewController.onScreenRotation), name: UIDeviceOrientationDidChangeNotification, object: nil)

		slider.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))

		if pictureName == nil {
			NSLog("Error: Could not start SurveyViewController, pictureName not set.")
			displayAlert("Could not open in-app survey, parameter \"pictureName\" not set.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}
		
		let inAppSurveysString = getInAppSurveys()
		if (inAppSurveysString == nil || inAppSurveysString!.isEmpty) {
			NSLog("Error: Could not start SurveyViewController, in app surveys are empty or nil.")
			displayAlert("Could not open in-app survey, survey data is corrupt.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}
		
		if let dataFromString = inAppSurveysString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
			inAppSurveys = JSON(data: dataFromString)[IN_APP_SURVEYS]
		}
		if (inAppSurveys == nil) {
			NSLog("Error: Could not start SurveyViewController, in app surveys object could not be created.")
			displayAlert("Could not open in-app survey, survey data is corrupt.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}

		if !updateUI() {
			NSLog("Warning: Could not start SurveyViewController, first survey has faulty JSON.")
			submitImageAndAnswer(nil, answer: nil) {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func onScreenRotation() {
		loadIndicator!.center = self.view.center
	}

	@IBAction func sliderValueChanged(sender: UISlider) {
		let currentValue = Int(sender.value)
		sliderLabel.text = "\(currentValue)"
		let imageName = "smiley_" + String(currentValue) + ".png"
		sliderImage.image = UIImage(named: imageName)
	}

	@IBAction func submitAppAnswer() {
		let answer = Int(slider.value)
		let iasurveyID = inAppSurveys[currentSurvey][ID].numberValue
		submitImageAndAnswer(iasurveyID, answer: answer, withClosure: nil)
	}

	func submitImageAndAnswer(iasurveyID: NSNumber?, answer: Int?, withClosure block: (() -> Void)?) {
		loadIndicator?.startAnimating()

		let projectID = getProjectID()
		var picEnc = ""
		let asset = PHAsset.fetchAssetsWithLocalIdentifiers([pictureName!], options: nil).firstObject as! PHAsset
		let requestOptions = PHImageRequestOptions()
		requestOptions.synchronous = true // block further execution until we have our base64-encoded string
		PHImageManager.defaultManager().requestImageDataForAsset(asset, options: requestOptions, resultHandler: { data, dataUTI, orientation, info in
			let base64 = data!.base64EncodedStringWithOptions([])
			picEnc = base64
		})
		let tf = NSDateFormatter()
		tf.dateFormat = TS_FORMAT
		let timestamp = tf.stringFromDate(NSDate())
		let cookie = getSessionCookie()
		
		var json = JSON([PROJECT_ID: projectID, PIC_ENC: picEnc, TIMESTAMP: timestamp])
		if iasurveyID != nil {
			json[IASURVEY_ID] = JSON(iasurveyID!)
		}
		if answer != nil {
			json[ANSWER] = JSON(answer!)
		}

		let photoOnly = iasurveyID == nil && answer == nil
		let url = photoOnly ? SUBMIT_PIC_URL : SUBMIT_APP_ANSWER_URL

		let posting = AsyncServerPost(url: url, json: json, cookie: cookie,
			successHandler: { data, cookie in
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.loadIndicator?.stopAnimating()
					Toast(msg: "Answer submitted", duration: nil, viewController: self).show({
						self.navigationController?.popToRootViewControllerAnimated(true)
					})
				})
			},
			errorHandler: { errorCode, data in
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.loadIndicator?.stopAnimating()
					let msgEnd = photoOnly ? "photo" : "photo and survey answer"
					NSLog("Failed to submit \(msgEnd). Code = \(errorCode), message = \(data)")
					self.displayUploadAlert("Could not submit \(msgEnd).")
				})
		})
		posting.execute()
	}

	func getProjectID() -> String {
		let path = DOCUMENTS_DIR.URLByAppendingPathComponent(P_FILE).path!
		let projectID = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
		if projectID != nil {
			return projectID!
		}
		else {
			return EMPTY
		}
	}
	
	func getSessionCookie() -> String {
		let path = DOCUMENTS_DIR.URLByAppendingPathComponent(SC_FILE).path!
		let cookie = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
		if cookie != nil {
			return cookie!
		}
		else {
			return EMPTY
		}
	}

	func getInAppSurveys() -> String? {
		let path = DOCUMENTS_DIR.URLByAppendingPathComponent(IAS_FILE).path!
		let inAppSurveys = try? String(contentsOfFile: path, encoding: NSUTF8StringEncoding)
		if inAppSurveys != nil {
			return inAppSurveys
		}
		else {
			return nil
		}
	}

	func displayUploadAlert(msg: String) {
		let alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Retry", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			self.submitAppAnswer()
		}))
		alert.addAction(UIAlertAction(title: "Exit", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			self.navigationController?.popToRootViewControllerAnimated(true)
		}))
		presentViewController(alert, animated: true, completion: nil)
	}

	func displayAlert(msg: String, withClosure block: (() -> Void)?) {
		let alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			if block != nil {
				NSOperationQueue.mainQueue().addOperationWithBlock({
					block!()
				})
			}
		}))
		presentViewController(alert, animated: true, completion: nil)
	}

	func updateUI() -> Bool {
		let inAppSurvey = inAppSurveys[currentSurvey]
		if inAppSurvey.count == 0 {
			return false
		}

		questionText.text = inAppSurvey[QUESTION_TEXT].stringValue
		if !inAppSurvey[SLIDER_MAX_TEXT].stringValue.isEmpty {
			sliderMaxText.text = inAppSurvey[SLIDER_MAX_TEXT].stringValue
		}
		if !inAppSurvey[SLIDER_MIN_TEXT].stringValue.isEmpty {
			sliderMinText.text = inAppSurvey[SLIDER_MIN_TEXT].stringValue
		}
		if inAppSurvey[SLIDER_MAX] != nil && inAppSurvey[SLIDER_MIN] != nil {
			slider.maximumValue = inAppSurvey[SLIDER_MAX].floatValue
			slider.minimumValue = inAppSurvey[SLIDER_MIN].floatValue
		}
		else if inAppSurvey[SLIDER_MAX] != nil {
			slider.maximumValue = inAppSurvey[SLIDER_MAX].floatValue
			slider.minimumValue = 1
		}
		else if inAppSurvey[SLIDER_MIN] != nil {
			slider.maximumValue = 7
			slider.minimumValue = inAppSurvey[SLIDER_MIN].floatValue
		}
		else {
			slider.maximumValue = 7
			slider.minimumValue = 1
		}
		slider.setValue(((slider.maximumValue - slider.minimumValue) / 2) + slider.minimumValue, animated: false)
		sliderValueChanged(slider)
		return true
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
