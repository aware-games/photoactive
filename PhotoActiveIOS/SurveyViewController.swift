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
		if pictureName == nil {
			NSLog("Error: Could not start SurveyViewController, pictureName not set.")
			displayAlert("Picture not found.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}

		let inAppSurveysString = getInAppSurveys()
		if (inAppSurveysString == nil || inAppSurveysString!.isEmpty) {
			NSLog("Error: Could not start SurveyViewController, in app surveys are empty or nil.")
			displayAlert("In app surveys syntax invalid.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}

		if let dataFromString = inAppSurveysString?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
			inAppSurveys = JSON(data: dataFromString)[IN_APP_SURVEYS]
		}
		if (inAppSurveys == nil) {
			NSLog("Error: Could not start SurveyViewController, in app surveys object could not be created.")
			displayAlert("In app surveys syntax invalid.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}

		loadIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
		loadIndicator!.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadIndicator!.center = self.view.center
		loadIndicator!.backgroundColor = UIColor.darkGrayColor()
		loadIndicator!.layer.cornerRadius = 10
		self.view.addSubview(loadIndicator!)
		loadIndicator!.bringSubviewToFront(self.view)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "onScreenRotation", name: UIDeviceOrientationDidChangeNotification, object: nil)

		slider.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))

		if !updateUI() {
			NSLog("Warning: Could not start SurveyViewController, first survey has faulty JSON.")
			submitImageAndAnswer(nil, answer: nil)
			navigationController?.popToRootViewControllerAnimated(true)
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
		submitImageAndAnswer(iasurveyID, answer: answer)
	}

	func submitImageAndAnswer(iasurveyID: NSNumber?, answer: Int?) {
		loadIndicator?.startAnimating()

		let projectID = getProjectID()
		var picEnc = ""
		let asset = PHAsset.fetchAssetsWithLocalIdentifiers([pictureName!], options: nil).firstObject as! PHAsset
		let requestOptions = PHImageRequestOptions()
		requestOptions.synchronous = true // block further execution until we have our base64-encoded string
		PHImageManager.defaultManager().requestImageDataForAsset(asset, options: requestOptions, resultHandler: { data, dataUTI, orientation, info in
			let base64 = data.base64EncodedStringWithOptions(nil)
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
		let posting = AsyncServerPost(url: SUBMIT_APP_ANSWER_URL, json: json, cookie: cookie,
			successHandler: { data, cookie in
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.loadIndicator?.stopAnimating()
					Toast(msg: "Answer submitted", duration: nil).show()
					self.navigationController?.popToRootViewControllerAnimated(true)
				})
			},
			errorHandler: { errorCode, data in
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.loadIndicator?.stopAnimating()
					NSLog("Failed to submit photo and survey answer. Code = \(errorCode), message = \(data)")
					self.displayUploadAlert("Failed to submit photo and survey answer.")
				})
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

	func getInAppSurveys() -> String? {
		let path = DOCUMENTS_DIR.stringByAppendingPathComponent(IAS_FILE)
		let inAppSurveys = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)
		if inAppSurveys != nil {
			return inAppSurveys
		}
		else {
			return nil
		}
	}

	func displayUploadAlert(msg: String) {
		var alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
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
		var alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			if block != nil {
				block!()
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
