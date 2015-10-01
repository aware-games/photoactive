//
//  UIButtonExt.swift
//  PhotoActiveIOS
//
//  Created by Joel Hietanen on 07/08/15.
//  Copyright (c) 2015 Aware Games. All rights reserved.
//

import UIKit

extension CALayer {
	func setBorderUIColor(color: UIColor) {
		self.borderColor = color.CGColor
	}

	func borderUIColor() -> UIColor {
		return UIColor(CGColor: self.borderColor!)
	}
}