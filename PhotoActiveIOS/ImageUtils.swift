//
//  ImageUtils.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 05/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import Foundation
import AVFoundation

class ImageUtils {
	static let PHOTOACTIVE_FOLDER_NAME = "PhotoActive"
	static let TS_FORMAT = "yyyyMMdd_HHmmss"
	static let IMG_PREFIX = "IMG_"
	static let IMG_SUFFIX = ".jpg"
	static let VID_PREFIX = "VID_"
	static let VID_SUFFIX = ".mp4"
	static let MAX_HEIGHT = 1024
	static let MAX_WIDTH = 1024
	static let MEDIA_TYPE_IMAGE = 1
	static let MEDIA_TYPE_VIDEO = 0

	/*class func getOutputMediaFileUrl(type: Int) -> NSURL {
		return NSURL(fileURLWithPath: getOutputMediaFile(type))
	}*/

	/**
	 * Create a File for saving an image or video.
	 */
	class func getOutputMediaFile(type: Int) -> NSFileHandle? {
		return nil
	}

	/**
	Calculate an inSampleSize for use in an options object when decoding bitmaps using the decode* methods from iOSBitmapFactory. This implementation calculates the closest inSampleSize that will result in the final decoded bitmap having a width and height equal to or larger than the requested width and height. This implementation does not ensure a power of 2 is returned for inSampleSize which can be faster when decoding, but results in a larger bitmap which isn't as useful for caching purposes.
	 
	:param: options	An options object with out* params already populated (run through a decode* method with inJustDecodeBounds==true
	:param: reqWidth	The requested width of the resulting bitmap
	:param: reqHeight	The requested height of the resulting bitmap
	:returns:	The value to be used for inSampleSize
	*/
	class func calculateInSampleSize(options: option, reqWidth: Int, reqHeight: Int) -> Int {
		// Raw height and width of image
		let height = Int(options.val)
		let width = Int(options.val)
		var inSampleSize = 1

		if height > reqHeight || width > reqWidth {

			// Calculate ratios of height and width to requested height and width
			let heightRatio = Int(round(Double(height) / Double(reqHeight)))
			let widthRatio = Int(round(Double(width) / Double(reqWidth)))

			// Choose the smallest ratio as inSampleSize value, this will guarantee a final image with both dimensions larger than or equal to the requested height and width.
			inSampleSize = heightRatio < widthRatio ? heightRatio : widthRatio

			// This offers some additional logic in case the image has a strange aspect ratio. For exapmle, a panorama may have a much larger width than height. In these cases the total pixels might still end up being too large to fit comfortably in memory, so we should be more aggressive with sample down the image (=larger inSampleSize).
			let totalPixels = width * height

			// Anything more than 2x the requestied pixels we'll sample down further
			let totalReqPixelsCap = reqWidth * reqHeight * 2

			while totalPixels / (inSampleSize * inSampleSize) > totalReqPixelsCap {
				inSampleSize++
			}
		}

		return inSampleSize
	}

	/**
	Rotate an image if required.
	
	:param: img
	:param: angle
	:returns:
	*/
	class func rotateImageIfRequired(img: AVAsset, angle: Int) -> AVAsset {
		// Detect rotation
		let rotation = angle
		if rotation != 0 {
			//let matrix = Matrix()
			//matrix.rotate()
			return img
		}
		else {
			return img
		}
	}
}