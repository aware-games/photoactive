//
//  EntryPortViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 24/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit
import Photos

class EntryPortViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

//        // start by checking photo library access
//		if PHPhotoLibrary.authorizationStatus() == .Authorized {
//			// if ok, continue initialization
//			startInitializing()
//		}
//		else {
//			// otherwise, request autorization and handle user response accordingly
//			PHPhotoLibrary.requestAuthorization() { status in
//				if status == .Authorized {
					self.startInitializing()
//				}
//				else {
//					dispatch_async(dispatch_get_main_queue(), { () -> Void in
//						self.displayAlert("You must allow the app to access the Photos library or the app will not function properly.") {
//							exit(0)
//						}
//					})
//				}
//			}
//		}
    }

	func startInitializing() {
		let qualityOfServiceClass = QOS_CLASS_BACKGROUND
		let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
		dispatch_async(backgroundQueue, {
			// This is run on the background queue
			let result = self.intializeApp()
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				// This is run on the main queue, after the previous code in outer block
				if result == NO_ERROR {
					self.performSegueWithIdentifier("MainMenuSegue", sender: self)
				}
				else {
//					if result == PHOTO_LIBRARY_NOT_AVAILABLE {
//						self.displayAlert("Could not create PhotoActive album in Photos library, app will exit.") {
//							exit(0)
//						}
//					}
//					else {
						switch result {
						case NOT_AUTHENTICATED:
							self.performSegueWithIdentifier("UserLoginSegue", sender: self)
						case INITIAL_START_UP:
							fallthrough
						case INVALID_PROJECT_ID:
							fallthrough
						default:
							self.performSegueWithIdentifier("ProjectRegistrationSegue", sender: self)
						}
//					}
				}
			})
		})
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	func intializeApp() -> Int {
		var result = NO_ERROR

//		// create a PhotoActive-album in the Photos library if not existing already
//		let fetchOptions = PHFetchOptions()
//		fetchOptions.predicate = NSPredicate(format: "title = %@", "PhotoActive")
//		let collection: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
//
//		if collection.firstObject == nil {
//			PHPhotoLibrary.sharedPhotoLibrary().performChanges({
//				PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("PhotoActive")
//				},
//				completionHandler: { success, error in
//					if !success {
//						result = PHOTO_LIBRARY_NOT_AVAILABLE
//					}
//			})
//		}

		// check project id and session cookie
		let projectID = getProjectID()
		let sessionCookie = getSessionCookie()

		if (projectID.isEmpty && sessionCookie.isEmpty) {
			result = INITIAL_START_UP
		}

		if (result == NO_ERROR && !isValidProjectID(projectID)) {
			result = INVALID_PROJECT_ID
		}

		if (result == NO_ERROR && !isValidSessionCookie(sessionCookie)) {
			result = NOT_AUTHENTICATED
		}

		return result
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

	func isValidProjectID(projectID: String) -> Bool {
		if !projectID.isEmpty {
			let b = CallBackReturnHelper()
			let json = JSON([PROJECT_ID: projectID])
			let posting = SyncServerPost(url: PROJECT_REG_URL, json: json,
				successHandler: { data, cookie in
					b.value = true
			},
				errorHandler: { errorCode, data in
					b.value = false
			})

			posting.execute()
			return b.value
		}

		return false
	}

	func isValidSessionCookie(sessionCookie: String) -> Bool {
		if !sessionCookie.isEmpty {
			let b = CallBackReturnHelper()
			let json = JSON([])
			let posting = SyncServerPost(url: CHECK_SESSION_URL, json: json, cookie: sessionCookie, successHandler: { data, cookie in
					b.value = true
			},
				errorHandler: { errorCode, data in
					b.value = false
			})

			posting.execute()
			return b.value
		}

		return false
	}

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
		if segue.identifier == "UserLoginSegue" {
			let vc = segue.destinationViewController as! UserRegistrationViewController
			vc.login = true
		}
    }

}

class CallBackReturnHelper {
	var value: Bool = false
}
