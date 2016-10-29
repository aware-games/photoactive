//
//  UploadPictureViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 29/10/16.
//  Copyright © 2016 Aware Games. All rights reserved.
//

import UIKit
import Photos

class UploadPictureViewController: UIViewController {
	var pictureName: String?
	var loadIndicator: UIActivityIndicatorView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		loadIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
		loadIndicator!.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadIndicator!.center = self.view.center
		loadIndicator!.backgroundColor = UIColor.darkGrayColor()
		loadIndicator!.layer.cornerRadius = 10
		self.view.addSubview(loadIndicator!)
		loadIndicator!.bringSubviewToFront(self.view)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UploadPictureViewController.onScreenRotation), name: UIDeviceOrientationDidChangeNotification, object: nil)

		if pictureName == nil {
			NSLog("Error: Could not start UploadPictureViewController, pictureName not set.")
			displayAlert("Could not upload picture, parameter \"pictureName\" not set.") {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
			return
		}
		
		submitImageAndAnswer() {
			self.navigationController?.popToRootViewControllerAnimated(true)
		}
	}
	
	func onScreenRotation() {
		loadIndicator!.center = self.view.center
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
	
	func displayUploadAlert(msg: String) {
		let alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Retry", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			self.submitImageAndAnswer() {
				self.navigationController?.popToRootViewControllerAnimated(true)
			}
		}))
		alert.addAction(UIAlertAction(title: "Exit", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			self.navigationController?.popToRootViewControllerAnimated(true)
		}))
		presentViewController(alert, animated: true, completion: nil)
	}
	
	func submitImageAndAnswer(withClosure block: (() -> Void)?) {
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
		
		let json = JSON([PROJECT_ID: projectID, PIC_ENC: picEnc, TIMESTAMP: timestamp])
		let posting = AsyncServerPost(url: SUBMIT_PIC_URL, json: json, cookie: cookie,
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
											NSLog("Failed to submit photo. Code = \(errorCode), message = \(data)")
											self.displayUploadAlert("Could not submit photo.")
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
}