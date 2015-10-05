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

class PAUIButton : UIButton {
	override var highlighted: Bool {
		get {
			return super.highlighted
		}
		set {
			if newValue {
				backgroundColor = UIColor(red: 0.792157, green: 1.0, blue: 0.698039, alpha: 1.0)
			}
			else {
				backgroundColor = UIColor.whiteColor()
			}
			super.highlighted = newValue
		}
	}
}