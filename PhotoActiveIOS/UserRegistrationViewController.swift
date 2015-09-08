//
//  UserRegistrationViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 25/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit

class UserRegistrationViewController: UIViewController, UITextFieldDelegate {
	var login = false
	var loadIndicator: UIActivityIndicatorView?

	@IBOutlet weak var emailInput: UITextField!
	@IBOutlet weak var passwordInput: UITextField!
	@IBOutlet weak var headerText: UILabel!
	@IBOutlet weak var registerBtn: UIButton!
	@IBOutlet weak var switchText: UILabel!
	@IBOutlet weak var switchBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		emailInput.delegate = self
		passwordInput.delegate = self

		loadIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
		loadIndicator!.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
		loadIndicator!.center = self.view.center
		loadIndicator!.backgroundColor = UIColor.darkGrayColor()
		loadIndicator!.layer.cornerRadius = 10
		self.view.addSubview(loadIndicator!)
		loadIndicator!.bringSubviewToFront(self.view)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "onScreenRotation", name: UIDeviceOrientationDidChangeNotification, object: nil)
		updateUITexts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField == emailInput {
			passwordInput.becomeFirstResponder()
		}
		else {
			textField.resignFirstResponder()
		}
		return true
	}
	
	func onScreenRotation() {
		loadIndicator!.center = self.view.center
	}

	@IBAction func submitBtnPressed(sender: UIButton) {
		let username = emailInput.text
		let password = passwordInput.text
		let url = login ? USER_AUTH_URL : USER_REG_URL
		let json = JSON([USERNAME: username, PASSWORD: password])
		let posting = AsyncServerPost(url: url, json: json,
			successHandler: { data, cookie in
				let path = DOCUMENTS_DIR.stringByAppendingPathComponent(SC_FILE)
				var error: NSError?
				let success = cookie!.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: &error)
				if !success {
					NSLog("Error: Failed to store session cookie. \(error)")
					self.displayAlert("Error saving vital data. Error code: \(error?.code)") {
						self.loadIndicator?.stopAnimating()
					}
				}
				else {
					self.loadIndicator?.stopAnimating()
					self.performSegueWithIdentifier("MainMenu2Segue", sender: self)
				}
			},
			errorHandler: { errorCode, data in
				let msg = self.login ? "Email / password not valid, please try again." : "Email already in use, please try again."
				self.displayAlert(msg) {
					self.loadIndicator?.stopAnimating()
				}
		})
		
		loadIndicator?.startAnimating()
		posting.execute()
	}

	@IBAction func switchTextBtnPressed(sender: UIButton) {
		login = !login
		updateUITexts()
	}

	func updateUITexts() {
		if login {
			headerText.text = "Login to access PhotoActive"
			registerBtn.setTitle("Login", forState: UIControlState.Normal)
			switchText.text = "Don't have an account?"
			switchBtn.setTitle("Register here.", forState: UIControlState.Normal)
		}
		else {
			headerText.text = "Register a new user account to PhotoActive"
			registerBtn.setTitle("Register", forState: UIControlState.Normal)
			switchText.text = "Already have an account?"
			switchBtn.setTitle("Login here.", forState: UIControlState.Normal)
		}
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
