//
//  UIImageExt.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 28/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit

extension UIImage {
	func imageRotatedByDegrees(degrees: CGFloat, flip: Bool, resize: Bool) -> UIImage {
		let newWidth = resize ? size.height : size.width
		let newHeight = resize ? size.width : size.height

		let radiansToDegrees: (CGFloat) -> CGFloat = {
			return $0 * (180.0 / CGFloat(M_PI))
		}

		let degreesToRadians: (CGFloat) -> CGFloat = {
			return $0 / 180.0 * CGFloat(M_PI)
		}

		// Calculate the size of the rotated view's containing box for our drawing space
		let rotatedViewBox = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: newWidth, height: newHeight)))
		let t = CGAffineTransformMakeRotation(degreesToRadians(degrees))
		rotatedViewBox.transform = t
		let rotatedSize = rotatedViewBox.frame.size

		// Create the bitmap context
		UIGraphicsBeginImageContext(rotatedSize)
		let bitmap = UIGraphicsGetCurrentContext()

		// Move the origin to the middle of the image so we will rotate and scale around the center
		CGContextTranslateCTM(bitmap, rotatedSize.width / 2.0, rotatedSize.height / 2.0)

		// Rotate the image context
		CGContextRotateCTM(bitmap, degreesToRadians(degrees))

		// Now, draw the rotated/scaked image into the context
		var yFlip: CGFloat

		if flip {
			yFlip = CGFloat(-1.0)
		}
		else {
			yFlip = CGFloat(1.0)
		}

		CGContextScaleCTM(bitmap, yFlip, -1.0)
		CGContextDrawImage(bitmap, CGRectMake(-newWidth / 2, -newHeight / 2, newWidth, newHeight), CGImage)

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage
	}
}