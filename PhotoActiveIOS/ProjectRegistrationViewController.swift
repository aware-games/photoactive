//
//  ProjectRegistrationViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 25/08/15.
//  Copyright © 2015 Aware Games. All rights reserved.
//

import UIKit

class ProjectRegistrationViewController: UIViewController, UITextFieldDelegate {
	@IBOutlet weak var projectVal: UITextField!
	var loadIndicator: UIActivityIndicatorView?

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		projectVal.delegate = self

		loadIndicator = UIActivityIndicatorView(activityIndicatorStyle:UIActivityIndicatorViewStyle.WhiteLarge)
		loadIndicator!.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadIndicator!.center = self.view.center
		loadIndicator!.backgroundColor = UIColor.darkGrayColor()
		loadIndicator!.layer.cornerRadius = 10
		self.view.addSubview(loadIndicator!)
		loadIndicator!.bringSubviewToFront(self.view)

		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProjectRegistrationViewController.onScreenRotation), name: UIDeviceOrientationDidChangeNotification, object: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		projectVal.resignFirstResponder()
		return true
	}

	func onScreenRotation() {
		loadIndicator!.center = self.view.center
	}

	@IBAction func submitProjectID(sender: UIButton) {
		let projectID = projectVal.text
		let json = JSON([PROJECT_ID: projectID!])
		let posting = AsyncServerPost(url: PROJECT_REG_URL, json: json,
			successHandler: { data, cookie in
				NSOperationQueue.mainQueue().addOperationWithBlock({
					let path = DOCUMENTS_DIR.URLByAppendingPathComponent(P_FILE).path!
					var error: NSError?
					let success: Bool
					do {
						try projectID!.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
						success = true
					} catch let error1 as NSError {
						error = error1
						success = false
					} catch {
						fatalError()
					}
					if !success {
						NSLog("Error: Failed to store project ID. \(error)")
						self.displayAlert("Could not save vital data to file. Error code: \(error?.code)", withClosure: nil)
						self.loadIndicator?.stopAnimating()
					}
					else {
						self.loadIndicator?.stopAnimating()
						self.performSegueWithIdentifier("UserRegistrationSegue", sender: self)
					}
				})
			},
			errorHandler: { errorCode, data in
				NSOperationQueue.mainQueue().addOperationWithBlock({
					self.displayAlert("Failed to validate project ID, please try again", withClosure: nil)
					self.loadIndicator?.stopAnimating()
					NSLog("Error: Failed to validate project ID. Error code = \(errorCode). Data = \(data).")
				})
			}
		)

		loadIndicator?.startAnimating()
		posting.execute()
	}

	func displayAlert(msg: String, withClosure block: (() -> Void)?) {
		let alert = UIAlertController(title: "Error", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
			alert.dismissViewControllerAnimated(true, completion: nil)
			if block != nil {
				block!()
			}
		}))
		presentViewController(alert, animated: true, completion: nil)
	}

	/*
	// MARK: Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the view controller using segue.destinationViewController.
		// Pass the selected objects to the new view controller.
	}
	*/

}