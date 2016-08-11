//
//  Toast.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 21/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit

class Toast {
	static let DEFAULT_MSG = "Default message"

//	let toast = UIAlertView(title: EMPTY, message: DEFAULT_MSG, delegate: nil, cancelButtonTitle: nil)
	let toast = UIAlertController(title: EMPTY, message: DEFAULT_MSG, preferredStyle: UIAlertControllerStyle.Alert)
	var duration = 2.5
	var viewController: UIViewController

	init(msg: String, duration: Double?, viewController: UIViewController) {
		toast.message = msg
		if duration != nil {
			self.duration = duration!
		}
		self.viewController = viewController
	}

	func show(completion: (() -> Void)?) {
//		toast.show()
		viewController.presentViewController(toast, animated: true, completion: nil)
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(duration * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
//			self.toast.dismissWithClickedButtonIndex(0, animated: true)
			self.toast.dismissViewControllerAnimated(true, completion: nil)
			if completion != nil {
				completion!()
			}
		})
	}
}