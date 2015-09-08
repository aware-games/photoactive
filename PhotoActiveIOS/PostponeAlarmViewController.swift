//
//  PostponeAlarmViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 04/09/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit

class PostponeAlarmViewController: UIViewController {
	@IBOutlet weak var alarmPostponePicker: UIDatePicker!

	var alarmText: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	@IBAction func onPostponeBtnPressed(sender: UIButton) {
		let id = arc4random()
		let newAlarmTime = alarmPostponePicker.date
		let now = NSDate()

		if newAlarmTime.isLessThanDate(now) {
			newAlarmTime.addDays(1)
		}

		let notification = UILocalNotification()
		notification.alertBody = alarmText != nil && !alarmText!.isEmpty ? alarmText! : "Please take a photo"
		notification.alertAction = "open"
		notification.fireDate = newAlarmTime
		notification.soundName = UILocalNotificationDefaultSoundName
		notification.userInfo = [ID: Int(id)]
		notification.category = "REMINDER_CATEGORY"
		UIApplication.sharedApplication().scheduleLocalNotification(notification)

		NSOperationQueue.mainQueue().addOperationWithBlock({
			self.displayDialog("Reminder saved") {
				exit(0)
			}
		})
	}

	func displayDialog(msg: String, withClosure block: (() -> Void)?) {
		var alert = UIAlertController(title: "Attention", message: msg, preferredStyle: UIAlertControllerStyle.Alert)
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
