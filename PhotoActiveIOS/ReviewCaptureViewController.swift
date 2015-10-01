//
//  ReviewCaptureViewController.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 06/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit
import Photos

class ReviewCaptureViewController: UIViewController {
	let photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	/*
	Creating an asset and adding to an album.
	
	:param: image		Image to store.
	:param: toAlbum		Album in which to store the image.
	*/
	func addNewAssetWithImage(image: UIImage, toAlbum album: PHAssetCollection) {
		photoLibrary.performChanges( {
			// Request creating an asset from the image
			let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
			
			// Request editing the album
			let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: album)
			
			// Get a placeholder for the new asset and add it to the album editing request
			let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
			albumChangeRequest!.addAssets([assetPlaceholder] as! NSFastEnumeration)
			},
			completionHandler: { success, error in
				if success {
					NSOperationQueue.mainQueue().addOperationWithBlock({
						self.performSegueWithIdentifier("ReviewCaptureSegue", sender: self)
					})
				}
				else {
					NSLog("Error: Failed to save photo to album. %@", error!.localizedDescription)
					self.navigationController?.popViewControllerAnimated(true)
				}
		})
	}
}
