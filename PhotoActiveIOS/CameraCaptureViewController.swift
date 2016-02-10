//
//  CameraCaptureViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 01/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit
import AVFoundation

class CameraCaptureViewController: UIViewController {
	let captureSession = AVCaptureSession()
	var previewLayer: AVCaptureVideoPreviewLayer?

	// If we find a device we'll store it here for later use
	var captureDevice: AVCaptureDevice?

	let screenWidth = UIScreen.mainScreen().bounds.size.width

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		captureSession.sessionPreset = AVCaptureSessionPresetPhoto

		let devices = AVCaptureDevice.devices()

		// Loop through all the capture devices on this device
		for device in devices {
			// Make sure this particular device supports video
			if device.hasMediaType(AVMediaTypeVideo) {
				// Finally check the position and confirm we've got the back camera
				if device.position == AVCaptureDevicePosition.Back {
					captureDevice = device as? AVCaptureDevice
					if captureDevice != nil {
						beginSession()
					}
				}
			}
		}

		// If there no capture device was found, display an error message and go back
		if captureDevice == nil {
			NSLog("Error: No capture device found")
			let alert = UIAlertController(title: "Error", message: "Could not open camera", preferredStyle: UIAlertControllerStyle.Alert)
			alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
				// Go back to the previous view controller
				self.navigationController?.popViewControllerAnimated(true)
			}))
			self.presentViewController(alert, animated: true, completion: nil)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
		if segue.identifier == "ReviewCaptureSegue" {
//			let destController = segue.destinationViewController as? ReviewCaptureViewController
			
		}
	}

	func beginSession() {
		configureDevice()

		do {
			try captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
		}
		catch {
			NSLog("Error: \(error)")
		}

		previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		self.view.layer.addSublayer(previewLayer!)
		previewLayer?.frame = self.view.layer.frame

		captureSession.startRunning()
	}

	func configureDevice() {
		if let device = captureDevice {
			do {
				try device.lockForConfiguration()
			} catch _ {
			}
			device.focusMode = .AutoFocus
			device.unlockForConfiguration()
		}
	}

	func updateDeviceSettings(focusValue: Float, isoValue: Float) {
		if let device = captureDevice {
			do {
				try device.lockForConfiguration()
				device.setFocusModeLockedWithLensPosition(focusValue, completionHandler: { time in
					//
				})

				// Adjust the iso to clamp between minIso and maxIso based on the active format
				let minISO = device.activeFormat.minISO
				let maxISO = device.activeFormat.maxISO
				let clampedISO = isoValue * (maxISO - minISO) + minISO

				device.setExposureModeCustomWithDuration(AVCaptureExposureDurationCurrent, ISO: clampedISO, completionHandler: { time in
					//
				})

				device.unlockForConfiguration()
			} catch _ {
			}
		}
	}

	func touchPercent(touch: UITouch) -> CGPoint {
		// Get the dimensions of the sceen in points
		let screenSize = UIScreen.mainScreen().bounds.size

		// Create an empty CGPoint object set to 0, 0
		var touchPer = CGPointZero

		// Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
		touchPer.x = touch.locationInView(self.view).x / screenSize.width
		touchPer.y = touch.locationInView(self.view).y / screenSize.height

		// Return the populated CGPoint
		return touchPer
	}

    @IBAction func takePhoto(sender: UIButton) {
        // TODO
	}
}
